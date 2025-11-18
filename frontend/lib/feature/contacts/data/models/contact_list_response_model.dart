import 'contact_response_model.dart';

class ContactListResponseModel {
  final List<ContactResponseModel> contacts;

  ContactListResponseModel({required this.contacts});

  factory ContactListResponseModel.fromJson(dynamic json) {
    // API may return either a bare array or an object with a list field; support both.
    if (json is List) {
      return ContactListResponseModel(
        contacts:
            json.map((e) => ContactResponseModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }

    if (json is Map<String, dynamic>) {
      final list = json['data'] ?? json['contacts'] ?? json['items'] ?? json['results'];
      if (list is List) {
        return ContactListResponseModel(
          contacts: list
              .map((e) => ContactResponseModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    }

    // Fallback to empty list if shape is unexpected
    return ContactListResponseModel(contacts: const []);
  }

  Map<String, dynamic> toJson() => {
        'contacts': contacts.map((e) => e.toJson()).toList(),
      };
}
