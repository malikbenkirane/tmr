CREATE TABLE note_graph (
    edge_id INTEGER PRIMARY KEY,
    note_a INTEGER NOT NULL,
    note_b INTEGER NOT NULL,
    created_at TEXT NOT NULL
);
