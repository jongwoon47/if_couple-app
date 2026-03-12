import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenerativeAI } from "@google/generative-ai";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// 보호: 메시지 길이 / 분당 요청 / 일일 요청
const MAX_CHARS = 500;
const RATE_LIMIT_PER_MIN = 10;
const DAILY_LIMIT = 500;
const LIMITS_COLLECTION = "translation_limits";

// API 키는 Google Secret Manager에만 저장. 앱 코드에는 넣지 마세요.
const geminiApiKey = defineSecret("GEMINI_API_KEY");

/**
 * 번역 HTTP 함수 (앱에서 POST로 호출)
 * Body: { "text": "번역할 글", "system_prompt": "선택", "user_id": "Firebase UID" }
 * Response: { "translated": "번역 결과" }
 * 제한: 500자, 분당 10회, 일 500회/사용자
 */
export const translate = onRequest(
  {
    cors: true,
    region: "asia-northeast3",
    secrets: [geminiApiKey],
  },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const key = geminiApiKey.value();
    if (!key || key.trim() === "") {
      res.status(500).json({ error: "GEMINI_API_KEY is not set in Secret Manager" });
      return;
    }

    let body;
    try {
      body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    } catch {
      res.status(400).json({ error: "Invalid JSON body" });
      return;
    }

    const text = (body.text ?? "").toString().trim();
    const systemPrompt = (body.system_prompt ?? "Translate Korean to Japanese naturally for couples. Output only the translation, no explanation.").toString().trim();
    const userId = (body.user_id ?? "").toString().trim();

    if (text === "") {
      res.status(400).json({ error: "text is required" });
      return;
    }
    if (userId === "") {
      res.status(400).json({ error: "user_id is required for rate limiting" });
      return;
    }

    // ① 메시지 길이 제한
    if (text.length > MAX_CHARS) {
      res.status(400).json({
        error: "text_too_long",
        message: `번역은 ${MAX_CHARS}자까지 가능해요.`,
        max_chars: MAX_CHARS,
      });
      return;
    }

    // ② 요청 속도 제한(분당) + ③ 일일 제한
    try {
      await db.runTransaction(async (tx) => {
        const ref = db.collection(LIMITS_COLLECTION).doc(userId);
        const doc = await tx.get(ref);
        const now = Date.now();
        const today = new Date().toISOString().slice(0, 10);

        let rateCount = 1;
        let rateWindowStart = now;
        let dayCount = 1;
        let dayDate = today;

        if (doc.exists) {
          const d = doc.data();
          const windowStart = d.rateWindowStart ?? 0;
          if (now - windowStart < 60_000) {
            rateCount = (d.rateCount ?? 0) + 1;
            rateWindowStart = windowStart;
          }
          if (d.dayDate === today) {
            dayCount = (d.dayCount ?? 0) + 1;
            dayDate = today;
          }
        }

        if (rateCount > RATE_LIMIT_PER_MIN) {
          throw new Error("RATE_LIMIT");
        }
        if (dayCount > DAILY_LIMIT) {
          throw new Error("DAILY_LIMIT");
        }

        tx.set(ref, {
          rateCount,
          rateWindowStart,
          dayCount,
          dayDate,
        }, { merge: true });
      });
    } catch (e) {
      if (e.message === "RATE_LIMIT") {
        res.set("Access-Control-Allow-Origin", "*");
        res.status(429).json({
          error: "rate_limit",
          message: "요청이 너무 많아요. 1분 후에 다시 시도해 주세요.",
        });
        return;
      }
      if (e.message === "DAILY_LIMIT") {
        res.set("Access-Control-Allow-Origin", "*");
        res.status(429).json({
          error: "daily_limit",
          message: "오늘 번역 사용 한도를 다 썼어요. 내일 다시 이용해 주세요.",
        });
        return;
      }
      throw e;
    }

    try {
      const genAI = new GoogleGenerativeAI(key);
      const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });
      const prompt = `${systemPrompt}\n\nText to translate:\n${text}`;
      const result = await model.generateContent(prompt);
      const response = result.response;
      let translated = (response.text() ?? "").trim();

      // Gemini가 원문+번역을 여러 줄로 보낼 수 있음 → 마지막 줄만 사용 (번역문만)
      const lines = translated.split(/\n/).map((s) => s.trim()).filter(Boolean);
      if (lines.length > 1) {
        translated = lines[lines.length - 1];
      }
      translated = translated.trim();

      if (translated === "") {
        res.status(502).json({ error: "Empty translation from Gemini" });
        return;
      }

      res.set("Access-Control-Allow-Origin", "*");
      res.status(200).json({ translated });
    } catch (e) {
      console.error("Gemini translate error:", e);
      res.status(502).json({
        error: "Translation failed",
        message: e instanceof Error ? e.message : String(e),
      });
    }
  }
);
