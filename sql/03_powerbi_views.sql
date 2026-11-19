-- =====================================================================
-- 03 | Views for Power BI
--
-- Power BI does not need the geometry column (the maps use the
-- TopoJSON/GeoJSON files), so these views expose only the attributes.
-- In Power BI: Get data -> PostgreSQL database -> select the views.
-- =====================================================================

CREATE OR REPLACE VIEW reference.v_postal_codes AS
SELECT postal_code, nuts3_id, nuts2_id, nuts1_id, nuts0_id, locality_id, degree_urb, lon_cent, lat_cent
FROM reference.postal_codes;

CREATE OR REPLACE VIEW reference.v_localities AS
SELECT locality_id, municipality_id, district_id, locality_name, population_2024, area_km2,
       locality_name_id, lon_cent, lat_cent
FROM reference.localities;

CREATE OR REPLACE VIEW reference.v_municipalities AS
SELECT municipality_id, municipality_name, area_ha, perimeter_km, lon_cent, lat_cent
FROM reference.municipalities;

CREATE OR REPLACE VIEW reference.v_districts AS
SELECT district_id, district_name, area_ha, perimeter_km, lon_cent, lat_cent
FROM reference.districts;

CREATE OR REPLACE VIEW reference.v_nuts0 AS
SELECT nuts0_id, nuts0_name, lon_cent, lat_cent FROM reference.nuts0;

CREATE OR REPLACE VIEW reference.v_nuts1 AS
SELECT nuts1_id, nuts1_name, lon_cent, lat_cent FROM reference.nuts1;

CREATE OR REPLACE VIEW reference.v_nuts2 AS
SELECT nuts2_id, nuts2_name, lon_cent, lat_cent FROM reference.nuts2;

CREATE OR REPLACE VIEW reference.v_nuts3 AS
SELECT nuts3_id, nuts3_name, mountain_type, urban_type, coastal_type, lon_cent, lat_cent
FROM reference.nuts3;
