import 'package:equatable/equatable.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserSuccess extends UserState {
  final String userId;
  final String name;
  final String? photoUrl;

  const UserSuccess({
    required this.userId,
    required this.name,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [userId, name, photoUrl];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object> get props => [message];
}
