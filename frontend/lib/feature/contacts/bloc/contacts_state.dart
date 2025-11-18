import 'package:equatable/equatable.dart';
import 'package:frontend/feature/contacts/data/models/contacts_model.dart';

abstract class ContactsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ContactsInitial extends ContactsState {}

class AddContactLoading extends ContactsState {}

class AddContactSuccess extends ContactsState {
  final ContactModel contact;
  AddContactSuccess(this.contact);

  @override
  List<Object?> get props => [contact];
}

class AddContactError extends ContactsState {
  final String message;
  AddContactError(this.message);

  @override
  List<Object?> get props => [message];
}

class GetContactsLoading extends ContactsState {}

class GetContactsSuccess extends ContactsState {
  final List<ContactModel> contacts;
  GetContactsSuccess(this.contacts);

  @override
  List<Object?> get props => [contacts];
}

class GetContactsError extends ContactsState {
  final String message;
  GetContactsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeleteContactLoading extends ContactsState {}

class DeleteContactSuccess extends ContactsState {
  final int id;
  DeleteContactSuccess(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteContactError extends ContactsState {
  final String message;
  DeleteContactError(this.message);

  @override
  List<Object?> get props => [message];
}