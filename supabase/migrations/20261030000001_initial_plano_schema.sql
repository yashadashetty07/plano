-- PLANO Master Database Schema & Row Level Security (RLS)
-- Single Source of Truth for Plano Personal Productivity & Activity Tracking

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    theme_mode TEXT NOT NULL DEFAULT 'system',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 2. WORKSPACES (Private personal default, explicit membership for shared)
CREATE TABLE IF NOT EXISTS public.workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_personal BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.workspace_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(workspace_id, user_id)
);

ALTER TABLE public.workspace_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "workspaces_access" ON public.workspaces;
CREATE POLICY "workspaces_access" ON public.workspaces
    FOR ALL USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "workspace_members_access" ON public.workspace_members;
DROP POLICY IF EXISTS "workspace_members_select" ON public.workspace_members;
DROP POLICY IF EXISTS "workspace_members_owner_manage" ON public.workspace_members;
CREATE POLICY "workspace_members_select" ON public.workspace_members
    FOR SELECT USING (
        auth.uid() = user_id OR EXISTS (
            SELECT 1 FROM public.workspaces
            WHERE workspaces.id = workspace_members.workspace_id
              AND workspaces.owner_id = auth.uid()
        )
    );
CREATE POLICY "workspace_members_owner_manage" ON public.workspace_members
    FOR ALL USING (EXISTS (
        SELECT 1 FROM public.workspaces
        WHERE workspaces.id = workspace_members.workspace_id
          AND workspaces.owner_id = auth.uid()
    )) WITH CHECK (EXISTS (
        SELECT 1 FROM public.workspaces
        WHERE workspaces.id = workspace_members.workspace_id
          AND workspaces.owner_id = auth.uid()
    ));

-- 3. PROJECTS
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workspace_id UUID REFERENCES public.workspaces(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'completed', 'archived', 'on_hold'
    target_date DATE,
    category TEXT,
    icon TEXT,
    color TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "projects_user_isolation" ON public.projects;
CREATE POLICY "projects_user_isolation" ON public.projects
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_projects_user_id ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(user_id, status);

-- 4. TASKS
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'todo', -- 'todo', 'in_progress', 'completed', 'cancelled'
    priority TEXT NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    due_date DATE,
    scheduled_at TIMESTAMPTZ,
    category TEXT,
    tags TEXT[] DEFAULT '{}',
    estimated_minutes INTEGER NOT NULL DEFAULT 0 CHECK (estimated_minutes >= 0),
    actual_minutes INTEGER NOT NULL DEFAULT 0 CHECK (actual_minutes >= 0),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tasks_user_isolation" ON public.tasks;
CREATE POLICY "tasks_user_isolation" ON public.tasks
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id AND
        (project_id IS NULL OR EXISTS (
            SELECT 1 FROM public.projects p
            WHERE p.id = tasks.project_id AND p.user_id = auth.uid()
        ))
    );

CREATE INDEX IF NOT EXISTS idx_tasks_user_status ON public.tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_user_due_date ON public.tasks(user_id, due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON public.tasks(project_id);

-- 5. ACTIVITY LOGS (Flexible logging across multiple domains)
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- 'work', 'personal_project', 'learning', 'workout', 'habit', 'admin', 'creative', 'rest', 'custom'
    tags TEXT[] DEFAULT '{}',
    date DATE NOT NULL,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes >= 0),
    timezone TEXT NOT NULL DEFAULT 'UTC',
    notes TEXT,
    source TEXT NOT NULL DEFAULT 'manual', -- 'manual', 'assistant', 'health_connect', 'timer'
    idempotency_key TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "activity_logs_user_isolation" ON public.activity_logs;
CREATE POLICY "activity_logs_user_isolation" ON public.activity_logs
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id AND
        (project_id IS NULL OR EXISTS (
            SELECT 1 FROM public.projects p
            WHERE p.id = activity_logs.project_id AND p.user_id = auth.uid()
        )) AND
        (task_id IS NULL OR EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = activity_logs.task_id AND t.user_id = auth.uid()
        ))
    );

CREATE INDEX IF NOT EXISTS idx_activity_logs_user_date ON public.activity_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_category ON public.activity_logs(user_id, category);

