import 'package:frontend/feature/contacts/data/models/contact_response_model.dart';

class ContactModel {
  final int id;
  final String userId;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final String createdAt;
  final String updatedAt;

  const ContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  static ContactModel fromResponse(ContactResponseModel response) {
    return ContactModel(
      id: response.id,
      userId: response.userId,
      name: response.name,
      phone: response.phone,
      relationship: response.relationship,
      isPrimary: response.isPrimary,
      createdAt: response.createdAt,
      updatedAt: response.updatedAt,
    );
  }
}
