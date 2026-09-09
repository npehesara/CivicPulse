-- CivicPulse Database Migration: Home Location & 25 Sri Lankan Districts
-- Safe for execution on production (e.g., Aiven PostgreSQL)

-- 1. Add home location and territory_id columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS home_latitude DOUBLE PRECISION;
ALTER TABLE users ADD COLUMN IF NOT EXISTS home_longitude DOUBLE PRECISION;
ALTER TABLE users ADD COLUMN IF NOT EXISTS territory_id BIGINT;

-- 2. Migrate existing registered_territory_id values to territory_id if present
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'registered_territory_id'
    ) THEN
        UPDATE users
        SET territory_id = registered_territory_id
        WHERE territory_id IS NULL AND registered_territory_id IS NOT NULL;
    END IF;
END $$;

-- 3. Insert the 25 Sri Lankan administrative districts into territories table if not present
-- Note: Uses Western, Central, Southern, Northern, Eastern, North Western, North Central, Uva, and Sabaragamuwa as parent provinces.

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'Western Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'Western Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'Central Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'Central Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'Southern Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'Southern Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'Northern Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'Northern Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'Eastern Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'Eastern Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'North Western Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'North Western Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'North Central Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'North Central Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'Uva Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'Uva Province');

INSERT INTO territories (territory_name, territory_type, boundary_geometry, created_at)
SELECT 'Sabaragamuwa Province', 'PROVINCE', NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = 'Sabaragamuwa Province');

-- Insert 25 Districts referencing parent province
INSERT INTO territories (territory_name, territory_type, parent_territory_id, boundary_geometry, created_at)
SELECT d.name, 'DISTRICT', p.territory_id, NULL, NOW()
FROM (VALUES
    ('Colombo', 'Western Province'),
    ('Gampaha', 'Western Province'),
    ('Kalutara', 'Western Province'),
    ('Kandy', 'Central Province'),
    ('Matale', 'Central Province'),
    ('Nuwara Eliya', 'Central Province'),
    ('Galle', 'Southern Province'),
    ('Matara', 'Southern Province'),
    ('Hambantota', 'Southern Province'),
    ('Jaffna', 'Northern Province'),
    ('Kilinochchi', 'Northern Province'),
    ('Mannar', 'Northern Province'),
    ('Vavuniya', 'Northern Province'),
    ('Mullaitivu', 'Northern Province'),
    ('Batticaloa', 'Eastern Province'),
    ('Ampara', 'Eastern Province'),
    ('Trincomalee', 'Eastern Province'),
    ('Kurunegala', 'North Western Province'),
    ('Puttalam', 'North Western Province'),
    ('Anuradhapura', 'North Central Province'),
    ('Polonnaruwa', 'North Central Province'),
    ('Badulla', 'Uva Province'),
    ('Monaragala', 'Uva Province'),
    ('Ratnapura', 'Sabaragamuwa Province'),
    ('Kegalle', 'Sabaragamuwa Province')
) AS d(name, province)
JOIN territories p ON p.territory_name = d.province
WHERE NOT EXISTS (SELECT 1 FROM territories WHERE territory_name = d.name);
