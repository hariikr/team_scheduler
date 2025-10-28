import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/task_model.dart';
import '../../logic/task/task_cubit.dart';
import '../../logic/task/task_state.dart';
import 'create_task_screen.dart';

enum TaskFilter { all, created, mine }

class TaskListScreen extends StatelessWidget {
  final String userId;

  const TaskListScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskCubit(Supabase.instance.client)..loadTasks(),
      child: TaskListView(userId: userId),
    );
  }
}

class TaskListView extends StatefulWidget {
  final String userId;

  const TaskListView({
    super.key,
    required this.userId,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  TaskFilter _selectedFilter = TaskFilter.all;

  void _applyFilter(TaskFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });

    final cubit = context.read<TaskCubit>();
    switch (filter) {
      case TaskFilter.all:
        cubit.loadTasks();
        break;
      case TaskFilter.created:
        cubit.loadTasksCreatedBy(widget.userId);
        break;
      case TaskFilter.mine:
        cubit.loadTasksForCollaborator(widget.userId);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<TaskCubit, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TaskDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task deleted successfully')),
            );
            context.read<TaskCubit>().loadTasks();
          } else if (state is TaskCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task created successfully')),
            );
            context.read<TaskCubit>().loadTasks();
          }
        },
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<TaskModel> tasks = [];
          if (state is TaskListLoaded) {
            tasks = state.tasks;
          }

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.task_alt,
                        size: 28,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Tasks',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Filters
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              context,
                              label: 'All',
                              filter: TaskFilter.all,
                              icon: Icons.list_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              label: 'Created',
                              filter: TaskFilter.created,
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              label: 'Mine',
                              filter: TaskFilter.mine,
                              icon: Icons.group_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Task List
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task_alt,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No tasks found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first task to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CreateTaskScreen(userId: widget.userId),
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  _applyFilter(_selectedFilter);
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Task'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(task: task, userId: widget.userId);
                        },
                      ),
              ),
              // Bottom Actions
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateTaskScreen(userId: widget.userId),
                              ),
                            );
                            if (result == true && context.mounted) {
                              _applyFilter(_selectedFilter);
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Add Task'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.schedule_rounded, size: 20),
                          label: const Text('Slots'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required TaskFilter filter,
    required IconData icon,
  }) {
    final bool isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _applyFilter(filter);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        width: isSelected ? 1.5 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final String userId;

  const TaskCard({
    super.key,
    required this.task,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM dd, yyyy');
    final bool isScheduled = task.startTime != null && task.endTime != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showTaskDetails(context);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isScheduled ? Colors.green : Colors.orange)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isScheduled
                          ? Icons.event_available_rounded
                          : Icons.event_busy_rounded,
                      color: isScheduled ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Collaborator avatars
                  if (task.collaborators != null &&
                      task.collaborators!.isNotEmpty)
                    _buildCollaboratorAvatars(),
                  const SizedBox(width: 8),
                  if (task.createdBy == userId)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Duration
              if (isScheduled) ...[
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Duration: ${task.durationInMinutes} min',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              // Collaborators
              if (task.collaborators != null &&
                  task.collaborators!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.group_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Collaborators: ${task.collaborators!.map((u) => u.name).join(", ")}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (isScheduled) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.15),
                        Colors.green.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            size: 18, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${timeFormat.format(task.startTime!)} - ${timeFormat.format(task.endTime!)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(task.startTime!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.green.withOpacity(0.5)),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.15),
                        Colors.orange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Not scheduled yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.orange.withOpacity(0.5)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty) ...[
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(task.description!),
                const SizedBox(height: 16),
              ],
              if (task.startTime != null && task.endTime != null) ...[
                const Text(
                  'Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM dd, yyyy h:mm a').format(task.startTime!)} - ${DateFormat('h:mm a').format(task.endTime!)}',
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Created',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(DateFormat('MMM dd, yyyy').format(task.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TaskCubit>().deleteTask(task.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorAvatars() {
    if (task.collaborators == null || task.collaborators!.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCount =
        task.collaborators!.length > 3 ? 3 : task.collaborators!.length;
    final remaining = task.collaborators!.length - displayCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show up to 3 avatars
        ...List.generate(displayCount, (index) {
          final collaborator = task.collaborators![index];
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
            child: _buildAvatar(collaborator.photoUrl, collaborator.name),
          );
        }),
        // Show "+X" if there are more collaborators
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.grey[200],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar(name);
                },
              )
            : _buildInitialsAvatar(name),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = _getInitials(name);
    final color = _getColorFromName(name);

    return Container(
      color: color,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _getColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
