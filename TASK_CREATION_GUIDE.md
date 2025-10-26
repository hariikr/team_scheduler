# Task Creation Flow - Implementation Guide

## Overview
This document describes the complete task creation flow implementation with an intelligent slot-finding algorithm that automatically finds available time slots when all selected collaborators are free.

## Features Implemented

### 1. Task Creation Flow (4 Steps)

#### Step 1: Task Details
- Enter task title (required)
- Enter task description (optional)
- Clean UI with Material Design 3 components

#### Step 2: Choose Collaborators
- List of all users in the organization
- Checkbox selection interface
- Current user is auto-selected and cannot be deselected
- Shows user name, email, and avatar

#### Step 3: Choose Duration
- Four predefined duration options:
  - 10 minutes (Quick sync)
  - 15 minutes (Short meeting)
  - 30 minutes (Standard meeting) - default
  - 60 minutes (Long session)
- Radio button selection with descriptions

#### Step 4: Choose Available Slot
- Shows calculated time slots where ALL selected collaborators are available
- Considers existing tasks (busy times) and excludes overlaps
- Displays slots with date and time in an easy-to-read format
- Select one slot to confirm the task

### 2. Slot Finder Algorithm

The intelligent slot-finding algorithm is implemented in `TaskService.findAvailableSlots()` with the following logic:

#### Algorithm Steps:

1. **Fetch Availability**: Gets all availability slots for selected users from the database
2. **Fetch Existing Tasks**: Retrieves scheduled tasks for all users to identify busy times
3. **Find Common Slots**: 
   - Starts with the first user's availability
   - Finds intersections with each other user's availability
   - Only slots where ALL users overlap are considered
4. **Split into Chunks**: Divides common slots into the requested duration (e.g., 30-minute chunks)
5. **Exclude Busy Times**: Removes time slots that conflict with existing scheduled tasks
6. **Return Sorted Results**: Returns available slots sorted by start time

#### Key Algorithm Features:
- ✅ Handles multiple users efficiently
- ✅ Considers time zone (uses timestamptz)
- ✅ Excludes existing task conflicts
- ✅ Splits long availability windows into appropriate durations
- ✅ Adds 5-minute buffer between consecutive slots
- ✅ Searches next 7 days by default (configurable)

### 3. Data Models

#### TaskModel
```dart
- id: String (bigint from DB)
- title: String
- description: String? (optional)
- createdBy: String (user ID)
- startTime: DateTime? (when scheduled)
- endTime: DateTime? (when scheduled)
- createdAt: DateTime
```

#### TaskCollaboratorModel
```dart
- id: String
- taskId: String
- userId: String
- createdAt: DateTime
```

#### TimeSlotModel
```dart
- startTime: DateTime
- endTime: DateTime
- duration: Duration (computed)
- durationInMinutes: int (computed)
```

### 4. Database Schema

The implementation expects these Supabase tables:

#### tasks
```sql
CREATE TABLE public.tasks (
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
```

#### task_collaborators
```sql
CREATE TABLE public.task_collaborators (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    task_id bigint NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(task_id, user_id)
);
```

### 5. User Interface Components

#### Task List Screen
- Displays all tasks in the organization
- Shows scheduled vs. unscheduled tasks with different indicators
- Card-based layout with task details
- Delete functionality (only for task creator)
- Refresh button
- Navigate to "Create Task" screen

#### Create Task Screen
- Multi-step form with progress indicator
- Step navigation (Back/Next buttons)
- Validation at each step
- Loading states for async operations
- Error handling with snackbar notifications
- Auto-loads users and calculates slots as needed

#### Availability Screen Updates
- Added "View Tasks" button
- Navigates to Task List screen
- Maintains existing availability management functionality

### 6. State Management (BLoC/Cubit)

#### TaskCubit
Manages all task-related operations:
- `loadTasks()` - Fetch all tasks
- `loadTaskDetail(taskId)` - Get task with collaborators
- `loadUsers()` - Fetch all users for selection
- `findAvailableSlots()` - Run slot finder algorithm
- `createTask()` - Create new task with collaborators
- `updateTask()` - Update existing task
- `deleteTask()` - Remove task

#### TaskState
Multiple states for different operations:
- `TaskInitial` - Initial state
- `TaskLoading` - Loading indicator
- `TaskListLoaded` - Tasks fetched
- `UsersLoaded` - Users for selection
- `AvailableSlotsLoaded` - Calculated slots
- `TaskCreated` - Success state
- `TaskError` - Error with message

### 7. Navigation Flow

```
AvailabilityScreen
    ↓ (View Tasks button)
TaskListScreen
    ↓ (Create Task button)
CreateTaskScreen (Step 1: Task Info)
    ↓ (Next)
CreateTaskScreen (Step 2: Collaborators)
    ↓ (Next, loads available slots)
CreateTaskScreen (Step 3: Duration)
    ↓ (Next)
CreateTaskScreen (Step 4: Select Slot)
    ↓ (Create Task)
TaskListScreen (with new task)
```

