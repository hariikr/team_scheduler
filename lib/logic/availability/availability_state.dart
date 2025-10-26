import 'package:equatable/equatable.dart';
import '../../data/models/availability_model.dart';

abstract class AvailabilityState extends Equatable {
  const AvailabilityState();

  @override
  List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {
  const AvailabilityInitial();
}

class AvailabilityLoading extends AvailabilityState {
  const AvailabilityLoading();
}

class AvailabilityLoaded extends AvailabilityState {
  final List<AvailabilityModel> slots;

  const AvailabilityLoaded(this.slots);

  @override
  List<Object?> get props => [slots];
}

class AvailabilityError extends AvailabilityState {
  final String message;

  const AvailabilityError(this.message);

  @override
  List<Object> get props => [message];
}

class AvailabilityOperationSuccess extends AvailabilityState {
  final String message;
  final List<AvailabilityModel> slots;

  const AvailabilityOperationSuccess({
    required this.message,
    required this.slots,
  });

  @override
  List<Object?> get props => [message, slots];
}
