import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/feature/user_profile/bloc/user_profile_event.dart';
import 'package:frontend/feature/user_profile/bloc/user_profile_state.dart';
import 'package:frontend/feature/user_profile/data/repository/profile_repository.dart';
import 'package:frontend/feature/user_profile/data/request_model/update_profile_request_model.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserProfileRepository _repository;

  UserProfileBloc(this._repository) : super(UserProfileInitial()) {
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(UserProfileLoading());
    try {
      final response = await _repository.updateProfileInfo(
        UpdateProfileRequestModel(
          name: getIt<AppState>().username,
          email: getIt<AppState>().email,
          photo: getIt<AppState>().profileImage,
          mobileNo: event.phoneNo,
        ),
      );
      if (response != null) {
        await getIt<AppState>().updateUserPhoneNo(event.phoneNo);
        emit(UserProfileSuccess(response.message));
      } else {
        emit(UserProfileError('Failed to update profile info'));
      }
    } catch (e) {
      emit(UserProfileError(e.toString()));
    }
  }
}
