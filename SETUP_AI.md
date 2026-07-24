# AI Photo Scan — setup (free)

Adds a "📷 Scan part photo" button to the Add Part form. Snap a part or its box
and the AI fills in the fields; you review/edit, then Save.

Uses **Google Gemini** (free tier). Your API key is stored securely on Netlify —
never in the app or exposed to users.

---

## Step 1 — Get a free Gemini API key
1. Go to **Google AI Studio**: https://aistudio.google.com/app/apikey
2. Sign in with a Google account.
3. Click **Create API key** → copy the key (a long string).

*(Free tier is generous. If you ever exceed it, Google will simply rate-limit;
no surprise charges unless you deliberately enable billing.)*

## Step 2 — Add the key to Netlify (keeps it secret)
1. Go to **app.netlify.com** → your **spareparts-warehouse** site.
2. **Site configuration → Environment variables → Add a variable**.
3. Key: `GEMINI_API_KEY`  ·  Value: *(paste your Gemini key)*  → **Save**.
4. **Deploys → Trigger deploy → Deploy site** (so the new key is picked up).

## Step 3 — Use it
1. Open the app → **Add Part** → tap **📷 Scan part photo**.
2. On the phone this opens the camera. Take a clear, well-lit photo of the part
   or its box (part numbers/labels facing the camera help a lot).
3. The AI fills what it can. **Check every field and correct anything wrong**,
   then tap **Save part**.

---

## Notes
- Accuracy is best for printed labels/boxes (part numbers, brands). For a bare
  metal part with no markings, it will identify the type but may not know exact
  numbers — that's why you can always edit before saving.
- If the button shows "AI not configured", the `GEMINI_API_KEY` env var isn't set
  yet (Step 2) or the site needs a redeploy.
- To change the AI model, edit `MODEL` at the top of
  `netlify/functions/identify-part.mjs`.
