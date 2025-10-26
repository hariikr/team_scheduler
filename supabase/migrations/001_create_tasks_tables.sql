-- ================================================
-- Team Scheduler - Task Management Migration
-- ================================================
-- Description: Creates tables for task management with slot finder
-- Version: 1.0
-- Date: 2025-10-27
-- ================================================

-- ================================================
-- 1. CREATE TASKS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS public.tasks (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    description text,
    created_by uuid NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
    start_time timestamptz,
    end_time timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_task_range CHECK (
        (start_time IS NULL AND end_time IS NULL) OR
        (start_time < end_time)
    )
);

-- Add table comment
COMMENT ON TABLE public.tasks IS 'Stores all tasks in the system';

-- Add column comments
COMMENT ON COLUMN public.tasks.id IS 'Primary key - auto-generated';
COMMENT ON COLUMN public.tasks.title IS 'The title/name of the task';
COMMENT ON COLUMN public.tasks.description IS 'Optional detailed description of the task';
COMMENT ON COLUMN public.tasks.created_by IS 'User ID of the person who created the task';
COMMENT ON COLUMN public.tasks.start_time IS 'Scheduled start time (null if not scheduled yet)';
COMMENT ON COLUMN public.tasks.end_time IS 'Scheduled end time (null if not scheduled yet)';
COMMENT ON COLUMN public.tasks.created_at IS 'Timestamp when task was created';

-- ================================================
-- 2. CREATE TASK COLLABORATORS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS public.task_collaborators (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    task_id bigint NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT unique_task_collaborator UNIQUE(task_id, user_id)
);

-- Add table comment
COMMENT ON TABLE public.task_collaborators IS 'Links tasks with their collaborators (many-to-many relationship)';

-- Add column comments
COMMENT ON COLUMN public.task_collaborators.id IS 'Primary key - auto-generated';
COMMENT ON COLUMN public.task_collaborators.task_id IS 'Reference to the task';
COMMENT ON COLUMN public.task_collaborators.user_id IS 'Reference to the collaborating user';
COMMENT ON COLUMN public.task_collaborators.created_at IS 'Timestamp when collaborator was added';

-- ================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ================================================

-- Indexes for tasks table
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON public.tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_start_time ON public.tasks(start_time);
CREATE INDEX IF NOT EXISTS idx_tasks_end_time ON public.tasks(end_time);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON public.tasks(created_at DESC);

-- Indexes for task_collaborators table
CREATE INDEX IF NOT EXISTS idx_task_collaborators_task_id ON public.task_collaborators(task_id);
CREATE INDEX IF NOT EXISTS idx_task_collaborators_user_id ON public.task_collaborators(user_id);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_task_collaborators_user_task ON public.task_collaborators(user_id, task_id);

-- ================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- ================================================

-- Enable RLS on tasks table
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Enable RLS on task_collaborators table
ALTER TABLE public.task_collaborators ENABLE ROW LEVEL SECURITY;

-- ================================================
-- 5. CREATE RLS POLICIES FOR TASKS TABLE
-- ================================================

-- Policy: Anyone can view all tasks (organization-wide visibility)
CREATE POLICY "Anyone can view tasks"
    ON public.tasks
    FOR SELECT
    USING (true);

-- Policy: Authenticated users can create tasks
CREATE POLICY "Authenticated users can create tasks"
    ON public.tasks
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy: Task creator can update their tasks
CREATE POLICY "Task creator can update task"
    ON public.tasks
    FOR UPDATE
    USING (auth.uid() = created_by)
    WITH CHECK (auth.uid() = created_by);

-- Policy: Task creator can delete their tasks
CREATE POLICY "Task creator can delete task"
    ON public.tasks
    FOR DELETE
    USING (auth.uid() = created_by);

-- ================================================
-- 6. CREATE RLS POLICIES FOR TASK_COLLABORATORS TABLE
-- ================================================

-- Policy: Anyone can view task collaborators
CREATE POLICY "Anyone can view task collaborators"
    ON public.task_collaborators
    FOR SELECT
    USING (true);

-- Policy: Authenticated users can add collaborators
CREATE POLICY "Authenticated users can add collaborators"
    ON public.task_collaborators
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy: Authenticated users can remove collaborators
CREATE POLICY "Authenticated users can remove collaborators"
    ON public.task_collaborators
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- ================================================
-- 7. GRANT PERMISSIONS
-- ================================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tasks TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.task_collaborators TO authenticated;

-- Grant usage on sequences
GRANT USAGE ON SEQUENCE public.tasks_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE public.task_collaborators_id_seq TO authenticated;

-- ================================================
-- 8. VERIFICATION QUERIES (Optional - Run separately to test)
-- ================================================

-- Uncomment these queries to verify the setup after migration

-- Check if tasks table exists
-- SELECT EXISTS (
--     SELECT FROM information_schema.tables 
--     WHERE table_schema = 'public' 
--     AND table_name = 'tasks'
-- );

-- Check if task_collaborators table exists
-- SELECT EXISTS (
--     SELECT FROM information_schema.tables 
--     WHERE table_schema = 'public' 
--     AND table_name = 'task_collaborators'
-- );

-- List all indexes on tasks table
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'tasks' 
-- AND schemaname = 'public';

-- List all RLS policies on tasks table
-- SELECT policyname, cmd, qual 
-- FROM pg_policies 
-- WHERE tablename = 'tasks' 
-- AND schemaname = 'public';

-- ================================================
-- MIGRATION COMPLETE
-- ================================================
-- Tables created: tasks, task_collaborators
-- Indexes created: 7 indexes for optimal query performance
-- RLS enabled: Yes
-- Policies created: 7 policies for secure access
-- ================================================
