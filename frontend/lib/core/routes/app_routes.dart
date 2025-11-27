import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/feature/authentication/ui/login_page.dart';
import 'package:frontend/feature/contacts/ui/add_contacts_page.dart';
import 'package:frontend/feature/contacts/ui/contact_list_page.dart';
import 'package:frontend/feature/user_profile/bloc/user_profile_bloc.dart';
import 'package:frontend/feature/user_profile/data/repository/profile_repository.dart';
import 'package:frontend/feature/user_profile/ui/user_profile_page.dart';
import 'package:injectable/injectable.dart';

@singleton
class AppRoutes {
  /// Define route names as constants
  static const String initialRoute = '/';
  static const String login = '/login';
  static const String contactList = '/contactList';
  static const String addContact = '/addContact';
  static const String userProfile = '/userProfile';

  /// Generate routes dynamically
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(builder: (_) {
          if(getIt<AppState>().loggedInState == LoggedState.loggedIn) {
            return ContactListPage();
          } else {
            return LoginPage();
          }
        });
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case contactList:
        return MaterialPageRoute(builder: (_) => ContactListPage());
      case addContact:
        return MaterialPageRoute(builder: (_) => AddContactsPage());
      case userProfile:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => UserProfileBloc(UserProfileRepository()),
            child: UserProfilePage(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                'No route defined for ${settings.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
    }
  }

  static Widget loginScreen() => LoginPage();
  static Widget contactListScreen() => ContactListPage();
}
