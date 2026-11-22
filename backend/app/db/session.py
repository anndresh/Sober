from sqlalchemy import MetaData, create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

from app.core.config import get_settings

settings = get_settings()
database_url = settings.database_url
if database_url.startswith('postgresql://'):
    database_url = database_url.replace('postgresql://', 'postgresql+psycopg://', 1)
url = make_url(database_url)
engine_options = {}
if url.get_backend_name() == 'sqlite':
    engine_options['connect_args'] = {'check_same_thread': False}
elif url.get_backend_name() == 'postgresql':
    engine_options['connect_args'] = {'connect_timeout': 5}
    # Supavisor's transaction mode manages the connection pool itself.
    if url.port == 6543:
        engine_options['connect_args']['prepare_threshold'] = None
        engine_options['poolclass'] = NullPool
engine = create_engine(url, pool_pre_ping=True, **engine_options)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base(metadata=MetaData(schema='sober' if engine.dialect.name == 'postgresql' else None))


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
