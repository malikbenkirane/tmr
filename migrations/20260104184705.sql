CREATE TABLE special_goal_sessions (
  id INTEGER PRIMARY KEY,
  code INTEGER, -- special goal code as defined in lib/domain/models/settings/special_goal.dart
  started_at STRING,
  stopped_at STRING
);
