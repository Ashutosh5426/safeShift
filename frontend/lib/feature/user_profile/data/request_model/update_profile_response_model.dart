class UpdateProfileResponseModel {
  final bool success;
  final String message;
  final int statusCode;

  UpdateProfileResponseModel({
    required this.success,
    required this.message,
    required this.statusCode,
  });

  factory UpdateProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      statusCode: json['status'] ?? 0,
    );
  }
}
