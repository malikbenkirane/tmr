-- Signal‑to‑noise ratio rounded to two significant figures.
-- Example: a ratio of 4.0 is represented as 40.
ALTER TABLE app_settings ADD COLUMN signal_noise_ratio INTEGER DEFAULT 80; 

CREATE TABLE signal_noise_ratio_log (
    id               INTEGER PRIMARY KEY,
    logged_at        TEXT,
    ratio            INTEGER
);
