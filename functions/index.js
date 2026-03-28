import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
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

const LINE_PROFILE_URL = "https://api.line.me/v2/profile";

// 보호: 메시지 길이 / 분당 요청 / 일일 요청
const MAX_CHARS = 500;
const RATE_LIMIT_PER_MIN = 10;
const DAILY_LIMIT = 500;
const LIMITS_COLLECTION = "translation_limits";

// API 키는 Google Secret Manager에만 저장. 앱 코드에는 넣지 마세요.
const geminiApiKey = defineSecret("GEMINI_API_KEY");

async function verifyTranslateAuth(req, res) {
  const authHeader = (req.get("authorization") || req.get("Authorization") || "").toString();
  if (!authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing Authorization Bearer token" });
    return null;
  }
  const idToken = authHeader.substring(7).trim();
  if (!idToken) {
    res.status(401).json({ error: "Empty bearer token" });
    return null;
  }
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (e) {
    console.error("verifyIdToken failed:", e);
    res.status(401).json({ error: "Invalid auth token" });
    return null;
  }
}

/**
 * Gemini가 여러 줄로 답할 때 잘못된 줄을 고르지 않도록 번역문 한 줄을 고른다.
 * 기존 로직은 마지막 줄만 사용했는데, 번역이 첫 줄에 있고 끝에 이름·잡음 등이 붙으면
 * 그 잡음이 저장되는 문제가 있었다.
 */
