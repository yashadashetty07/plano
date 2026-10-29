-- Run against a Supabase project only after migration, using SQL Editor as an
-- administrator. Supply two existing auth.users UUIDs before running:
--   SET plano.test_user_a = '<user A UUID>';
--   SET plano.test_user_b = '<user B UUID>';
-- The entire test rolls back and creates no lasting records.
BEGIN;

DO $$
DECLARE
    user_a UUID := NULLIF(current_setting('plano.test_user_a', true), '')::UUID;
    user_b UUID := NULLIF(current_setting('plano.test_user_b', true), '')::UUID;
    test_task UUID := gen_random_uuid();
    test_health UUID := gen_random_uuid();
    found_count INTEGER;
BEGIN
    IF user_a IS NULL OR user_b IS NULL OR user_a = user_b THEN
        RAISE EXCEPTION 'Set plano.test_user_a and plano.test_user_b to two distinct existing auth.users UUIDs';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_a)
       OR NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_b) THEN
        RAISE EXCEPTION 'Both test UUIDs must exist in auth.users';
    END IF;

    INSERT INTO public.tasks (id, user_id, title)
    VALUES (test_task, user_a, 'RLS isolation fixture');
    INSERT INTO public.health_summaries (id, user_id, date, step_count)
    VALUES (test_health, user_a, CURRENT_DATE, 123, 'RLS fixture');

    -- Switch the effective database role and JWT identity to user B.
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM set_config('request.jwt.claim.sub', user_b::TEXT, true);
    PERFORM set_config('request.jwt.claims', json_build_object('sub', user_b, 'role', 'authenticated')::TEXT, true);

    SELECT count(*) INTO found_count FROM public.tasks WHERE id = test_task;
    IF found_count <> 0 THEN RAISE EXCEPTION 'User B read User A task'; END IF;
    SELECT count(*) INTO found_count FROM public.health_summaries WHERE id = test_health;
    IF found_count <> 0 THEN RAISE EXCEPTION 'User B read User A health summary'; END IF;

    UPDATE public.tasks SET title = 'RLS tampered' WHERE id = test_task;
    IF FOUND THEN RAISE EXCEPTION 'User B updated User A task'; END IF;
    DELETE FROM public.tasks WHERE id = test_task;
    IF FOUND THEN RAISE EXCEPTION 'User B deleted User A task'; END IF;
    UPDATE public.health_summaries SET step_count = 999 WHERE id = test_health;
    IF FOUND THEN RAISE EXCEPTION 'User B updated User A health summary'; END IF;
    DELETE FROM public.health_summaries WHERE id = test_health;
    IF FOUND THEN RAISE EXCEPTION 'User B deleted User A health summary'; END IF;
    RAISE NOTICE 'RLS isolation checks passed for reads, updates, and deletes.';
END $$;

ROLLBACK;
