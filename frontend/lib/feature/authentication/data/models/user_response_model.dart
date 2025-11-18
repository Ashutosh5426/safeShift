import 'package:json_annotation/json_annotation.dart';

part 'user_response_model.g.dart';

@JsonSerializable()
class UserResponseModel {
  final String id;
  final String name;
  final String email;
  final String? photo;
  final String? mobileNo;

  UserResponseModel({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
    this.mobileNo,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) => _$UserResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserResponseModelToJson(this);
}
