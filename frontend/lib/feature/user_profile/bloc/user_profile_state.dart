import 'package:equatable/equatable.dart';

abstract class UserProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileSuccess extends UserProfileState {
  final String message;
  UserProfileSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UserProfileError extends UserProfileState {
  final String message;
  UserProfileError(this.message);

  @override
  List<Object?> get props => [message];
}