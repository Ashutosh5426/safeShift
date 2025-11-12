import 'package:dio/dio.dart';
import 'package:frontend/feature/authentication/data/models/user_response_model.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/auth/google')
  Future<Map<String, Object?>> googleSignIn(@Body() Map<String, dynamic> body);

  @GET('/user/profile')
  Future<UserResponseModel> getProfile();
}
