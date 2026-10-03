-- Real schema of the mcp-memory-service 10.74.1 sqlite-vec database.
-- Dumped from a .backup copy via sqlite_master (never from the live file).
-- Shadow tables of the fts5 and vec0 virtual tables are omitted: SQLite recreates them.
-- Executing this needs the sqlite_vec extension loaded (vec0 virtual table).

CREATE TABLE metadata (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );

CREATE TABLE memories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    content_hash TEXT UNIQUE NOT NULL,
                    content TEXT NOT NULL,
                    tags TEXT,
                    memory_type TEXT,
                    metadata TEXT,
                    created_at REAL,
                    updated_at REAL,
                    created_at_iso TEXT,
                    updated_at_iso TEXT,
                    deleted_at REAL DEFAULT NULL
                , parent_id TEXT, version INTEGER DEFAULT 1, confidence REAL DEFAULT 1.0, last_accessed INTEGER, superseded_by TEXT);

CREATE VIRTUAL TABLE memory_content_fts USING fts5(
                    content,
                    content='memories',
                    content_rowid='id',
                    tokenize='trigram'
                );

CREATE TRIGGER memories_fts_ai AFTER INSERT ON memories
                BEGIN
                    INSERT INTO memory_content_fts(rowid, content)
                    VALUES (new.id, new.content);
                END;

CREATE TRIGGER memories_fts_au AFTER UPDATE ON memories
                BEGIN
                    DELETE FROM memory_content_fts WHERE rowid = old.id;
                    INSERT INTO memory_content_fts(rowid, content)
                    VALUES (new.id, new.content);
                END;

CREATE TRIGGER memories_fts_ad AFTER DELETE ON memories
                BEGIN
                    DELETE FROM memory_content_fts WHERE rowid = old.id;
                END;

CREATE INDEX idx_content_hash ON memories(content_hash);

CREATE INDEX idx_created_at ON memories(created_at);

CREATE INDEX idx_memory_type ON memories(memory_type);

CREATE INDEX idx_deleted_at ON memories(deleted_at);

CREATE TABLE memory_graph (
    source_hash TEXT NOT NULL,
    target_hash TEXT NOT NULL,
    similarity REAL NOT NULL,
    connection_types TEXT NOT NULL,  -- JSON array: ["semantic", "temporal", "causal", "thematic"]
    metadata TEXT,                   -- JSON object: {discovery_date, confidence, context}
    created_at REAL NOT NULL, relationship_type TEXT DEFAULT 'related',
    PRIMARY KEY (source_hash, target_hash)
);

CREATE INDEX idx_graph_source ON memory_graph(source_hash);

CREATE INDEX idx_graph_target ON memory_graph(target_hash);

CREATE INDEX idx_graph_relationship ON memory_graph(relationship_type);

CREATE TABLE migration_registry (
                version INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                filename TEXT NOT NULL,
                applied_at TEXT NOT NULL,
                checksum TEXT
            );

CREATE TABLE beliefs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    belief_hash TEXT UNIQUE NOT NULL,
    content TEXT NOT NULL,
    confidence REAL NOT NULL DEFAULT 0.5,
    status TEXT NOT NULL DEFAULT 'candidate',  -- candidate, active, disputed, superseded
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    derived_from TEXT NOT NULL DEFAULT '[]',  -- JSON array of observation content_hashes (provenance)
    contradicted_by TEXT NOT NULL DEFAULT '[]',  -- JSON array of observation content_hashes
    metadata TEXT DEFAULT '{}'
);

CREATE INDEX idx_beliefs_status ON beliefs(status);

CREATE INDEX idx_beliefs_confidence ON beliefs(confidence);

CREATE VIRTUAL TABLE memory_embeddings USING vec0(content_embedding FLOAT[768] distance_metric=cosine);
