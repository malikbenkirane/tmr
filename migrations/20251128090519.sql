-- Create routines table
CREATE TABLE routines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    goal_30m INTEGER NOT NULL,
    spent_1s INTEGER NOT NULL,
    running BOOLEAN NOT NULL
);

-- Create routines_logs table
CREATE TABLE routines_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    routine_id INTEGER NOT NULL,
    updated_at DATETIME NOT NULL,
    state INTEGER NOT NULL,
    FOREIGN KEY (routine_id) REFERENCES routines(id)
);

-- Optional: Create indexes for better performance
CREATE INDEX idx_routines_logs_id ON routines_logs(id);
CREATE INDEX idx_routines_logs_updated_at ON routines_logs(updated_at);
