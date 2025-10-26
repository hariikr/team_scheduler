-- ================================================
-- Team Scheduler - Task Management Rollback
-- ================================================
-- Description: Rollback script for task management migration
-- Version: 1.0
-- Date: 2025-10-27
-- WARNING: This will delete all task-related data!
-- ================================================

-- ================================================
-- 1. DROP RLS POLICIES
-- ================================================

-- Drop policies for task_collaborators table
DROP POLICY IF EXISTS "Authenticated users can remove collaborators" ON public.task_collaborators;
DROP POLICY IF EXISTS "Authenticated users can add collaborators" ON public.task_collaborators;
DROP POLICY IF EXISTS "Anyone can view task collaborators" ON public.task_collaborators;

-- Drop policies for tasks table
DROP POLICY IF EXISTS "Task creator can delete task" ON public.tasks;
DROP POLICY IF EXISTS "Task creator can update task" ON public.tasks;
DROP POLICY IF EXISTS "Authenticated users can create tasks" ON public.tasks;
DROP POLICY IF EXISTS "Anyone can view tasks" ON public.tasks;

-- ================================================
-- 2. DROP INDEXES
-- ================================================

-- Drop indexes for task_collaborators table
DROP INDEX IF EXISTS public.idx_task_collaborators_user_task;
DROP INDEX IF EXISTS public.idx_task_collaborators_user_id;
DROP INDEX IF EXISTS public.idx_task_collaborators_task_id;

-- Drop indexes for tasks table
DROP INDEX IF EXISTS public.idx_tasks_created_at;
DROP INDEX IF EXISTS public.idx_tasks_end_time;
DROP INDEX IF EXISTS public.idx_tasks_start_time;
DROP INDEX IF EXISTS public.idx_tasks_created_by;

-- ================================================
-- 3. DROP TABLES (CASCADE will drop foreign keys)
-- ================================================

-- Drop task_collaborators table first (child table)
DROP TABLE IF EXISTS public.task_collaborators CASCADE;

-- Drop tasks table (parent table)
DROP TABLE IF EXISTS public.tasks CASCADE;

-- ================================================
-- 4. DROP SEQUENCES (if they still exist)
-- ================================================

DROP SEQUENCE IF EXISTS public.task_collaborators_id_seq CASCADE;
DROP SEQUENCE IF EXISTS public.tasks_id_seq CASCADE;

-- ================================================
-- ROLLBACK COMPLETE
-- ================================================
-- All task-related tables, indexes, policies, and sequences have been removed.
-- ================================================
