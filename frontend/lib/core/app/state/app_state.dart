import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:frontend/core/routes/navigation_service.dart';
import 'package:frontend/core/shared_preferences/local_storage.dart';
import 'package:frontend/core/shared_preferences/storage_constants.dart';
import 'package:frontend/feature/authentication/data/models/user_response_model.dart';
import 'package:frontend/feature/authentication/google_sign_in.dart';
import 'package:injectable/injectable.dart';

enum LoggedState { loggedOut, loggedIn }

@singleton
class AppState extends ChangeNotifier {
  LoggedState _loggedInState = LoggedState.loggedOut;
  final String _iosClientId = dotenv.env['IOS_CLIENT_ID'] ?? '';
  final String _serverClientId = dotenv.env['SERVERS_CLIENT_ID'] ?? '';
  final String _baseUrl = dotenv.env['BASE_URL'] ?? '';

  LoggedState get loggedInState {
    final isLoggedIn = LocalStorage.getBool(SHARED_PREFS_ISLOGGEDIN) ?? false;
    _loggedInState = isLoggedIn ? LoggedState.loggedIn : LoggedState.loggedOut;
    return _loggedInState;
  }

  String get userId => LocalStorage.getString(StorageConstants.userId) ?? '';

  String get username =>
      LocalStorage.getString(StorageConstants.username) ?? '';

  String get email => LocalStorage.getString(StorageConstants.userEmail) ?? '';

  String get profileImage =>
      LocalStorage.getString(StorageConstants.profileImage) ?? '';

  String get userPhoneNo =>
      LocalStorage.getString(StorageConstants.userPhoneNo) ?? '';

  Future<bool> updateUserPhoneNo(String value) async {
    return await LocalStorage.setString(StorageConstants.userPhoneNo, value);
  }

  String get iosClientId => _iosClientId;

  String get serverClientId => _serverClientId;

  String get baseUrl => _baseUrl;

  Future<void> logIn() async {
    _loggedInState = LoggedState.loggedIn;
    await LocalStorage.setBool(SHARED_PREFS_ISLOGGEDIN, true);
    NavigationService.pushNamedAndRemoveUntil(AppRoutes.contactList);
    notifyListeners();
  }

  Future<void> logOut() async {
    _loggedInState = LoggedState.loggedOut;
    AuthService.instance.signOut();
    await LocalStorage.clear(whiteList: []);
    NavigationService.pushNamedAndRemoveUntil(AppRoutes.login);
    notifyListeners();
  }

  Future<bool> setUserPreferences(UserResponseModel user) async {
    final id = await LocalStorage.setString(StorageConstants.userId, user.id);
    final name = await LocalStorage.setString(
      StorageConstants.username,
      user.name,
    );
    final email = await LocalStorage.setString(
      StorageConstants.userEmail,
      user.email,
    );
    final photo = await LocalStorage.setString(
      StorageConstants.profileImage,
      user.photo ?? '',
    );
    final phone = await LocalStorage.setString(
      StorageConstants.userPhoneNo,
      user.mobileNo ?? '',
    );
    return id && name && email && photo && phone;
  }
}
