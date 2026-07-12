# Spare Parts Warehouse App — Specification

**Business:** Car spare parts warehouse, Sarawak, Malaysia.
**Core promise:** never sell a customer the wrong part. Compatibility comes first.

---

## 1. The #1 problem this app solves: CORRECT FITMENT

A single physical part can fit **many** vehicles, and one vehicle needs **many**
parts. The relationship is **many-to-many**. Two real cases from the business:

- **Shared mechanical part:** a *tie rod end* fits BOTH the **Ford Ranger** AND
  certain **Mazda** models (they share a platform). One part, multiple vehicles.
- **Engine-dependent part:** a *starter motor* or other electrical part is only
  correct for a specific **engine code** (e.g. Toyota **2KD**). The same body
  model with a different engine needs a DIFFERENT starter. Body model alone is
  NOT enough — the engine must be stated.

So every part is matched to one or more **Fitments**, where a fitment is:

```
Make  +  Model  +  Year range  +  Engine code (when relevant)  +  Variant/notes
```

Example fitments for one starter motor:
| Make   | Model    | Years     | Engine | Notes        |
|--------|----------|-----------|--------|--------------|
| Toyota | Hilux    | 2005–2015 | 2KD    | 2.5L diesel  |
| Toyota | Fortuner | 2005–2015 | 2KD    | 2.5L diesel  |

The same Hilux with a **2TR petrol** engine would NOT match this part.

---

## 2. Feature scope

### Must-have (v1)
- **Part lookup by vehicle:** staff/customer picks Make -> Model -> Year ->
  Engine, and sees ONLY parts that truly fit. This prevents wrong purchases.
- **Part lookup by part number / name / brand** (reverse search).
- **Compatibility flags:** clearly show when a part is **engine-specific**
  (e.g. "2KD ONLY") vs. fits all engines of a model.
- **Stock levels** per part, per warehouse location.
- **Stock in / out** (receiving from suppliers, issuing to customers).
- **Low-stock alerts** (reorder point per part).
- **Cross-reference / OEM numbers** (so a part can be found by OEM or aftermarket code).

### Should-have (v2)
- Suppliers + purchase orders.
- Sales / invoicing in **MYR** with **SST** where applicable.
- Reports: stock value, fast/slow movers, monthly movement.
- Multiple warehouse locations.
- Barcode/QR scanning via phone camera.

### Malaysia specifics
- Currency: **MYR (RM)**.
- Tax: **SST** field on sales (configurable rate).
- Keep design ready for **LHDN e-Invoicing (MyInvois)** fields later.

---

## 3. Users & devices
- Web app (opens on any phone, tablet, or office PC — no app store).
- Roles: **Admin** (full), **Staff** (stock + lookup), optional **Viewer**.

## 4. Recommended stack
- Frontend: React + TypeScript (responsive, works on phone + PC).
- Backend/DB: PostgreSQL (via Supabase for DB + auth + hosting in one).
- Barcode: browser camera.
- Hosting: cloud, low monthly cost.

---

## 5. Data model (overview — see schema.sql for full detail)

```
vehicle_make ─┐
              ├─< vehicle_model ─< fitment >─┐
        engine (code) ──────────────┘        │   (many-to-many)
                                             │
                                   part_fitment
                                             │
part_category ─< part >──────────────────────┘
                  │
                  ├─< inventory >── location
                  ├─< part_crossref  (OEM / interchange numbers)
                  └─< stock_movement  (audit of every in/out)
```

The **fitment** + **part_fitment** tables are the heart of the system — they are
what guarantees a customer only ever sees parts that fit their exact car + engine.
