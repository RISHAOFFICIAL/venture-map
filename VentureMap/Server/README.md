# VentureMap Organizations Proxy

A tiny Node.js server that sits between the VentureMap iOS app and two
third-party APIs. API keys can't live inside an app (anyone who downloads
the app can extract them), so they live here instead.

**What it does**

| Endpoint | What it does |
|---|---|
| `GET /health` | Sanity check — returns `{ "ok": true }` |
| `GET /categories?focus=...` | AI turns a free-typed focus area into 2–4 category labels |
| `GET /organizations?focus=...&location=...` | Web search (Tavily) for real organizations matching the focus + location |

## 1. Get the free API keys

**Tavily** (organization web search — required for `/organizations`)

1. Go to https://tavily.com and sign up.
2. Copy your API key from the dashboard. The free tier includes 1,000 searches/month.

**Google AI Studio** (AI focus → categories — optional but recommended)

1. Go to https://aistudio.google.com and sign in.
2. Click **Get API key** → **Create API key**. The free tier is enough for this app.
3. Without any AI key, `/categories` still works — it falls back to a small
   built-in keyword matcher. The categories are just less clever.

## 2. Run it

No `npm install` needed — the server uses only Node.js built-ins (Node 18+).

```bash
cd Server
TAVILY_API_KEY=tvly-your-key GEMINI_API_KEY=your-gemini-key node organizations-proxy.mjs
```

You should see:

```
VentureMap organizations proxy listening on http://localhost:8787
```

## 3. Test it

In another terminal:

```bash
# Server is alive
curl "http://localhost:8787/health"

# AI categories from a typed focus
curl "http://localhost:8787/categories?focus=teaching%20kids%20to%20code"

# Organizations for a category near a location
curl "http://localhost:8787/organizations?focus=STEM%20education&location=Detroit,%20MI"
```

## 4. Connect the app

The app's `OrganizationSearchService` already points at
`http://localhost:8787`, which works in the **iOS Simulator** while this
server runs on the same Mac.

- **Physical iPhone:** `localhost` on the phone is the phone itself, not your
  Mac. Either run the server with your Mac's LAN IP and change `baseURL` in
  `OrganizationSearchService.swift` to `http://<your-mac-ip>:8787`, or deploy
  the server somewhere and use its `https://` URL (required before shipping —
  see below).
- **Before shipping:** deploy this file to any Node host (Render, Railway,
  Fly.io, a VPS…), set the same environment variables there, and update
  `baseURL` to the deployed `https://` URL.

## How the AI step works

`GET /categories` sends the typed focus to Gemini (via its OpenAI-compatible
endpoint) with instructions to reply in strict JSON:

```json
["STEM education", "Digital skills"]
```

If the AI call fails — or no AI key is set — the server falls back to
`fallbackCategories()`, a small keyword table in the code. The app can't tell
the difference; it just gets category labels either way.

## How the organization search works

Tavily returns web results (title, URL, snippet) — not structured org
records. The server maps each result to the app's `SuggestedOrganization`
shape and best-effort extracts phone/email from the snippet with regexes.
Fields Tavily doesn't provide arrive as `null`, and the app's
`SuggestedOrganizationRow` only renders the contact methods it receives.
