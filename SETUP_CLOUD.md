# Cloud Setup — shared inventory across all your devices (free)

This turns the app from single-device into a **shared, live** system: add a part
on your phone and it instantly appears on your laptop and your staff's devices.
Uses **Supabase** (free tier) for the database + login. ~10 minutes, one time.

---

## Step 1 — Create a free Supabase project
1. Go to **[supabase.com](https://supabase.com)** → **Start your project** → sign in (GitHub works).
2. Click **New project**.
3. Name it e.g. `spareparts`, set a **database password** (save it somewhere), pick
   the region closest to Malaysia (e.g. **Southeast Asia / Singapore**).
4. Click **Create new project** and wait ~2 minutes for it to finish setting up.

## Step 2 — Create the database table
1. In your project, open **SQL Editor** (left sidebar) → **New query**.
2. Open the file **`supabase/setup.sql`** from this repo, copy ALL of it, paste into
   the query box.
3. Click **Run**. You should see "Success". This creates the `parts` table,
   security rules, and the example parts.

## Step 3 — Get your two keys
1. Go to **Project Settings** (gear icon) → **API**.
2. Copy these two values:
   - **Project URL** (looks like `https://abcd1234.supabase.co`)
   - **anon public** key (a long text string under "Project API keys")

*(The anon key is safe to put in the app — it only works together with a valid
login, because Row Level Security protects the data.)*

## Step 4 — Put the keys into the app
Open **`app/index.html`** and near the top of the `<script>` section find:

```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace the two placeholder strings with your Project URL and anon key, then save
and commit. Netlify will redeploy automatically.

> Easiest option: just send me the Project URL + anon key and I'll paste them in
> and push for you.

## Step 5 — Create your login account
1. In Supabase, go to **Authentication** → **Users** → **Add user** →
   **Create new user**.
2. Enter your **email** and a **password**. (Turn OFF "auto-confirm"? Leave it so
   the user is confirmed immediately — tick "Auto Confirm User" if shown.)
3. That's your login for the app.

### Add staff later
Repeat Step 5 for each staff member — one email + password each. They all share
the same live inventory.

## Step 6 — Lock down sign-ups (recommended)
So random people can't create accounts:
1. **Authentication** → **Providers** → **Email**.
2. Turn **OFF "Allow new users to sign up"** (you'll add users manually in Step 5).

---

## Done!
Open your Netlify link, sign in with the account from Step 5, and you'll see the
shared inventory. Add a part on your phone → refresh your laptop → it's there. ✅

## Notes
- **Existing local data** (parts you added before on your laptop) stays in that
  browser only; it won't auto-move to the cloud. Re-add important ones, or ask me
  to write a quick import.
- **Offline:** viewing works offline (cached), but adding/editing needs internet
  since it saves to the shared database.
- **Free tier** is generous and fine for a single shop; you can upgrade later if
  you outgrow it.
