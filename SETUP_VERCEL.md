# Host on Vercel (free) — setup

Netlify paused new deploys (free build allowance used up). Vercel's free tier
hosts the same app + the AI function with more headroom. Your data is unaffected
(it lives in Supabase, not the host). Only the web address changes.

## Step 1 — Create a Vercel account
1. Go to **https://vercel.com** → **Sign Up** → **Continue with GitHub**.
2. Authorize Vercel.

## Step 2 — Import your repo
1. **Add New… → Project**.
2. Find **`spareparts-warehouse`** → **Import**.
3. **Framework Preset:** choose **Other**.
4. **Root Directory:** leave as `./` (the repo root — do NOT set it to `app`;
   `vercel.json` already points the site to the `app` folder and keeps `/api`).
5. Leave Build Command empty / default.

## Step 3 — Add the AI key (before or after first deploy)
1. In the project, go to **Settings → Environment Variables**.
2. Add: **Key** = `GEMINI_API_KEY` · **Value** = your Gemini key · Save.
   (Same value you used on Netlify.)

## Step 4 — Deploy
1. Click **Deploy**. Wait ~1 minute.
2. You'll get a URL like **`https://spareparts-warehouse.vercel.app`**.
   *(If you added the key after the first deploy, go to **Deployments → … → Redeploy** so it picks up the key.)*

## Step 5 — Use the new link
1. Open the new `*.vercel.app` link → sign in (same email/password).
2. Everything is there (your data comes from Supabase).
3. Re-add to your phone home screen from the new link (Safari → Share → Add to Home Screen).

## Notes
- The app calls `/api/identify-part` on Vercel (and still falls back to the old
  Netlify path), so the AI scan works on the new host.
- Supabase needs no changes — email/password login works from any domain.
- You can delete the Netlify site later, or keep it; it just won't update.
