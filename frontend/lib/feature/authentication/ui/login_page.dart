import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/images.dart';
import 'package:frontend/feature/authentication/bloc/auth_bloc.dart';
import 'package:frontend/feature/authentication/bloc/auth_event.dart';
import 'package:frontend/feature/authentication/bloc/auth_state.dart';
import 'package:frontend/feature/authentication/data/repository/auth_repository.dart';
import 'package:frontend/feature/common/circular_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = AuthBloc(AuthRepository());
    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppIcons.appIcon, width: 280,),
          Text('SafeShift', style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 50,
            fontWeight: FontWeight.w800
          ),),
          SizedBox(height: 100),
          BlocProvider(
            create: (_) => authBloc,
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is Authenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Welcome ${state.user.name}')),
                  );
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}')),
                  );
                }
              },
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is Authenticated) {
                  return Center(child: Text('Hello ${state.user.name}'));
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: CircularButton(
                    width: double.maxFinite,
                    imagePath: AppIcons.googleIcon,
                    imageType: ImageType.svg,
                    buttonText: AppStrings.signInWithGoogle,
                    textColor: AppColors.primaryColor,
                    onPressed: () async {
                      context.read<AuthBloc>().add(GoogleSignInRequested());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}