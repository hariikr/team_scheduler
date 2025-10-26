# Supabase Migrations

This directory contains SQL migration files for the Team Scheduler database.

## Files

### `001_create_tasks_tables.sql`
Main migration file that creates:
- `tasks` table - Stores task information
- `task_collaborators` table - Links tasks with users
- Indexes for performance optimization
- Row Level Security (RLS) policies
- Proper permissions

### `001_rollback_tasks_tables.sql`
Rollback file to undo the migration (⚠️ **WARNING: Destructive operation**)

## How to Apply Migration

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New query**
4. Copy the entire contents of `001_create_tasks_tables.sql`
5. Paste into the SQL editor
6. Click **Run** or press `Ctrl+Enter`
7. Verify success by checking the **Table Editor**

### Option 2: Using Supabase CLI

```bash
# Make sure you're in the project root directory
cd "c:\Users\harik\Desktop\Flutter Project\team_scheduler"

# Login to Supabase (if not already logged in)
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Apply the migration
supabase db push
```

### Option 3: Direct SQL Execution

```bash
# Using psql (if you have direct database access)
psql "postgresql://[CONNECTION_STRING]" < supabase/migrations/001_create_tasks_tables.sql
```

## Verification

After running the migration, verify the setup:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('tasks', 'task_collaborators');

-- Expected output: Both tables should be listed

-- Check indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('tasks', 'task_collaborators')
ORDER BY tablename, indexname;

-- Check RLS policies
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('tasks', 'task_collaborators')
ORDER BY tablename, policyname;
```

## What Gets Created

### Tables
1. **tasks**
   - `id` (bigint, auto-increment)
   - `title` (text, required)
   - `description` (text, optional)
   - `created_by` (uuid, references users)
   - `start_time` (timestamptz, nullable)
   - `end_time` (timestamptz, nullable)
   - `created_at` (timestamptz, default now())

2. **task_collaborators**
   - `id` (bigint, auto-increment)
   - `task_id` (bigint, references tasks)
   - `user_id` (uuid, references users)
   - `created_at` (timestamptz, default now())
   - Unique constraint on (task_id, user_id)

### Indexes (7 total)
- `idx_tasks_created_by` - Fast lookups by creator
- `idx_tasks_start_time` - Efficient time-based queries
- `idx_tasks_end_time` - Time range queries
- `idx_tasks_created_at` - Recent tasks first
- `idx_task_collaborators_task_id` - Find collaborators by task
- `idx_task_collaborators_user_id` - Find tasks by user
- `idx_task_collaborators_user_task` - Composite for common queries

### RLS Policies (7 total)
**Tasks Table:**
- Anyone can view all tasks
- Authenticated users can create tasks
- Task creators can update their own tasks
- Task creators can delete their own tasks

**Task Collaborators Table:**
- Anyone can view collaborators
- Authenticated users can add collaborators
- Authenticated users can remove collaborators

## Rollback (⚠️ CAUTION)

If you need to undo the migration:

```sql
-- In Supabase SQL Editor, run:
-- Copy and paste contents from: 001_rollback_tasks_tables.sql
```

**WARNING**: This will permanently delete:
- All tasks
- All task collaborator relationships
- All indexes
- All RLS policies

## Prerequisites

Before running this migration, ensure:
- [ ] `users` table exists with columns: `id` (uuid), `name`, `email`
- [ ] `availability` table exists (for slot-finding algorithm)
- [ ] You have admin access to the Supabase project
- [ ] You've backed up any important data (if re-running)

## Troubleshooting

### Error: "relation 'users' does not exist"
**Solution**: Create the users table first or verify the `auth.users` setup.

### Error: "permission denied"
**Solution**: Ensure you're running the migration as a database admin or service role.

### Error: "policy already exists"
**Solution**: Run the rollback script first, then re-run the migration.

### Tables created but app shows errors
**Checklist**:
1. Verify RLS is enabled: `SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('tasks', 'task_collaborators');`
2. Check policies exist: Run verification queries above
3. Test with Supabase client in app
4. Check Supabase logs for detailed error messages

## Migration History

| Version | Date       | Description                          |
|---------|------------|--------------------------------------|
| 001     | 2025-10-27 | Create tasks and task_collaborators |

## Next Steps

After successful migration:

1. ✅ Run verification queries to confirm setup
2. ✅ Test task creation in the Flutter app
3. ✅ Verify RLS policies are working (try with different users)
4. ✅ Monitor Supabase logs for any issues
5. ✅ Consider adding sample data for testing

## Support

If you encounter issues:
- Check Supabase Dashboard → Logs
- Review RLS policies in Dashboard → Authentication → Policies
- Verify table structure in Dashboard → Table Editor
- Check this README for troubleshooting tips

---

**Last Updated**: October 27, 2025
