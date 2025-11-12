import 'package:flutter/material.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/feature/authentication/ui/login_page.dart';
import 'package:frontend/feature/contacts/ui/add_contacts_page.dart';
import 'package:frontend/feature/contacts/ui/contact_list_page.dart';

class AppRoutes {
  /// Define route names as constants
  static const String initialRoute = '/';
  static const String login = '/login';
  static const String contactList = '/contactList';
  static const String addContact = '/addContact';

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
