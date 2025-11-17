import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/shared_preferences/local_storage.dart';
import 'package:frontend/feature/authentication/data/models/user_response_model.dart';

class AuthRepository {
  final _api = ApiClient.getService();

  Future<UserResponseModel?> signInWithGoogle(String idToken) async {
    try {
      final response = await _api.googleSignIn({'idToken': idToken});
      final token = response['token'] as String?;
      final userJson = response['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        throw Exception('Invalid API response');
      }

      await LocalStorage.setToken(token);
      return UserResponseModel.fromJson(userJson);
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<UserResponseModel> getProfile() async {
    return await _api.getProfile();
  }

  Future<void> signOut() async {
    await LocalStorage.clear();
  }
}
