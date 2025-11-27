class UpdateProfileRequestModel {
  final String name;
  final String email;
  final String photo;
  final String mobileNo;

  UpdateProfileRequestModel({
    required this.name,
    required this.email,
    required this.photo,
    required this.mobileNo,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "photo": photo,
      "mobileNo": mobileNo,
    };
  }
}
