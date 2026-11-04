#!/usr/bin/env node
/**
 * organizations-proxy.mjs — VentureMap's tiny companion server.
 *
 * WHY THIS EXISTS
 * The iOS app needs two things it can't do safely on its own:
 *   1. Search the web for real organizations (via the Tavily search API).
 *   2. Turn a user's free-typed focus area into clean category labels (via an AI).
 * Both need secret API keys. A key bundled inside an app can be extracted by
 * anyone who downloads the app — so the keys live HERE, on this server, and
 * the app only ever talks to this server. That is the entire job of a
 * "proxy": it stands between the app and the third-party APIs.
 *
 * ENDPOINTS
 *   GET /health?                                -> { "ok": true }
 *   GET /categories?focus=teaching+kids+to+code -> { "categories": ["STEM education", "Digital skills"] }
 *   GET /organizations?focus=STEM+education&location=Detroit,+MI
 *        -> [ { "name": ..., "website": ..., "phone": ..., "email": ..., "summary": ... }, ... ]
 *
 * RUN
 *   TAVILY_API_KEY=tvly-... GEMINI_API_KEY=... node organizations-proxy.mjs
 * See README.md next to this file for where to get the (free) keys.
 *
 * DEPENDENCIES: none. Uses only Node's built-in `http` module and the
 * built-in `fetch` (Node 18+). No `npm install` needed.
 */

import http from "node:http";

// ---------------------------------------------------------------------------
// Configuration — all from environment variables so no secret is ever
// written into this file (and therefore never committed to git by accident).
// ---------------------------------------------------------------------------
const PORT = Number(process.env.PORT || 8787);
const TAVILY_API_KEY = process.env.TAVILY_API_KEY || "";
// AI for turning free-text focus into categories. Gemini is first choice
// because Google AI Studio has a free tier; OpenAI is the fallback.
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || "";

// ---------------------------------------------------------------------------
// Small HTTP helpers
// ---------------------------------------------------------------------------
function sendJson(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(body),
    // The app is native (not a browser), so CORS is harmless here — but it
    // makes the endpoints testable from a browser/curl without friction.
    "Access-Control-Allow-Origin": "*",
  });
  res.end(body);
}

// ---------------------------------------------------------------------------
// AI: free-text focus -> 2-4 category labels
// ---------------------------------------------------------------------------
const CATEGORY_SYSTEM_PROMPT =
  "You turn a free-text focus area into 2-4 short category labels (2-4 words each) " +
  "that a nonprofit/community-organization directory would use. " +
  'Reply with ONLY a JSON array of strings, e.g. ["STEM education", "Digital skills"]. No other text.';

/** Call an OpenAI-compatible chat-completions endpoint and parse the category list. */
async function chatCompletions(endpoint, apiKey, model, focus) {
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0.2, // low = deterministic, factual answers
      messages: [
        { role: "system", content: CATEGORY_SYSTEM_PROMPT },
        { role: "user", content: focus.slice(0, 200) },
      ],
    }),
  });
  if (!response.ok) throw new Error(`AI request failed (HTTP ${response.status})`);
  const data = await response.json();
  const text = data?.choices?.[0]?.message?.content ?? "";
  return parseCategoryList(text, focus);
}

/** Pull a JSON string array out of the model's reply (tolerates ``` fences). */
function parseCategoryList(text, focus) {
  try {
    const cleaned = text.replace(/```json|```/g, "").trim();
    const match = cleaned.match(/\[[\s\S]*\]/); // first [...] block
    const parsed = JSON.parse(match ? match[0] : cleaned);
    const labels = (Array.isArray(parsed) ? parsed : [])
      .filter((x) => typeof x === "string")
      .map((x) => x.trim())
      .filter(Boolean)
      .slice(0, 4);
    if (labels.length > 0) return labels;
  } catch {
    // fall through to the keyword fallback below
  }
  return fallbackCategories(focus);
}

/**
 * No-AI fallback: match keywords in the focus text against a small table.
 * This keeps the demo working even with no AI key configured — the
 * categories are less clever, but the feature still functions end to end.
 */