## Files Created/Modified

### New Files Created:
1. `lib/data/models/task_model.dart`
2. `lib/data/models/task_collaborator_model.dart`
3. `lib/data/models/time_slot_model.dart`
4. `lib/data/services/task_service.dart`
5. `lib/logic/task/task_cubit.dart`
6. `lib/logic/task/task_state.dart`
7. `lib/presentation/task/task_list_screen.dart`
8. `lib/presentation/task/create_task_screen.dart`

### Modified Files:
1. `lib/presentation/availability/availability_screen.dart` - Added navigation to tasks
2. `test/widget_test.dart` - Updated test

## Usage Instructions

### For Users:

1. **Set Your Availability First**
   - Go to Availability screen
   - Add your available time slots
   - These will be used for finding common meeting times

2. **View Tasks**
   - Click "View Tasks" button from Availability screen
   - See all tasks (scheduled and unscheduled)

3. **Create a New Task**
   - Click "Create Task" button
   - **Step 1**: Enter title and description
   - **Step 2**: Select team members (collaborators)
   - **Step 3**: Choose how long the task will take
   - **Step 4**: Pick from available time slots (automatically calculated)
   - Click "Create Task" to finalize

4. **Manage Tasks**
   - View task details by tapping on a task card
   - Delete tasks you created using the menu button
   - Refresh the list anytime

### For Developers:

#### To Test Locally:
1. Ensure Supabase is properly configured
2. Create the required database tables (tasks, task_collaborators)
3. Add some test users with availability slots
4. Run the app and test the flow

#### To Extend:
- Add task editing functionality in `TaskService`
- Implement task filtering/search in `TaskListScreen`
- Add notifications when tasks are assigned
- Implement recurring task support
- Add calendar view for tasks

## Algorithm Example

**Scenario**: Find 30-minute slot for User A, User B, and User C

**User A Availability**: Mon 9:00-12:00, Mon 14:00-17:00
**User B Availability**: Mon 10:00-15:00
**User C Availability**: Mon 11:00-16:00

**Existing Tasks**:
- User A has meeting Mon 14:00-14:30

**Algorithm Process**:
1. Find common slots:
   - Mon 10:00-12:00 (A, B intersect)
   - Mon 11:00-12:00 (A, B, C all intersect) ✓
   - Mon 14:00-15:00 (A, B, C all intersect) ✓

2. Split into 30-min chunks:
   - Mon 11:00-11:30 ✓
   - Mon 11:35-12:05 ✗ (extends beyond 12:00)
   - Mon 14:00-14:30 ✗ (User A has existing task)
   - Mon 14:30-15:00 ✓

**Available Slots Returned**:
- Mon 11:00-11:30
- Mon 14:30-15:00

## Design Decisions

1. **Progressive Disclosure**: Multi-step form prevents overwhelming users
2. **Auto-calculation**: Slots calculated automatically after selecting collaborators
3. **Visual Feedback**: Progress indicator shows current step
4. **Smart Defaults**: Current user auto-selected, 30min default duration
5. **Error Handling**: Graceful error messages with recovery options
6. **No Manual Time Entry**: Users select from suggested slots (prevents conflicts)
7. **Optimistic Validation**: Each step validated before proceeding

## Performance Considerations

- Slot calculation may take time with many users/long date ranges
- Consider caching frequently accessed data
- Database queries use proper indexes on user_id, start_time, end_time
- Pagination could be added for large task lists

## Security Notes

- Tasks use RLS (Row Level Security) in Supabase
- Only task creator can delete tasks
- All users can view all tasks (organization-wide visibility)
- Consider adding role-based permissions for future enhancements

## Future Enhancements

- [ ] Task editing (change time, collaborators, etc.)
- [ ] Task categories/labels
- [ ] Calendar view integration
- [ ] Email/push notifications
- [ ] Recurring tasks
- [ ] Task comments/notes
- [ ] File attachments
- [ ] Task status workflow (pending, in-progress, completed)
- [ ] Advanced filters (by date, collaborator, status)
- [ ] Export to calendar (iCal format)

## Troubleshooting

**No slots found?**
- Ensure all selected users have availability set
- Check if date range is appropriate (default: next 7 days)
- Verify users don't have conflicting existing tasks

**Database errors?**
- Verify Supabase connection
- Check table schemas match expected structure
- Ensure RLS policies allow read/write operations

**UI not updating?**
- Check BLoC state emissions
- Verify listeners are properly set up
- Look for console errors

---

**Implementation Status**: ✅ Complete and Ready for Testing

**Last Updated**: October 27, 2025
