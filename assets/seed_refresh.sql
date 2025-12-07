DELETE FROM routines;
DELETE FROM routines_logs;
INSERT INTO routines (id, name, goal_30m, spent_1s, running) VALUES(1, 'foo', 2, 0, 0);
INSERT INTO routines (id, name, goal_30m, spent_1s, running) VALUES(2, 'bar', 3, 12, 0);
INSERT INTO routines (id, name, goal_30m, spent_1s, running) VALUES(3, 'bob', 1, 100, 1);
INSERT INTO routines (id, name, goal_30m, spent_1s, running) VALUES(4, 'far', 1, 100, 1);
INSERT INTO routines_logs (routine_id, updated_at, state) VALUES(1, '20251128T1200Z', 1); -- foo started not stopped
INSERT INTO routines_logs (routine_id, updated_at, state) VALUES(2, '20251129T1200Z', 1); -- bar started
INSERT INTO routines_logs (routine_id, updated_at, state) VALUES(2, '20251129T1400Z', 0); -- bar stopped
INSERT INTO routines_logs (routine_id, updated_at, state) VALUES(3, '20251129T1400Z', 1); -- bob started not stopped
INSERT INTO routines_logs (routine_id, updated_at, state) VALUES(4, DATETIME('now', '-00:06'), 1); -- far started not stopped
-- expected:
-- - foo: unchanged
-- - bar: spent == 0
-- - bob: sepnt == 0 and running == 0
-- - far: spent == 6 and running  == 1
