import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/feature/user_profile/data/request_model/update_profile_request_model.dart';
import 'package:frontend/feature/user_profile/data/request_model/update_profile_response_model.dart';

class UserProfileRepository {
  final _api = ApiClient.getService();

  Future<UpdateProfileResponseModel?> updateProfileInfo(UpdateProfileRequestModel body) async {
    try {
      final response = await _api.updateProfile(body, getIt<AppState>().userId);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
