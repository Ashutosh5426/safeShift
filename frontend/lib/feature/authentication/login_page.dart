import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/images.dart';
import 'package:frontend/feature/common/circular_button.dart';

import 'google_sign_in.dart' show AuthService;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppImages.splashImage),
          SizedBox(height: 32),
          CircularButton(
            AppIcons.googleIcon,
            imageType: ImageType.svg,
            buttonText: AppStrings.signInWithGoogle,
            onPressed: () async {
              final user = await AuthService().signInWithGoogle();
              if (user != null) {
                print('Successfully signed in: ${user.displayName}');
              }
            },
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.photoURL != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL!),
                radius: 50,
              ),
            SizedBox(height: 16),
            Text(
              'Hello, ${user.displayName ?? 'User'}!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(user.email ?? '', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text(
              'UID: ${user.uid}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
