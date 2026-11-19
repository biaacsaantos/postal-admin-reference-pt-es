-- =====================================================================
-- 02 | Primary keys, foreign keys and indexes
--
-- Run after the data has been loaded and the quality problems fixed
-- (see notebook 08). The model is the same as the Power BI data model
-- (docs/data_model.png).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Primary keys
-- ---------------------------------------------------------------------
ALTER TABLE reference.nuts0          ADD CONSTRAINT pk_nuts0          PRIMARY KEY (nuts0_id);
ALTER TABLE reference.nuts1          ADD CONSTRAINT pk_nuts1          PRIMARY KEY (nuts1_id);
ALTER TABLE reference.nuts2          ADD CONSTRAINT pk_nuts2          PRIMARY KEY (nuts2_id);
ALTER TABLE reference.nuts3          ADD CONSTRAINT pk_nuts3          PRIMARY KEY (nuts3_id);
ALTER TABLE reference.districts      ADD CONSTRAINT pk_districts      PRIMARY KEY (district_id);
ALTER TABLE reference.municipalities ADD CONSTRAINT pk_municipalities PRIMARY KEY (municipality_id);
ALTER TABLE reference.localities     ADD CONSTRAINT pk_localities     PRIMARY KEY (locality_id);
ALTER TABLE reference.postal_codes   ADD CONSTRAINT pk_postal_codes   PRIMARY KEY (postal_code);

-- ---------------------------------------------------------------------
-- Foreign keys (all relationships are one-to-many)
-- ---------------------------------------------------------------------
ALTER TABLE reference.postal_codes
    ADD CONSTRAINT fk_postal_codes_nuts0      FOREIGN KEY (nuts0_id)    REFERENCES reference.nuts0 (nuts0_id),
    ADD CONSTRAINT fk_postal_codes_nuts1      FOREIGN KEY (nuts1_id)    REFERENCES reference.nuts1 (nuts1_id),
    ADD CONSTRAINT fk_postal_codes_nuts2      FOREIGN KEY (nuts2_id)    REFERENCES reference.nuts2 (nuts2_id),
    ADD CONSTRAINT fk_postal_codes_nuts3      FOREIGN KEY (nuts3_id)    REFERENCES reference.nuts3 (nuts3_id),
    ADD CONSTRAINT fk_postal_codes_localities FOREIGN KEY (locality_id) REFERENCES reference.localities (locality_id);

ALTER TABLE reference.localities
    ADD CONSTRAINT fk_localities_municipalities FOREIGN KEY (municipality_id) REFERENCES reference.municipalities (municipality_id),
    ADD CONSTRAINT fk_localities_districts      FOREIGN KEY (district_id)     REFERENCES reference.districts (district_id);

-- ---------------------------------------------------------------------
-- Indexes on foreign keys (faster joins)
-- ---------------------------------------------------------------------
CREATE INDEX idx_postal_codes_nuts3       ON reference.postal_codes (nuts3_id);
CREATE INDEX idx_postal_codes_locality    ON reference.postal_codes (locality_id);
CREATE INDEX idx_localities_municipality  ON reference.localities (municipality_id);
CREATE INDEX idx_localities_district      ON reference.localities (district_id);

-- ---------------------------------------------------------------------
-- Spatial indexes (GiST) for spatial queries
-- ---------------------------------------------------------------------
CREATE INDEX gix_nuts3_geometry          ON reference.nuts3          USING GIST (geometry);
CREATE INDEX gix_districts_geometry      ON reference.districts      USING GIST (geometry);
CREATE INDEX gix_municipalities_geometry ON reference.municipalities USING GIST (geometry);
CREATE INDEX gix_localities_geometry     ON reference.localities     USING GIST (geometry);
CREATE INDEX gix_postal_codes_geometry   ON reference.postal_codes   USING GIST (geometry);

ANALYZE;
