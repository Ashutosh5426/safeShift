import 'package:flutter/material.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:frontend/core/routes/navigation_service.dart';
import 'package:frontend/feature/common/common_network_image.dart';
import 'package:frontend/feature/safe_model/ui/safe_mode_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = getIt<AppState>();
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: (){
                      NavigationService.pushNamed(AppRoutes.userProfile);
                    },
                    child: Hero(
                      tag: "profilePicHero",
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: CommonNetworkWidget(
                            imageUrl: appState.profileImage,
                            width: 60, // match diameter
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    appState.username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stay Safe, Stay Connected',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.contacts_outlined),
              title: const Text('Contacts'),
              onTap: () {
                NavigationService.pop();
              },
            ),

            ListTile(
              leading: const Icon(Icons.safety_check_rounded),
              title: const Text('Safe Mode'),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SafeModePage()));
              },
            ),

            const Spacer(),

            const Divider(thickness: 1),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                getIt<AppState>().logOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
