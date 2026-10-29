-- Plano RLS User-Isolation Verification Script
-- Simulates User A and User B to prove strict tenant isolation and data protection.

DO $$
DECLARE
    user_a UUID := '11111111-1111-1111-1111-111111111111';
    user_b UUID := '22222222-2222-2222-2222-222222222222';
    rec_count INTEGER;
BEGIN
    -- 1. Setup mock profiles & tasks
    SET LOCAL ROLE postgres;

    -- User A creates a task and health summary
    INSERT INTO public.tasks (id, user_id, title, status, priority)
    VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', user_a, 'User A Secret Task', 'todo', 'high')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.health_summaries (id, user_id, date, step_count, workout_duration_minutes)
    VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', user_a, CURRENT_DATE, 8450, 45)
    ON CONFLICT (id) DO NOTHING;

    -- 2. Switch to User B identity via Supabase JWT claim simulation
    PERFORM set_config('request.jwt.claim.sub', user_b::text, true);
    PERFORM set_config('role', 'authenticated', true);

    -- User B attempts to read User A's tasks
    SELECT COUNT(*) INTO rec_count FROM public.tasks WHERE user_id = user_a;
    IF rec_count > 0 THEN
        RAISE EXCEPTION 'SECURITY BREACH: User B could view User A tasks! (Count: %)', rec_count;
    END IF;

    -- User B attempts to read User A's health summaries
    SELECT COUNT(*) INTO rec_count FROM public.health_summaries WHERE user_id = user_a;
    IF rec_count > 0 THEN
        RAISE EXCEPTION 'SECURITY BREACH: User B could view User A health data! (Count: %)', rec_count;
    END IF;

    -- User B attempts to update User A's task
    UPDATE public.tasks SET title = 'Hacked' WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    
    -- User B attempts to delete User A's task
    DELETE FROM public.tasks WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    -- Reset to postgres to verify User A's task was unaffected
    SET LOCAL ROLE postgres;
    SELECT COUNT(*) INTO rec_count FROM public.tasks 
    WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' AND title = 'User A Secret Task';
    
    IF rec_count != 1 THEN
        RAISE EXCEPTION 'SECURITY BREACH: User A task was modified or deleted by User B!';
    END IF;

    RAISE NOTICE 'SUCCESS: RLS tenant isolation verified! User B cannot read, update, or delete User A records.';
END $$;
