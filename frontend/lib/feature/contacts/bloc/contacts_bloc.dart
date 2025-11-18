import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/feature/contacts/bloc/contacts_event.dart';
import 'package:frontend/feature/contacts/bloc/contacts_state.dart';
import 'package:frontend/feature/contacts/data/models/add_contact_request_model.dart';
import 'package:frontend/feature/contacts/data/repository/contacts_repository.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository _contactsRepository;

  ContactsBloc(this._contactsRepository) : super(ContactsInitial()) {
    on<AddContactEvent>(_onAddContacts);
    on<GetContactsEvent>(_onGetContacts);
    on<DeleteContactEvent>(_onDeleteContact);
  }

  Future<void> _onAddContacts(
    AddContactEvent event,
    Emitter<ContactsState> emit,
  ) async {
    emit(AddContactLoading());
    try {
      final contact = await _contactsRepository.addContacts(
        AddContactRequestModel(
          name: event.name,
          phone: event.phone,
          relationship: event.relationship,
          isPrimary: event.isPrimary,
        ),
      );
      if (contact != null) {
        emit(AddContactSuccess(contact));
      } else {
        emit(AddContactError('Failed to add contact'));
      }
    } catch (e) {
      emit(AddContactError(e.toString()));
    }
  }

  Future<void> _onGetContacts(
    GetContactsEvent event,
    Emitter<ContactsState> emit,
  ) async {
    emit(GetContactsLoading());
    try {
      final contacts = await _contactsRepository.getAllContacts();
      emit(GetContactsSuccess(contacts));
    } catch (e) {
      emit(GetContactsError(e.toString()));
    }
  }

  Future<void> _onDeleteContact(
    DeleteContactEvent event,
    Emitter<ContactsState> emit,
  ) async {
    emit(DeleteContactLoading());
    try {
      await _contactsRepository.deleteContact(event.id);
      emit(DeleteContactSuccess(event.id));
    } catch (e) {
      emit(DeleteContactError(e.toString()));
    }
  }
}
