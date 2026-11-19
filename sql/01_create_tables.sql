-- =====================================================================
-- 01 | Create schema and tables (without constraints)
--
-- The tables are created without primary and foreign keys so that the
-- data can be loaded first and checked for quality problems
-- (duplicates, orphan keys, invalid geometries). The constraints are
-- added afterwards in 02_constraints.sql.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS reference;

-- Drop in reverse order of dependency, so the script can be run again
DROP TABLE IF EXISTS reference.postal_codes CASCADE;
DROP TABLE IF EXISTS reference.localities CASCADE;
DROP TABLE IF EXISTS reference.municipalities CASCADE;
DROP TABLE IF EXISTS reference.districts CASCADE;
DROP TABLE IF EXISTS reference.nuts3 CASCADE;
DROP TABLE IF EXISTS reference.nuts2 CASCADE;
DROP TABLE IF EXISTS reference.nuts1 CASCADE;
DROP TABLE IF EXISTS reference.nuts0 CASCADE;

-- ---------------------------------------------------------------------
-- NUTS (Eurostat)
-- ---------------------------------------------------------------------
CREATE TABLE reference.nuts0 (
    nuts0_id    VARCHAR(2),
    nuts0_name  TEXT,
    lon_cent    DOUBLE PRECISION,
    lat_cent    DOUBLE PRECISION,
    geometry    GEOMETRY(MultiPolygon, 4326)
);

CREATE TABLE reference.nuts1 (
    nuts1_id    VARCHAR(3),
    nuts1_name  TEXT,
    lon_cent    DOUBLE PRECISION,
    lat_cent    DOUBLE PRECISION,
    geometry    GEOMETRY(MultiPolygon, 4326)
);

CREATE TABLE reference.nuts2 (
    nuts2_id    VARCHAR(4),
    nuts2_name  TEXT,
    lon_cent    DOUBLE PRECISION,
    lat_cent    DOUBLE PRECISION,
    geometry    GEOMETRY(MultiPolygon, 4326)
);

CREATE TABLE reference.nuts3 (
    nuts3_id       VARCHAR(5),
    nuts3_name     TEXT,
    mountain_type  SMALLINT,
    urban_type     SMALLINT,
    coastal_type   SMALLINT,
    lon_cent       DOUBLE PRECISION,
    lat_cent       DOUBLE PRECISION,
    geometry       GEOMETRY(MultiPolygon, 4326)
);

-- ---------------------------------------------------------------------
-- Districts and municipalities of Portugal (CAOP)
-- ---------------------------------------------------------------------
CREATE TABLE reference.districts (
    district_id    VARCHAR(10),
    district_name  TEXT,
    area_ha        DOUBLE PRECISION,
    perimeter_km   DOUBLE PRECISION,
    lon_cent       DOUBLE PRECISION,
    lat_cent       DOUBLE PRECISION,
    geometry       GEOMETRY(MultiPolygon, 4326)
);

CREATE TABLE reference.municipalities (
    municipality_id    VARCHAR(10),
    municipality_name  TEXT,
    area_ha            DOUBLE PRECISION,
    perimeter_km       DOUBLE PRECISION,
    lon_cent           DOUBLE PRECISION,
    lat_cent           DOUBLE PRECISION,
    geometry           GEOMETRY(MultiPolygon, 4326)
);

-- ---------------------------------------------------------------------
-- Localities (Eurostat LAU) and postal codes (Eurostat GISCO)
-- ---------------------------------------------------------------------
CREATE TABLE reference.localities (
    locality_id       VARCHAR(20),
    municipality_id   VARCHAR(10),
    district_id       VARCHAR(10),
    locality_name     TEXT,
    population_2024   INTEGER,
    area_km2          DOUBLE PRECISION,
    locality_name_id  TEXT,
    lon_cent          DOUBLE PRECISION,
    lat_cent          DOUBLE PRECISION,
    geometry          GEOMETRY(MultiPolygon, 4326)
);

CREATE TABLE reference.postal_codes (
    postal_code  VARCHAR(10),
    nuts3_id     VARCHAR(5),
    nuts2_id     VARCHAR(4),
    nuts1_id     VARCHAR(3),
    nuts0_id     VARCHAR(2),
    locality_id  VARCHAR(20),
    degree_urb   SMALLINT,
    lon_cent     DOUBLE PRECISION,
    lat_cent     DOUBLE PRECISION,
    geometry     GEOMETRY(Point, 4326)
);