function fallbackCategories(focus) {
  const lower = focus.toLowerCase();
  const table = [
    { words: ["code", "coding", "software", "developer", "programming", "app development"], label: "Software careers" },
    { words: ["school", "student", "stem", "kid", "youth", "teach", "classroom", "education"], label: "STEM education" },
    { words: ["computer", "internet", "digital literacy", "digital skills", "online safety", "broadband"], label: "Digital skills" },
    { words: ["startup", "business", "entrepreneur"], label: "Tech entrepreneurship" },
    { words: ["job", "career", "workforce", "employment", "resume"], label: "Workforce development" },
    { words: ["senior", "elderly", "older adult"], label: "Senior digital literacy" },
  ];
  const hits = table.filter((row) => row.words.some((w) => lower.includes(w))).map((row) => row.label);
  if (hits.length > 0) return hits.slice(0, 3);
  // Last resort: just echo the focus back, tidied up.
  const tidied = focus.trim().replace(/\s+/g, " ").slice(0, 40);
  return [tidied.charAt(0).toUpperCase() + tidied.slice(1)];
}

/** AI categories when a key exists, keyword fallback when it doesn't (or the AI errors). */
async function aiCategories(focus) {
  try {
    if (GEMINI_API_KEY) {
      return await chatCompletions(
        "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
        GEMINI_API_KEY,
        "gemini-2.0-flash",
        focus
      );
    }
    if (OPENAI_API_KEY) {
      return await chatCompletions("https://api.openai.com/v1/chat/completions", OPENAI_API_KEY, "gpt-4o-mini", focus);
    }
  } catch (err) {
    console.warn("AI categorization failed, using keyword fallback:", err.message);
  }
  return fallbackCategories(focus);
}

// ---------------------------------------------------------------------------
// Web search: focus (+ location) -> organizations, via Tavily
// ---------------------------------------------------------------------------
function extractPhone(text) {
  const m = (text || "").match(/(\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4})/);
  return m ? m[1].trim() : null;
}

function extractEmail(text) {
  const m = (text || "").match(/[\w.+-]+@[\w-]+\.[\w.]+/);
  return m ? m[0] : null;
}

async function searchOrganizations(focus, location) {
  if (!TAVILY_API_KEY) {
    const err = new Error("TAVILY_API_KEY is not set on the server. See Server/README.md.");
    err.status = 503;
    throw err;
  }
  const query = ["organizations", focus, location].filter(Boolean).join(" ");
  const response = await fetch("https://api.tavily.com/search", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      api_key: TAVILY_API_KEY,
      query,
      search_depth: "basic",
      max_results: 8,
    }),
  });
  if (!response.ok) throw new Error(`Tavily search failed (HTTP ${response.status})`);
  const data = await response.json();
  // Tavily returns web results, not structured org records — name/website
  // come from the result, and phone/email are best-effort regex finds in
  // the snippet. Missing contact fields arrive as null, which the app
  // already handles (it only shows the ones it gets).
  return (data.results || []).map((r) => ({
    name: r.title || r.url,
    website: r.url || null,
    phone: extractPhone(r.content),
    email: extractEmail(r.content),
    summary: (r.content || "").replace(/\s+/g, " ").trim().slice(0, 280) || null,
  }));
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------
const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, "http://localhost");
    if (req.method !== "GET") return sendJson(res, 405, { error: "Use GET." });

    if (url.pathname === "/health") {
      return sendJson(res, 200, { ok: true });
    }

    if (url.pathname === "/categories") {
      const focus = (url.searchParams.get("focus") || "").trim();
      if (!focus) return sendJson(res, 400, { error: 'Missing "focus" query parameter.' });
      const categories = await aiCategories(focus);
      return sendJson(res, 200, { categories });
    }

    if (url.pathname === "/organizations") {
      const focus = (url.searchParams.get("focus") || "").trim();
      const location = (url.searchParams.get("location") || "").trim();
      if (!focus) return sendJson(res, 400, { error: 'Missing "focus" query parameter.' });
      const orgs = await searchOrganizations(focus, location);
      return sendJson(res, 200, orgs);
    }

    return sendJson(res, 404, { error: "Unknown endpoint. Try /health, /categories, or /organizations." });
  } catch (err) {
    console.error(err);
    return sendJson(res, err.status || 500, { error: err.message || "Server error." });
  }
});

server.listen(PORT, () => {
  console.log(`VentureMap organizations proxy listening on http://localhost:${PORT}`);
  if (!TAVILY_API_KEY) console.warn("  (TAVILY_API_KEY not set — /organizations will return 503 until it is.)");
  if (!GEMINI_API_KEY && !OPENAI_API_KEY)
    console.warn("  (No AI key set — /categories will use the keyword fallback.)");
});
