# Architecture overview

This project follows a split responsibility model:

- React frontend for interfaces and user flows
- FastAPI backend for authenticated web APIs and business logic
- PostgreSQL persistence through SQLAlchemy, configured to use Supabase in production
- User-owned habits, streak history, journal entries, and urge logs load and save through the API so they stay in sync across devices
- A one-time authenticated import moves legacy IndexedDB records into PostgreSQL; IndexedDB is not used for ongoing app data

The frontend is intentionally structured around focused feature modules and a shared components layer, while the backend exposes v1 routes for authentication, dashboard metrics, habits, commitments, journaling, urges, statistics, and community.

## Sober database

Production PostgreSQL stores application data in the `sober` schema of
`guatec-production`. The tables are `user_sober`, `habit_sober`,
`journal_entry_sober`, and `urge_log_sober`. Create them as an administrator
with [the schema migration](../backend/migrations/001_sober_schema.sql). Give
the `sober_app` role a login credential and set the backend's `DATABASE_URL`
to its TLS-enabled Supabase pooler URL. Set `SECRET_KEY` in the backend's
runtime environment. The role can access the Sober tables and their sequences.

Deploy `backend/` as a FastAPI project on Vercel and set `VITE_API_URL` in
the existing frontend project to the backend's production URL. The API's
`/health` route checks that it can read the Sober schema.
