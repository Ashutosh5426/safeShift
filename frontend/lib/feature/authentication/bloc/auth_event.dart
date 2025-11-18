import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GoogleSignInRequested extends AuthEvent {
  GoogleSignInRequested();

  @override
  List<Object?> get props => [];
}

class FetchProfile extends AuthEvent {}

class SignOutRequested extends AuthEvent {}
