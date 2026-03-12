import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenerativeAI } from "@google/generative-ai";
import admin from "firebase-admin";

// Firebase Admin 초기화 (ESM + Node 20)
if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

// 카카오 로그인 (Secret Manager: KAKAO_REST_API_KEY만 사용)
const kakaoRestApiKey = defineSecret("KAKAO_REST_API_KEY");

const KAKAO_AUTH_URL = "https://kauth.kakao.com/oauth/authorize";
const KAKAO_TOKEN_URL = "https://kauth.kakao.com/oauth/token";
const KAKAO_USER_ME_URL = "https://kapi.kakao.com/v2/user/me";

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

// ----- 카카오 로그인 -----
const authCors = {
  cors: true,
  region: "asia-northeast3",
  // KAKAO_REST_API_KEY는 필수, KAKAO_CLIENT_SECRET은 선택
  secrets: [kakaoRestApiKey],
};

/**
 * 카카오 로그인 시작: 앱에서 이 URL로 이동하면 카카오 인증 페이지로 리다이렉트합니다.
 * GET ?redirect_uri=https://앱도메인 (인증 후 돌아갈 앱 URL)
 */
export const authKakaoStart = onRequest(authCors, async (req, res) => {
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.status(204).send("");
    return;
  }
  if (req.method !== "GET") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const redirectUri = (req.query.redirect_uri || "").toString().trim();
  if (!redirectUri) {
    res.status(400).send("redirect_uri is required");
    return;
  }

  const clientId = kakaoRestApiKey.value();
  if (!clientId || !clientId.trim()) {
    res.status(500).send("KAKAO_REST_API_KEY is not set in Secret Manager");
    return;
  }

  // state에 앱 redirect_uri를 넣어서 콜백에서 그쪽으로 토큰 전달
  const state = encodeURIComponent(redirectUri);
  const callbackUrl = getAuthKakaoCallbackUrl(req);
  const params = new URLSearchParams({
    response_type: "code",
    client_id: clientId,
    redirect_uri: callbackUrl,
    state,
  });
  const url = `${KAKAO_AUTH_URL}?${params.toString()}`;
  res.redirect(302, url);
});

/**
 * 카카오가 인증 후 리다이렉트하는 콜백.
 * code를 카카오 토큰으로 교환 → Firebase Custom Token 생성 → 앱 redirect_uri로 리다이렉트
 */
export const authKakaoCallback = onRequest(authCors, async (req, res) => {
  if (req.method !== "GET") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const code = (req.query.code || "").toString().trim();
  const state = (req.query.state || "").toString().trim();
  const error = req.query.error;
  const errorDesc = req.query.error_description;

  let appRedirectUri = "";
  try {
    appRedirectUri = decodeURIComponent(state);
  } catch (_) {
    appRedirectUri = state;
  }

  if (error) {
    const sep = appRedirectUri.includes("?") ? "&" : "?";
    const errMsg = [error, errorDesc].filter(Boolean).join(": ");
    res.redirect(302, `${appRedirectUri}${sep}auth_error=${encodeURIComponent(errMsg)}`);
    return;
  }

  if (!code) {
    res.redirect(302, `${appRedirectUri}${appRedirectUri.includes("?") ? "&" : "?"}auth_error=missing_code`);
    return;
  }

  const clientId = kakaoRestApiKey.value();
  if (!clientId || !clientId.trim()) {
    res.redirect(302, `${appRedirectUri}${appRedirectUri.includes("?") ? "&" : "?"}auth_error=server_config`);
    return;
  }

  const callbackUrl = getAuthKakaoCallbackUrl(req);
  let accessToken = "";
  let kakaoId = "";

  try {
    const tokenRes = await fetch(KAKAO_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded;charset=utf-8" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        client_id: clientId,
        redirect_uri: callbackUrl,
        code,
      }).toString(),
    });

    if (!tokenRes.ok) {
      const errText = await tokenRes.text();
      console.error("Kakao token error:", tokenRes.status, errText);
      res.redirect(302, `${appRedirectUri}${appRedirectUri.includes("?") ? "&" : "?"}auth_error=token_failed`);
      return;
    }

    const tokenData = await tokenRes.json();
    accessToken = (tokenData.access_token || "").toString();

    const meRes = await fetch(KAKAO_USER_ME_URL, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!meRes.ok) {
      console.error("Kakao user/me error:", meRes.status);
      res.redirect(302, `${appRedirectUri}${appRedirectUri.includes("?") ? "&" : "?"}auth_error=user_failed`);
      return;
    }
    const meData = await meRes.json();
    kakaoId = String(meData.id ?? "");
    if (!kakaoId) {
      res.redirect(302, `${appRedirectUri}${appRedirectUri.includes("?") ? "&" : "?"}auth_error=no_kakao_id`);
      return;
    }
  } catch (e) {
    console.error("Kakao auth error:", e);
    res.redirect(302, `${appRedirectUri}${appRedirectUri.includes("?") ? "&" : "?"}auth_error=exchange_failed`);
    return;
  }

  try {
    const firebaseUid = `kakao_${kakaoId}`;
    const customToken = await admin.auth().createCustomToken(firebaseUid);
    const sep = appRedirectUri.includes("?") ? "&" : "?";
    res.redirect(302, `${appRedirectUri}${sep}firebase_custom_token=${encodeURIComponent(customToken)}`);
  } catch (e) {
    console.error("Firebase custom token error:", e);
    res.redirect(302, `${appRedirectUri}${appRedirectUri.includes("?") ? "&" : "?"}auth_error=token_create_failed`);
  }
});

