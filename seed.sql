-- ============================================================================
-- Seed data — demonstrates the two hard compatibility cases:
--   (A) One tie rod end that fits BOTH Ford Ranger and Mazda BT-50
--   (B) A starter motor that is ENGINE-SPECIFIC (Toyota 2KD only)
-- ============================================================================

-- Makes
INSERT INTO vehicle_make (name) VALUES ('Toyota'), ('Ford'), ('Mazda');

-- Models
INSERT INTO vehicle_model (make_id, name) VALUES
  ((SELECT id FROM vehicle_make WHERE name='Toyota'), 'Hilux'),
  ((SELECT id FROM vehicle_make WHERE name='Toyota'), 'Fortuner'),
  ((SELECT id FROM vehicle_make WHERE name='Ford'),   'Ranger'),
  ((SELECT id FROM vehicle_make WHERE name='Mazda'),  'BT-50');

-- Engines
INSERT INTO engine (code, description) VALUES
  ('2KD', '2.5L Diesel'),
  ('2TR', '2.7L Petrol'),
  ('WLAT','2.5L Diesel (Ford/Mazda)');

-- Categories
INSERT INTO part_category (name) VALUES ('Steering'), ('Electrical'), ('Brakes');

-- ---------------------------------------------------------------------------
-- CASE A: Tie Rod End — shared across Ford Ranger + Mazda BT-50, engine-agnostic
-- ---------------------------------------------------------------------------
INSERT INTO part (part_number, name, category_id, brand, engine_specific, unit_price, unit_cost)
VALUES ('TRE-555-1001', 'Tie Rod End (Outer)',
        (SELECT id FROM part_category WHERE name='Steering'),
        '555', FALSE, 85.00, 52.00);

-- Fitments (engine NULL = fits any engine of that model/year)
INSERT INTO fitment (model_id, engine_id, year_from, year_to, variant) VALUES
  ((SELECT id FROM vehicle_model WHERE name='Ranger'), NULL, 2011, 2020, '4x4'),
  ((SELECT id FROM vehicle_model WHERE name='BT-50'),  NULL, 2011, 2020, '4x4');

-- Link the tie rod to BOTH fitments
INSERT INTO part_fitment (part_id, fitment_id)
SELECT (SELECT id FROM part WHERE part_number='TRE-555-1001'), f.id
FROM fitment f
JOIN vehicle_model m ON m.id = f.model_id
WHERE m.name IN ('Ranger','BT-50');

-- ---------------------------------------------------------------------------
-- CASE B: Starter Motor — ENGINE-SPECIFIC (Toyota 2KD only)
-- Same Hilux with a 2TR petrol engine must NOT match this part.
-- ---------------------------------------------------------------------------
INSERT INTO part (part_number, name, category_id, brand, engine_specific, unit_price, unit_cost)
VALUES ('STR-DENSO-2KD', 'Starter Motor',
        (SELECT id FROM part_category WHERE name='Electrical'),
        'Denso', TRUE, 480.00, 350.00);

-- Fitments tied specifically to the 2KD engine
INSERT INTO fitment (model_id, engine_id, year_from, year_to, variant) VALUES
  ((SELECT id FROM vehicle_model WHERE name='Hilux'),
   (SELECT id FROM engine WHERE code='2KD'), 2005, 2015, NULL),
  ((SELECT id FROM vehicle_model WHERE name='Fortuner'),
   (SELECT id FROM engine WHERE code='2KD'), 2005, 2015, NULL);

INSERT INTO part_fitment (part_id, fitment_id)
SELECT (SELECT id FROM part WHERE part_number='STR-DENSO-2KD'), f.id
FROM fitment f
JOIN engine e ON e.id = f.engine_id
WHERE e.code = '2KD';

-- OEM cross-reference so the starter is findable by OEM number too
INSERT INTO part_crossref (part_id, ref_number, ref_type)
VALUES ((SELECT id FROM part WHERE part_number='STR-DENSO-2KD'), '28100-30050', 'OEM');

-- ---------------------------------------------------------------------------
-- Stock
-- ---------------------------------------------------------------------------
INSERT INTO location (name) VALUES ('Main Warehouse Kuching');

INSERT INTO inventory (part_id, location_id, quantity, reorder_point, bin) VALUES
  ((SELECT id FROM part WHERE part_number='TRE-555-1001'),
   (SELECT id FROM location WHERE name='Main Warehouse Kuching'), 24, 6, 'A-12'),
  ((SELECT id FROM part WHERE part_number='STR-DENSO-2KD'),
   (SELECT id FROM location WHERE name='Main Warehouse Kuching'), 3, 2, 'E-04');

-- ============================================================================
-- TRY IT: these queries prove the compatibility logic works.
-- ============================================================================

-- Q1: "Customer has a Ford Ranger" -> should return the tie rod end.
--   SELECT * FROM v_part_fitment WHERE make='Ford' AND model='Ranger';

-- Q2: "Customer has a Mazda BT-50" -> SAME tie rod end appears.
--   SELECT * FROM v_part_fitment WHERE make='Mazda' AND model='BT-50';

-- Q3: "Hilux with 2KD engine" -> returns the starter motor.
--   SELECT * FROM v_part_fitment WHERE model='Hilux' AND engine_code='2KD';

-- Q4: "Hilux with 2TR petrol" -> returns NOTHING for the starter (correct!),
--     protecting the customer from buying the wrong engine's starter.
--   SELECT * FROM v_part_fitment WHERE model='Hilux' AND engine_code='2TR';
