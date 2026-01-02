-- 20260102204229.sql add settings sit back, stoke, start and slow down goals
ALTER TABLE app_settings ADD COLUMN sit_back_goal DEFAULT 3;
ALTER TABLE app_settings ADD COLUMN stoke_goal DEFAULT 2;
ALTER TABLE app_settings ADD COLUMN start_slow_goal DEFAULT 3;
ALTER TABLE app_settings ADD COLUMN slow_down_goal DEFAULT 2;

CREATE TABLE special_goals_log (
  id INTEGER PRIMARY KEY,
  special_goal INTEGER, -- enum lib/domain/models/settings/special_goal.dart
  goal INTEGER -- multiple of 30 minutes
);
