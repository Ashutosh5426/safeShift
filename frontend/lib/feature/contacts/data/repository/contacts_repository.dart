import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/feature/contacts/data/models/add_contact_request_model.dart';
import 'package:frontend/feature/contacts/data/models/contacts_model.dart';

class ContactsRepository {
  final _api = ApiClient.getService();

  Future<ContactModel?> addContacts(AddContactRequestModel body) async {
    try {
      final response = await _api.addContacts(body);
      return ContactModel.fromResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ContactModel>> getAllContacts() async {
    try {
      final response = await _api.getAllContacts();
      return response.contacts.map(ContactModel.fromResponse).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      await _api.deleteContact(id);
    } catch (e) {
      rethrow;
    }
  }
}
