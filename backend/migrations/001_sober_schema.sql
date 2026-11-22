-- Sober application tables. Run as the database administrator.
BEGIN;
CREATE SCHEMA IF NOT EXISTS sober;
REVOKE ALL ON SCHEMA sober FROM PUBLIC, anon, authenticated, service_role;
CREATE TABLE IF NOT EXISTS sober.user_sober (
    id SERIAL NOT NULL,
    name VARCHAR(120) NOT NULL,
    username VARCHAR(80) NOT NULL,
    email VARCHAR(180) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL,
    created_at VARCHAR,
    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS ix_sober_user_sober_email ON sober.user_sober (email);
CREATE INDEX IF NOT EXISTS ix_sober_user_sober_id ON sober.user_sober (id);
CREATE UNIQUE INDEX IF NOT EXISTS ix_sober_user_sober_username ON sober.user_sober (username);
ALTER TABLE sober.user_sober ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE sober.user_sober FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS sober.habit_sober (
    id SERIAL NOT NULL,
    record_id BIGINT NOT NULL,
    user_id INTEGER NOT NULL,
    name VARCHAR(160) NOT NULL,
    title VARCHAR(160) NOT NULL,
    description VARCHAR NOT NULL,
    reason VARCHAR NOT NULL,
    streak INTEGER NOT NULL,
    completed INTEGER NOT NULL,
    start_date VARCHAR(10) NOT NULL,
    start_at VARCHAR(40),
    first_start_date VARCHAR(10),
    streak_history JSON NOT NULL,
    color VARCHAR(80) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_habit_user_record UNIQUE (user_id, record_id),
    FOREIGN KEY(user_id) REFERENCES sober.user_sober (id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ix_sober_habit_sober_user_id ON sober.habit_sober (user_id);
ALTER TABLE sober.habit_sober ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE sober.habit_sober FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS sober.journal_entry_sober (
    id SERIAL NOT NULL,
    record_id BIGINT NOT NULL,
    user_id INTEGER NOT NULL,
    date VARCHAR(10) NOT NULL,
    mood VARCHAR(80) NOT NULL,
    note VARCHAR NOT NULL,
    triggers JSON NOT NULL,
    habit_id BIGINT,
    habit_name VARCHAR(160),
    PRIMARY KEY (id),
    CONSTRAINT uq_journal_user_record UNIQUE (user_id, record_id),
    FOREIGN KEY(user_id) REFERENCES sober.user_sober (id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ix_sober_journal_entry_sober_user_id ON sober.journal_entry_sober (user_id);
ALTER TABLE sober.journal_entry_sober ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE sober.journal_entry_sober FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS sober.urge_log_sober (
    id SERIAL NOT NULL,
    record_id BIGINT NOT NULL,
    user_id INTEGER NOT NULL,
    time VARCHAR(40) NOT NULL,
    trigger VARCHAR NOT NULL,
    intensity INTEGER NOT NULL,
    coping VARCHAR NOT NULL,
    habit_id BIGINT,
    habit_name VARCHAR(160),
    PRIMARY KEY (id),
    CONSTRAINT uq_urge_user_record UNIQUE (user_id, record_id),
    FOREIGN KEY(user_id) REFERENCES sober.user_sober (id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ix_sober_urge_log_sober_user_id ON sober.urge_log_sober (user_id);
ALTER TABLE sober.urge_log_sober ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE sober.urge_log_sober FROM PUBLIC, anon, authenticated, service_role;


DO $$
DECLARE
    table_name text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sober_app') THEN
        CREATE ROLE sober_app NOLOGIN CONNECTION LIMIT 15;
    END IF;

    GRANT USAGE ON SCHEMA sober TO sober_app;
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA sober TO sober_app;
    GRANT USAGE ON ALL SEQUENCES IN SCHEMA sober TO sober_app;

    FOREACH table_name IN ARRAY ARRAY['user_sober', 'habit_sober', 'journal_entry_sober', 'urge_log_sober']
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE schemaname = 'sober' AND tablename = table_name AND policyname = 'sober_backend'
        ) THEN
            EXECUTE format(
                'CREATE POLICY sober_backend ON sober.%I TO sober_app USING (true) WITH CHECK (true)',
                table_name
            );
        END IF;
    END LOOP;
END $$;

COMMIT;
