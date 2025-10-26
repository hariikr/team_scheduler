import 'package:equatable/equatable.dart';

class TimeSlotModel extends Equatable {
  final DateTime startTime;
  final DateTime endTime;

  const TimeSlotModel({
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  int get durationInMinutes => duration.inMinutes;

  @override
  List<Object?> get props => [startTime, endTime];

  @override
  String toString() {
    return 'TimeSlot(start: $startTime, end: $endTime, duration: ${durationInMinutes}min)';
  }
}
