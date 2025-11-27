import 'package:equatable/equatable.dart';

abstract class UserProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateProfileEvent extends UserProfileEvent {
  final String phoneNo;
  UpdateProfileEvent({
    required this.phoneNo,
  });

  @override
  List<Object?> get props => [phoneNo];
}