class AddContactRequestModel {
  String name;
  String phone;
  String relationship;
  bool isPrimary;

  AddContactRequestModel({
    required this.name,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['phone'] = phone;
    data['relationship'] = relationship;
    data['isPrimary'] = isPrimary;
    return data;
  }
}
