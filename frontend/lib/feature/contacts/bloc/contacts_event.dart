import 'package:equatable/equatable.dart';

abstract class ContactsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddContactEvent extends ContactsEvent {
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  AddContactEvent({
    required this.name,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [name, phone, relationship, isPrimary];
}

class GetContactsEvent extends ContactsEvent {}

class DeleteContactEvent extends ContactsEvent {
  final int id;
  DeleteContactEvent(this.id);

  @override
  List<Object?> get props => [id];
}
