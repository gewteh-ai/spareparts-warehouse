-- ============================================================================
-- Spare Parts Warehouse — Database Schema (PostgreSQL)
-- Focus: accurate vehicle compatibility (make/model/year/ENGINE CODE)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- VEHICLE CATALOG
-- ---------------------------------------------------------------------------

CREATE TABLE vehicle_make (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE           -- e.g. Toyota, Ford, Mazda
);

CREATE TABLE vehicle_model (
    id          SERIAL PRIMARY KEY,
    make_id     INT NOT NULL REFERENCES vehicle_make(id),
    name        TEXT NOT NULL,                 -- e.g. Hilux, Ranger, BT-50
    UNIQUE (make_id, name)
);

-- Engine is separated out because electrical/engine parts depend on it.
CREATE TABLE engine (
    id          SERIAL PRIMARY KEY,
    code        TEXT NOT NULL UNIQUE,          -- e.g. 2KD, 2TR, WLAT
    description TEXT                           -- e.g. "2.5L Diesel"
);

-- A FITMENT = a specific vehicle configuration a part can fit.
-- Any NULL factor means "fits regardless of that factor".
-- Add as many compatibility factors as the business needs — each NULL-able
-- column narrows a part to a specific configuration.
CREATE TABLE fitment (
    id           SERIAL PRIMARY KEY,
    model_id     INT NOT NULL REFERENCES vehicle_model(id),
    engine_id    INT REFERENCES engine(id),     -- NULL = any engine (e.g. body panels)
    year_from    INT,                           -- e.g. 2005
    year_to      INT,                           -- e.g. 2015 (NULL = still current)
    transmission TEXT,                          -- 'Auto' / 'Manual' / NULL = any
    drivetrain   TEXT,                          -- '4x2' / '4x4' / NULL = any (2WD/4WD)
    body_type    TEXT,                          -- e.g. 'Single Cab','Double Cab' / NULL
    variant      TEXT,                          -- any extra distinguishing note
    UNIQUE (model_id, engine_id, year_from, year_to, transmission, drivetrain, body_type, variant)
);

-- ---------------------------------------------------------------------------
-- PARTS CATALOG
-- ---------------------------------------------------------------------------

CREATE TABLE part_category (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE           -- e.g. Steering, Electrical, Brakes
);

CREATE TABLE part (
    id              SERIAL PRIMARY KEY,
    part_number     TEXT NOT NULL UNIQUE,      -- your internal / aftermarket SKU
    name            TEXT NOT NULL,             -- e.g. "Tie Rod End (Outer)"
    category_id     INT REFERENCES part_category(id),
    brand           TEXT,                      -- e.g. 555, Denso, Aisin
    description     TEXT,
    -- true = this part's correctness depends on the ENGINE, so the app MUST
    -- force the user to pick an engine before confirming the sale.
    engine_specific BOOLEAN NOT NULL DEFAULT FALSE,
    unit_price      NUMERIC(10,2) DEFAULT 0,   -- selling price (MYR)
    unit_cost       NUMERIC(10,2) DEFAULT 0,   -- purchase cost (MYR)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- THE HEART OF THE SYSTEM: which parts fit which vehicles (many-to-many).
CREATE TABLE part_fitment (
    part_id     INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
    fitment_id  INT NOT NULL REFERENCES fitment(id) ON DELETE CASCADE,
    note        TEXT,                          -- e.g. "left side only"
    PRIMARY KEY (part_id, fitment_id)
);

-- OEM / interchange numbers so a part is findable by any known code.
CREATE TABLE part_crossref (
    id          SERIAL PRIMARY KEY,
    part_id     INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
    ref_number  TEXT NOT NULL,                 -- e.g. OEM "45046-09280"
    ref_type    TEXT DEFAULT 'OEM',            -- OEM / aftermarket / supersession
    UNIQUE (part_id, ref_number)
);

-- ---------------------------------------------------------------------------
-- INVENTORY & STOCK
-- ---------------------------------------------------------------------------

CREATE TABLE location (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE           -- e.g. "Main Warehouse Kuching"
);

CREATE TABLE inventory (
    id            SERIAL PRIMARY KEY,
    part_id       INT NOT NULL REFERENCES part(id),
    location_id   INT NOT NULL REFERENCES location(id),
    quantity      INT NOT NULL DEFAULT 0,
    reorder_point INT NOT NULL DEFAULT 0,      -- low-stock alert threshold
    bin           TEXT,                        -- shelf/bin label
    UNIQUE (part_id, location_id)
);

-- Audit trail of every stock change (receiving, sale, adjustment).
CREATE TABLE stock_movement (
    id            SERIAL PRIMARY KEY,
    part_id       INT NOT NULL REFERENCES part(id),
    location_id   INT NOT NULL REFERENCES location(id),
    change_qty    INT NOT NULL,                -- +in / -out
    reason        TEXT NOT NULL,               -- 'receive','sale','adjust','return'
    ref           TEXT,                        -- invoice/PO number
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- SUPPLIERS (v2)
-- ---------------------------------------------------------------------------

CREATE TABLE supplier (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    phone       TEXT,
    email       TEXT,
    address     TEXT
);

-- ---------------------------------------------------------------------------
-- HELPFUL VIEW: find parts that fit a given vehicle+engine
-- Low-stock is anything where quantity <= reorder_point.
-- ---------------------------------------------------------------------------

CREATE VIEW v_part_fitment AS
SELECT
    p.id            AS part_id,
    p.part_number,
    p.name          AS part_name,
    p.brand,
    p.unit_price,
    p.engine_specific,
    mk.name         AS make,
    md.name         AS model,
    e.code          AS engine_code,
    f.year_from,
    f.year_to,
    f.transmission,
    f.drivetrain,
    f.body_type,
    f.variant,
    pf.note
FROM part p
JOIN part_fitment pf ON pf.part_id = p.id
JOIN fitment f       ON f.id = pf.fitment_id
JOIN vehicle_model md ON md.id = f.model_id
JOIN vehicle_make mk  ON mk.id = md.make_id
LEFT JOIN engine e    ON e.id = f.engine_id;

-- NOTE on multiple brands / price points:
-- The same functional part (e.g. "Tie Rod End for Ranger") can exist as several
-- rows in `part` — one per brand (555, CTR, Genuine) — each with its own
-- part_number and unit_price. They all link to the SAME fitment(s), so a vehicle
-- lookup returns every brand option, letting the customer choose by price.

-- Indexes for fast vehicle-based lookup
CREATE INDEX idx_fitment_model  ON fitment(model_id);
CREATE INDEX idx_fitment_engine ON fitment(engine_id);
CREATE INDEX idx_partfitment_part ON part_fitment(part_id);
CREATE INDEX idx_crossref_number ON part_crossref(ref_number);
