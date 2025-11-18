class ContactResponseModel {
  late int id;
  late String userId;
  late String name;
  late String phone;
  late String relationship;
  late bool isPrimary;
  late String createdAt;
  late String updatedAt;

  ContactResponseModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  ContactResponseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    name = json['name'];
    phone = json['phone'];
    relationship = json['relationship'];
    isPrimary = json['isPrimary'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['name'] = name;
    data['phone'] = phone;
    data['relationship'] = relationship;
    data['isPrimary'] = isPrimary;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