/**
 * 앱이 auth_code를 받았을 때 Firebase Custom Token으로 교환 (웹에서 콜백이 code만 넘기는 경우 대비)
 * POST Body: { "code": "...", "redirectUri": "..." }
 */
export const authKakaoExchange = onRequest(authCors, async (req, res) => {
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

  let body;
  try {
    body = typeof req.body === "string" ? JSON.parse(req.body) : req.body || {};
  } catch (_) {
    res.status(400).json({ error: "Invalid JSON body" });
    return;
  }

  const code = (body.code || "").toString().trim();
  const redirectUri = (body.redirectUri || "").toString().trim();
  if (!code || !redirectUri) {
    res.status(400).json({ error: "code and redirectUri are required" });
    return;
  }

  const clientId = kakaoRestApiKey.value();
  if (!clientId || !clientId.trim()) {
    res.status(500).json({ error: "KAKAO_REST_API_KEY is not set" });
    return;
  }

  // 앱이 받은 code는 redirect_uri=앱URL 로 발급된 것이므로 동일한 redirectUri로 토큰 요청
  try {
    const tokenRes = await fetch(KAKAO_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded;charset=utf-8" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        client_id: clientId,
        redirect_uri: redirectUri,
        code,
      }).toString(),
    });

    if (!tokenRes.ok) {
      const errText = await tokenRes.text();
      console.error("Kakao token exchange error:", tokenRes.status, errText);
      res.status(502).json({ error: "OAuth exchange failed" });
      return;
    }

    const tokenData = await tokenRes.json();
    const accessToken = (tokenData.access_token || "").toString();
    const meRes = await fetch(KAKAO_USER_ME_URL, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!meRes.ok) {
      res.status(502).json({ error: "Failed to get Kakao user" });
      return;
    }
    const meData = await meRes.json();
    const kakaoId = String(meData.id ?? "");
    if (!kakaoId) {
      res.status(502).json({ error: "No Kakao user id" });
      return;
    }

    const firebaseUid = `kakao_${kakaoId}`;
    const customToken = await admin.auth().createCustomToken(firebaseUid);
    res.set("Access-Control-Allow-Origin", "*");
    res.status(200).json({ firebaseCustomToken: customToken });
  } catch (e) {
    console.error("authKakaoExchange error:", e);
    res.status(502).json({ error: e instanceof Error ? e.message : "Exchange failed" });
  }
});

function getAuthKakaoCallbackUrl(req) {
  const protocol = req.get("x-forwarded-proto") || req.protocol || "https";
  const host = req.get("x-forwarded-host") || req.get("host") || "";
  const base = `${protocol}://${host}`.replace(/\/$/, "");
  return `${base}/authKakaoCallback`;
}
