# Database Setup for Task Management

## Required Tables

Execute these SQL commands in your Supabase SQL Editor to set up the task management tables.

### 1. Tasks Table

```sql
-- Create tasks table
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

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON public.tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_start_time ON public.tasks(start_time);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON public.tasks(created_at DESC);

-- Add comments for documentation
COMMENT ON TABLE public.tasks IS 'Stores all tasks in the system';
COMMENT ON COLUMN public.tasks.title IS 'The title/name of the task';
COMMENT ON COLUMN public.tasks.description IS 'Optional detailed description of the task';
COMMENT ON COLUMN public.tasks.created_by IS 'User ID of the person who created the task';
COMMENT ON COLUMN public.tasks.start_time IS 'Scheduled start time (null if not scheduled)';
COMMENT ON COLUMN public.tasks.end_time IS 'Scheduled end time (null if not scheduled)';
```

### 2. Task Collaborators Table

```sql
-- Create task_collaborators junction table
CREATE TABLE IF NOT EXISTS public.task_collaborators (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    task_id bigint NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT unique_task_collaborator UNIQUE(task_id, user_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_task_collaborators_task_id ON public.task_collaborators(task_id);
CREATE INDEX IF NOT EXISTS idx_task_collaborators_user_id ON public.task_collaborators(user_id);

-- Add comments for documentation
COMMENT ON TABLE public.task_collaborators IS 'Links tasks with their collaborators (many-to-many relationship)';
COMMENT ON COLUMN public.task_collaborators.task_id IS 'Reference to the task';
COMMENT ON COLUMN public.task_collaborators.user_id IS 'Reference to the collaborating user';
```

## Row Level Security (RLS) Policies

Enable RLS and set up policies for secure access:

### Tasks Table Policies

```sql
-- Enable RLS
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

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
```

### Task Collaborators Table Policies

```sql
-- Enable RLS
ALTER TABLE public.task_collaborators ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view task collaborators
CREATE POLICY "Anyone can view task collaborators"
    ON public.task_collaborators
    FOR SELECT
    USING (true);

-- Policy: Task creator can add collaborators
-- (We'll verify this in the application layer by checking task ownership)
CREATE POLICY "Authenticated users can add collaborators"
    ON public.task_collaborators
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy: Task creator can remove collaborators
-- (Application should verify task ownership before deletion)
CREATE POLICY "Authenticated users can remove collaborators"
    ON public.task_collaborators
    FOR DELETE
    USING (auth.role() = 'authenticated');
```

## Verify Existing Tables

Before running the above scripts, verify that these tables exist:

### Users Table
```sql
-- Verify users table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'users'
);
```

### Availability Table
```sql
-- Verify availability table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'availability'
);
```

## Sample Data (Optional - For Testing)

Insert some sample tasks for testing:

```sql
-- Get a user ID first
-- SELECT id FROM public.users LIMIT 1;

-- Insert a scheduled task (replace <user_id> with actual UUID)
INSERT INTO public.tasks (title, description, created_by, start_time, end_time)
VALUES (
    'Team Standup',
    'Daily team synchronization meeting',
    '<user_id>',
    '2025-10-28 09:00:00+00',
    '2025-10-28 09:30:00+00'
);

-- Insert an unscheduled task
INSERT INTO public.tasks (title, description, created_by)
VALUES (
    'Review Project Documentation',
    'Review and update project documentation',
    '<user_id>'
);

-- Add collaborators (replace <task_id> and <user_id> with actual values)
INSERT INTO public.task_collaborators (task_id, user_id)
VALUES 
    (1, '<user_id_1>'),
    (1, '<user_id_2>');
```

## Verification Queries

After setup, verify everything is working:

```sql
-- Check tasks table
SELECT COUNT(*) FROM public.tasks;

-- Check task_collaborators table
SELECT COUNT(*) FROM public.task_collaborators;

-- View all tasks with collaborator count
SELECT 
    t.id,
    t.title,
    t.start_time,
    t.end_time,
    COUNT(tc.user_id) as collaborator_count
FROM public.tasks t
LEFT JOIN public.task_collaborators tc ON t.id = tc.task_id
GROUP BY t.id, t.title, t.start_time, t.end_time
ORDER BY t.created_at DESC;

-- View tasks with collaborator details
SELECT 
    t.id as task_id,
    t.title,
    u.name as collaborator_name,
    u.email as collaborator_email
FROM public.tasks t
JOIN public.task_collaborators tc ON t.id = tc.task_id
JOIN public.users u ON tc.user_id = u.id
ORDER BY t.id, u.name;
```

## Cleanup (If needed)

To remove all task-related data and start fresh:

```sql
-- WARNING: This will delete all tasks and collaborators!
-- DROP TABLE IF EXISTS public.task_collaborators CASCADE;
-- DROP TABLE IF EXISTS public.tasks CASCADE;
```

## Performance Optimization

For better performance with large datasets:

```sql
-- Analyze tables to update statistics
ANALYZE public.tasks;
ANALYZE public.task_collaborators;

-- Vacuum to reclaim storage
VACUUM ANALYZE public.tasks;
VACUUM ANALYZE public.task_collaborators;
```

## Backup Recommendations

Before making changes to production:

```bash
# Export tasks (using Supabase CLI or Dashboard)
# Supabase Dashboard -> Table Editor -> tasks -> Export as CSV

# Or use SQL
# COPY public.tasks TO '/path/to/tasks_backup.csv' CSV HEADER;
# COPY public.task_collaborators TO '/path/to/collaborators_backup.csv' CSV HEADER;
```

---

**Setup Status**: Ready to execute in Supabase SQL Editor

**Last Updated**: October 27, 2025

## Next Steps

1. Execute the SQL commands in Supabase SQL Editor
2. Verify tables are created: `SELECT * FROM public.tasks LIMIT 1;`
3. Test RLS policies by trying to insert/update/delete from different users
4. Run the Flutter app and test the task creation flow
5. Monitor Supabase logs for any errors

## Support

If you encounter issues:
- Check Supabase Dashboard -> Table Editor to verify table structure
- Review Supabase Dashboard -> Authentication -> Policies
- Check Supabase Dashboard -> Logs for error messages
- Verify your users table has the correct structure with `id`, `name`, and `email` columns
