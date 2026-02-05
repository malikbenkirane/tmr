ALTER TABLE routines ADD COLUMN bin BOOLEAN NOT NULL DEFAULT 0;
UPDATE TABLE routines SET bin = -1 WHERE archived = 1;
UPDATE TABLE routines SET bin = -2 WHERE binned = 1;
