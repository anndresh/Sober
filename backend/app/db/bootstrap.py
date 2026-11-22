from sqlalchemy import inspect, text

from app.db.session import Base
from app.models.records import HabitRecord, JournalRecord, UrgeRecord
from app.models.user import User


def initialize_local_database(engine):
    legacy_names = {
        'users': User.__tablename__,
        'habits': HabitRecord.__tablename__,
        'journal_entries': JournalRecord.__tablename__,
        'urge_logs': UrgeRecord.__tablename__,
    }

    with engine.begin() as connection:
        # Ensure table renames also update foreign keys on SQLite builds with legacy defaults.
        connection.exec_driver_sql('PRAGMA legacy_alter_table=OFF')
        connection.exec_driver_sql('BEGIN IMMEDIATE')
        tables = set(inspect(connection).get_table_names())
        for old_name, new_name in legacy_names.items():
            if old_name in tables and new_name not in tables:
                connection.execute(text(f'ALTER TABLE {old_name} RENAME TO {new_name}'))

        Base.metadata.create_all(bind=connection)
        habit_table = HabitRecord.__tablename__
        columns = {column['name'] for column in inspect(connection).get_columns(habit_table)}
        for name, column_type in (('first_start_date', 'VARCHAR(10)'), ('start_at', 'VARCHAR(40)')):
            if name not in columns:
                connection.execute(text(f'ALTER TABLE {habit_table} ADD COLUMN {name} {column_type}'))