function pickTranslationFromGeminiOutput(raw, sourceText) {
  const sourceNorm = (sourceText ?? "").trim();
  let translated = (raw ?? "").trim();
  if (!translated) return "";

  const lines = translated
    .split(/\n/)
    .map((s) => s.trim())
    .filter(Boolean);
  if (lines.length <= 1) return translated;

  const hasHangul = (s) => /[\uAC00-\uD7AF]/.test(s);
  const hasKanaOrKanji = (s) =>
    /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]/.test(s);

  const stripLabel = (s) =>
    s
      .replace(
        /^(translation|訳|日本語|韓国語|한국어|일본어|原文|번역)\s*[:：]\s*/i,
        "",
      )
      .trim();

  const cleaned = lines.map(stripLabel).filter(Boolean);
  const candidates = cleaned.filter((l) => l !== sourceNorm);
  const pool = candidates.length > 0 ? candidates : cleaned;

  if (hasHangul(sourceNorm)) {
    // 한국어 → 일본어: 일본어/한자가 있고 한글이 없는 줄 우선
    const jp = pool.find((l) => hasKanaOrKanji(l) && !hasHangul(l));
    if (jp) return jp;
  } else {
    // 일본어 → 한국어: 한글이 있는 줄 우선
    const ko = pool.find((l) => hasHangul(l));
    if (ko) return ko;
  }

  // Echo 제거 후 첫 줄(번역이 보통 먼저 옴). 마지막 줄은 잡음에 취약함.
  return pool[0] ?? translated;
}

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
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
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
    const systemPrompt = (body.system_prompt ?? "Korean↔Japanese couple chat. Korean names/vocatives (…아/…야): katakana from pronunciation (준혁→ジュンヒョク); never substitute unrelated Japanese names (e.g. not ヒカル for 준혁). Output only the translation.").toString().trim();
    const userId = (body.user_id ?? "").toString().trim();

    if (text === "") {
      res.status(400).json({ error: "text is required" });
      return;
    }
    if (userId === "") {
      res.status(400).json({ error: "user_id is required for rate limiting" });
      return;
    }
    const decoded = await verifyTranslateAuth(req, res);
    if (!decoded) {
      return;
    }
    if (decoded.uid !== userId) {
      res.status(403).json({ error: "user_id does not match auth token uid" });
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
      let translated = pickTranslationFromGeminiOutput(
        response.text() ?? "",
        text,
      );
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

  const accessTokenFromBody = (body.accessToken || "").toString().trim();

  try {
    if (accessTokenFromBody) {
      const meRes = await fetch(KAKAO_USER_ME_URL, {
        headers: { Authorization: `Bearer ${accessTokenFromBody}` },
      });
      if (!meRes.ok) {
        const errText = await meRes.text();
        console.error("Kakao user/me (accessToken) error:", meRes.status, errText);
        res.status(401).json({ error: "Invalid or expired Kakao access token" });
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
      return;
    }

    const code = (body.code || "").toString().trim();
    const redirectUri = (body.redirectUri || "").toString().trim();
    if (!code || !redirectUri) {
      res.status(400).json({
        error: "Provide accessToken (native SDK) or code and redirectUri (web OAuth)",
      });
      return;
    }

    const clientId = kakaoRestApiKey.value();
    if (!clientId || !clientId.trim()) {
      res.status(500).json({ error: "KAKAO_REST_API_KEY is not set" });
      return;
    }

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

/**
 * LINE 네이티브 SDK로 받은 액세스 토큰으로 Firebase Custom Token 발급
 * POST Body: { "accessToken": "..." }
 */
export const authLineExchange = onRequest(authCors, async (req, res) => {
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

  const accessToken = (body.accessToken || "").toString().trim();
  if (!accessToken) {
    res.status(400).json({ error: "accessToken is required" });
    return;
  }

  try {
    const meRes = await fetch(LINE_PROFILE_URL, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!meRes.ok) {
      const errText = await meRes.text();
      console.error("LINE profile error:", meRes.status, errText);
      res.status(401).json({ error: "Invalid or expired LINE access token" });
      return;
    }
    const meData = await meRes.json();
    const lineUserId = (meData.userId ?? "").toString().trim();
    if (!lineUserId) {
      res.status(502).json({ error: "No LINE user id" });
      return;
    }

    const firebaseUid = `line_${lineUserId}`;
    const customToken = await admin.auth().createCustomToken(firebaseUid);
    res.set("Access-Control-Allow-Origin", "*");
    res.status(200).json({ firebaseCustomToken: customToken });
  } catch (e) {
    console.error("authLineExchange error:", e);
    res.status(502).json({ error: e instanceof Error ? e.message : "Exchange failed" });
  }
});

function getAuthKakaoCallbackUrl(req) {
  const protocol = req.get("x-forwarded-proto") || req.protocol || "https";
  const host = req.get("x-forwarded-host") || req.get("host") || "";
  const base = `${protocol}://${host}`.replace(/\/$/, "");
  return `${base}/authKakaoCallback`;
}

export const notifyOnMessageCreated = onDocumentCreated(
  {
    region: "asia-northeast3",
    document: "couples/{coupleId}/messages/{messageId}",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const message = snap.data() || {};
    const coupleId = event.params.coupleId;
    const senderId = (message.senderId || "").toString().trim();
    const text = (message.messageText || "").toString().trim();
    if (!coupleId || !senderId || !text) return;

    const coupleDoc = await db.collection("couples").doc(coupleId).get();
    if (!coupleDoc.exists) return;
    const couple = coupleDoc.data() || {};
    const user1Id = (couple.user1Id || "").toString().trim();
    const user2Id = (couple.user2Id || "").toString().trim();
    const receiverId = senderId === user1Id ? user2Id : user1Id;
    if (!receiverId) return;

    const [receiverDoc, senderDoc] = await Promise.all([
      db.collection("users").doc(receiverId).get(),
      db.collection("users").doc(senderId).get(),
    ]);
    if (!receiverDoc.exists) return;
    const receiver = receiverDoc.data() || {};
    const sender = senderDoc.exists ? senderDoc.data() || {} : {};

    const allEnabled = receiver.notificationAllEnabled !== false;
    const messageEnabled = receiver.notificationMessageEnabled !== false;
    if (!allEnabled || !messageEnabled) return;

    const tokensRaw = receiver.fcmTokens;
    if (!Array.isArray(tokensRaw) || tokensRaw.length === 0) return;
    const tokens = tokensRaw
      .map((t) => (t ?? "").toString().trim())
      .filter((t) => t.length > 0);
    if (tokens.length === 0) return;

    const senderName = (sender.nickname || "").toString().trim() || "Partner";
    const body = text.length > 120 ? `${text.slice(0, 117)}...` : text;

    const result = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: senderName,
        body,
      },
      data: {
        type: "chat_message",
        coupleId,
        messageId: snap.id,
        senderId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "default",
        },
      },
      apns: {
        headers: { "apns-priority": "10" },
      },
    });

    const invalidTokens = [];
    result.responses.forEach((r, i) => {
      if (r.success) return;
      const code = r.error?.code || "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalidTokens.push(tokens[i]);
      }
    });

    if (invalidTokens.length > 0) {
      await db.collection("users").doc(receiverId).set({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      }, { merge: true });
    }
  }
);
