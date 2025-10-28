import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart' as app_auth;
import '../../logic/availability/availability_cubit.dart';
import '../../logic/availability/availability_state.dart';
import '../../logic/user/user_cubit.dart';
import '../../logic/user/user_state.dart';
import '../../data/models/availability_model.dart';
import '../auth/login_screen.dart';
import '../task/task_list_screen.dart';

class AvailabilityScreen extends StatelessWidget {
  final String userId;

  const AvailabilityScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AvailabilityCubit(
            Supabase.instance.client,
            userId,
          )..loadAvailability(),
        ),
        BlocProvider(
          create: (context) => AuthCubit(AuthService(Supabase.instance.client)),
        ),
        BlocProvider(
          create: (context) =>
              UserCubit(Supabase.instance.client)..fetchUser(userId),
        ),
      ],
      child: const AvailabilityView(),
    );
  }
}

class AvailabilityView extends StatelessWidget {
  const AvailabilityView({super.key});

  void _navigateToTaskList(BuildContext context) {
    // Capture userId before navigation to avoid context issues
    final userId = context.read<AvailabilityCubit>().userId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(userId: userId),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().signOut();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddSlotDialog(
        onAdd: (startTime, endTime) {
          context.read<AvailabilityCubit>().addSlot(
                startTime: startTime,
                endTime: endTime,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AvailabilityCubit, AvailabilityState>(
          listener: (context, state) {
            if (state is AvailabilityError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is AvailabilityOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<AuthCubit, app_auth.AuthState>(
          listener: (context, state) {
            if (state is app_auth.AuthUnauthenticated) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } else if (state is app_auth.AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Availability'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: BlocBuilder<AvailabilityCubit, AvailabilityState>(
          builder: (context, state) {
            if (state is AvailabilityLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            List<AvailabilityModel> slots = [];
            if (state is AvailabilityLoaded) {
              slots = state.slots;
            } else if (state is AvailabilityOperationSuccess) {
              slots = state.slots;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Header with User Info
                BlocBuilder<UserCubit, UserState>(
                  builder: (context, userState) {
                    if (userState is UserSuccess) {
                      return Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.7),
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
                            // Profile Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: userState.photoUrl != null
                                    ? Image.network(
                                        userState.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.white,
                                            child: Icon(
                                              Icons.person,
                                              size: 35,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          size: 35,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Welcome Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userState.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (userState is UserLoading) {
                      return Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: const Row(
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 16),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Availability List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: slots.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No availability slots yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add your first slot below',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: slots.length,
                                  itemBuilder: (context, index) {
                                    final slot = slots[index];
                                    return AvailabilitySlotCard(
                                      slot: slot,
                                      slotNumber: index + 1,
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddSlotDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Slot'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _navigateToTaskList(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('View Tasks'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AvailabilitySlotCard extends StatelessWidget {
  final AvailabilityModel slot;
  final int slotNumber;

  const AvailabilitySlotCard({
    super.key,
    required this.slot,
    required this.slotNumber,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$slotNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(slot.startTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showDeleteConfirmation(context),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Slot'),
        content: const Text(
            'Are you sure you want to delete this availability slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AvailabilityCubit>().deleteSlot(slot.id);
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
}

class AddSlotDialog extends StatefulWidget {
  final Function(DateTime startTime, DateTime endTime) onAdd;

  const AddSlotDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddSlotDialog> createState() => _AddSlotDialogState();
}

class _AddSlotDialogState extends State<AddSlotDialog> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Availability Slot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Start Time'),
              subtitle: Text(startTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: startTime,
                );
                if (time != null) {
                  setState(() => startTime = time);
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('End Time'),
              subtitle: Text(endTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: endTime,
                );
                if (time != null) {
                  setState(() => endTime = time);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final start = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              startTime.hour,
              startTime.minute,
            );
            final end = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              endTime.hour,
              endTime.minute,
            );

            if (start.isAfter(end) || start.isAtSameMomentAs(end)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Start time must be before end time'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            widget.onAdd(start, end);
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
