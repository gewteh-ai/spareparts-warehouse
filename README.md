# Spare Parts Warehouse

Inventory + vehicle-compatibility app for a car spare parts business (Sarawak, Malaysia).
Its main job: **make sure a customer never buys the wrong part.**

## How to open the app (no installation, free, private)

1. In this repo, open **`app/index.html`**.
2. Click the **"Download raw file"** button (the download icon, top-right of the file view).
3. On your computer, **double-click the downloaded `index.html`** — it opens in your
   browser and works fully, even offline.

Your parts data is saved **inside that browser** (localStorage). Use one main
device (e.g. the office PC) as the master while you build up the list.

## What the app does

- **Find Parts** — pick the customer's vehicle (Make → Model → Year → Engine →
  Transmission → Drivetrain) and see only parts that truly fit. Engine-specific
  parts (e.g. starters) show a badge and warn you to confirm the engine.
- **Inventory** — all stock, low-stock alerts, and one-tap stock in/out.
- **Add Part** — add new parts with multiple brands/prices and as many
  compatible vehicles as needed. Saves instantly.

## Files

| File | Purpose |
|------|---------|
| `app/index.html` | The working app (self-contained, open in any browser) |
| `SPEC.md` | Requirements + the compatibility design |
| `schema.sql` | PostgreSQL schema for the future multi-user cloud version |
| `seed.sql` | Example data proving shared + engine-specific fitments |

## Later: multi-user cloud version

When multiple staff/devices need to share the same live data, the included
`schema.sql` is ready to deploy to a cloud database (e.g. Supabase). Ask and it
can be migrated.
