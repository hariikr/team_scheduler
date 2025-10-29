import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../logic/task/task_cubit.dart';
import '../../logic/task/task_state.dart';

class CreateTaskScreen extends StatefulWidget {
  final String userId;

  const CreateTaskScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  int _currentStep = 0;

  // Step 1: Task Info
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Step 2: Collaborators
  List<UserModel> _allUsers = [];
  Set<String> _selectedCollaboratorIds = {};

  // Step 3: Duration
  int _selectedDurationMinutes = 30;
  final List<int> _durationOptions = [10, 15, 30, 60];

  // Step 4: Time Slot
  List<TimeSlotModel> _availableSlots = [];
  TimeSlotModel? _selectedSlot;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskCubit(Supabase.instance.client),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Task'),
          centerTitle: true,
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
            } else if (state is UsersLoaded) {
              setState(() {
                _allUsers = state.users;
                // Auto-select current user
                _selectedCollaboratorIds.add(widget.userId);
              });
            } else if (state is AvailableSlotsLoaded) {
              setState(() {
                _availableSlots = state.slots;
                _selectedSlot = null;
              });
              if (_availableSlots.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'No available slots found for the selected collaborators'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } else if (state is TaskCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task created successfully!')),
              );
              Navigator.pop(context, true);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildStepContent(context, state),
                  ),
                ),
                // Navigation Buttons
                _buildNavigationButtons(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, TaskState state) {
    switch (_currentStep) {
      case 0:
        return _buildStep1TaskInfo();
      case 1:
        return _buildStep2Collaborators(state);
      case 2:
        return _buildStep3Duration();
      case 3:
        return _buildStep4TimeSlot(state);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1TaskInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Task Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          onChanged: (value) {
            // Trigger rebuild when text changes
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: 'Task Title *',
            hintText: 'Enter task title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.title),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Enter task description (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildStep2Collaborators(TaskState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Choose Collaborators',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select team members for this task',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        if (state is TaskLoading)
          const Center(child: CircularProgressIndicator())
        else if (_allUsers.isEmpty)
          Center(
            child: Column(
              children: [
                const Text('No users available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TaskCubit>().loadUsers();
                  },
                  child: const Text('Load Users'),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allUsers.length,
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              final isSelected = _selectedCollaboratorIds.contains(user.id);
              final isCurrentUser = user.id == widget.userId;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: isCurrentUser
                      ? null // Can't deselect current user
                      : (value) {
                          setState(() {
                            if (value == true) {
                              _selectedCollaboratorIds.add(user.id);
                            } else {
                              _selectedCollaboratorIds.remove(user.id);
                            }
                          });
                        },
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight:
                          isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    isCurrentUser ? '${user.email} (You)' : user.email,
                  ),
                  secondary: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3Duration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Choose Duration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How long will this task take?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ..._durationOptions.map((duration) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: RadioListTile<int>(
              value: duration,
              groupValue: _selectedDurationMinutes,
              onChanged: (value) {
                setState(() {
                  _selectedDurationMinutes = value!;
                  // Clear previously selected slot when duration changes
                  _selectedSlot = null;
                });
              },
              title: Text(
                '$duration minutes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(_getDurationDescription(duration)),
              secondary: Icon(
                Icons.timer,
                color: _selectedDurationMinutes == duration
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getDurationDescription(int minutes) {
    switch (minutes) {
      case 10:
        return 'Quick sync';
      case 15:
        return 'Short meeting';
      case 30:
        return 'Standard meeting';
      case 60:
        return 'Long session';
      default:
        return '';
    }
  }

  Widget _buildStep4TimeSlot(TaskState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Choose Available Slot',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a time when everyone is available',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        if (state is TaskLoading)
          const Center(child: CircularProgressIndicator())
        else if (_availableSlots.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No available slots found',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting different collaborators or check availability',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final slot = _availableSlots[index];
              final isSelected = _selectedSlot == slot;
              final timeFormat = DateFormat('h:mm a');
              final dateFormat = DateFormat('EEE, MMM dd');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedSlot = slot;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(slot.startTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.event_available,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, TaskState state) {
    final bool isLastStep = _currentStep == 3;
    final bool canProceed = _canProceedToNextStep();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: state is TaskLoading
                    ? null
                    : () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (state is TaskLoading || !canProceed)
                  ? null
                  : () {
                      if (isLastStep) {
                        _createTask(context);
                      } else {
                        _goToNextStep(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state is TaskLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isLastStep ? 'Create Task' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.trim().isNotEmpty;
      case 1:
        return _selectedCollaboratorIds.isNotEmpty;
      case 2:
        return true; // Duration is always selected
      case 3:
        return _selectedSlot != null;
      default:
        return false;
    }
  }

  void _goToNextStep(BuildContext context) {
    if (_currentStep == 1) {
      // After selecting collaborators, load available slots
      context.read<TaskCubit>().findAvailableSlots(
            userIds: _selectedCollaboratorIds.toList(),
            durationMinutes: _selectedDurationMinutes,
          );
    } else if (_currentStep == 2) {
      // After selecting duration, recalculate available slots
      context.read<TaskCubit>().findAvailableSlots(
            userIds: _selectedCollaboratorIds.toList(),
            durationMinutes: _selectedDurationMinutes,
          );
    } else if (_currentStep == 0) {
      // After task info, load users
      if (_allUsers.isEmpty) {
        context.read<TaskCubit>().loadUsers();
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  void _createTask(BuildContext context) {
    if (_selectedSlot == null) return;

    context.read<TaskCubit>().createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          createdBy: widget.userId,
          collaboratorIds: _selectedCollaboratorIds.toList(),
          startTime: _selectedSlot!.startTime,
          endTime: _selectedSlot!.endTime,
        );
  }
}