-- 6. HABITS & HABIT CHECKINS
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    frequency_target_days_per_week INTEGER NOT NULL DEFAULT 7 CHECK (frequency_target_days_per_week BETWEEN 1 AND 7),
    target_schedule TEXT NOT NULL DEFAULT 'daily', -- 'daily', 'weekdays', 'weekends'
    category TEXT NOT NULL DEFAULT 'routine',
    is_archived BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "habits_user_isolation" ON public.habits;
CREATE POLICY "habits_user_isolation" ON public.habits
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.habit_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    checkin_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(habit_id, checkin_date)
);

ALTER TABLE public.habit_checkins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "habit_checkins_user_isolation" ON public.habit_checkins;
CREATE POLICY "habit_checkins_user_isolation" ON public.habit_checkins
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id AND EXISTS (
            SELECT 1 FROM public.habits h
            WHERE h.id = habit_checkins.habit_id AND h.user_id = auth.uid()
        )
    );

CREATE INDEX IF NOT EXISTS idx_habit_checkins_lookup ON public.habit_checkins(user_id, checkin_date);

-- 7. LEARNING SESSIONS
CREATE TABLE IF NOT EXISTS public.learning_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    topic TEXT NOT NULL,
    resources TEXT,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes >= 0),
    session_date DATE NOT NULL,
    notes TEXT,
    goal TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.learning_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "learning_sessions_user_isolation" ON public.learning_sessions;
CREATE POLICY "learning_sessions_user_isolation" ON public.learning_sessions
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id AND
        (project_id IS NULL OR EXISTS (
            SELECT 1 FROM public.projects p
            WHERE p.id = learning_sessions.project_id AND p.user_id = auth.uid()
        ))
    );

CREATE INDEX IF NOT EXISTS idx_learning_sessions_user_date ON public.learning_sessions(user_id, session_date);

-- 8. HEALTH SUMMARIES (Strict Owner-Only Privacy — never shared)
CREATE TABLE IF NOT EXISTS public.health_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    step_count INTEGER NOT NULL DEFAULT 0 CHECK (step_count >= 0),
    workout_count INTEGER NOT NULL DEFAULT 0 CHECK (workout_count >= 0),
    workout_duration_minutes INTEGER NOT NULL DEFAULT 0 CHECK (workout_duration_minutes >= 0),
    source TEXT NOT NULL DEFAULT 'Health Connect',
    source_record_ids TEXT[] DEFAULT '{}',
    last_synced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, date, source)
);

ALTER TABLE public.health_summaries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "health_summaries_owner_only" ON public.health_summaries;
CREATE POLICY "health_summaries_owner_only" ON public.health_summaries
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_health_summaries_user_date ON public.health_summaries(user_id, date);

-- 9. INTEGRATION CONNECTIONS & STATUS
CREATE TABLE IF NOT EXISTS public.integration_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL, -- 'health_connect', 'samsung_health'
    is_connected BOOLEAN NOT NULL DEFAULT false,
    permissions_granted TEXT[] DEFAULT '{}',
    last_sync_at TIMESTAMPTZ,
    error_message TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, provider)
);

ALTER TABLE public.integration_connections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "integration_connections_owner_only" ON public.integration_connections;
CREATE POLICY "integration_connections_owner_only" ON public.integration_connections
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 10. ASSISTANT AUDIT & IDEMPOTENCY
CREATE TABLE IF NOT EXISTS public.assistant_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    prompt_preview TEXT NOT NULL,
    parsed_action JSONB NOT NULL,
    execution_status TEXT NOT NULL, -- 'previewed', 'confirmed', 'executed', 'cancelled', 'failed'
    idempotency_key TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.assistant_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "assistant_audit_logs_owner_only" ON public.assistant_audit_logs;
CREATE POLICY "assistant_audit_logs_owner_only" ON public.assistant_audit_logs
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Profile auto-creation on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, timezone)
    VALUES (new.id, COALESCE(new.raw_user_meta_data->>'full_name', 'Plano User'), 'UTC')
    ON CONFLICT (id) DO NOTHING;
    
    INSERT INTO public.workspaces (name, owner_id, is_personal)
    VALUES ('Personal Workspace', new.id, true)
    ON CONFLICT DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- The trigger runs through Supabase Auth. Do not expose its definer rights as
-- an RPC callable by API roles.
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;
