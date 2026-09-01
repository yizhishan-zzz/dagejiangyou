# Database deployment

The Spring Boot application currently uses a custom JWT service and maps its
JPA entities to the `public.users`, `tasks`, `orders`, `pools`, `wallets`, and
related runtime tables. The canonical PostgreSQL installation script is:

`migrations/20260901_backend_runtime_schema.sql`

Run that script once on a new Supabase project, then run the backend seed
script. It includes indexes, update timestamps, money/location constraints,
and RLS policies for direct Supabase client access.

`migrations/20260525_phase1_supabase_schema.sql` is retained as an earlier
design reference for a future Supabase Auth based architecture. It creates a
different `profiles` and PostGIS model and must not be run in the same
database as the current Spring runtime schema.

For Alibaba Cloud RDS PostgreSQL, use `backend/src/main/resources/schema.sql`
instead. RDS does not provide Supabase's `auth.uid()` function, so the
application API and database owner remain the security boundary there.
