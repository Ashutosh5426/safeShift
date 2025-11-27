import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/feature/common/circular_button.dart';
import 'package:frontend/feature/common/common_app_bar.dart';
import 'package:frontend/feature/common/common_network_image.dart';
import 'package:frontend/feature/common/common_text_form_field.dart';
import 'package:frontend/feature/user_profile/bloc/user_profile_bloc.dart';
import 'package:frontend/feature/user_profile/bloc/user_profile_event.dart';
import 'package:frontend/feature/user_profile/bloc/user_profile_state.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _editMode = false;
  late AppState _appState;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _appState = getIt<AppState>();
    _emailController = TextEditingController(text: _appState.email);
    _phoneController = TextEditingController(text: _appState.userPhoneNo);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = getIt<AppState>();
    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundColor,
      appBar: CommonAppBar(
        title: 'Profile',
        actions: [
          if (!_editMode)
            InkWell(
              onTap: _toggleEditMode,
              child: Icon(Icons.mode_edit_sharp, color: AppColors.primaryColor),
            ),
          const SizedBox(width: 20),
        ],
        onBackPressed: () {
          if (_editMode) {
            _toggleEditMode();
          } else {
            Navigator.pop(context);
          }
        },
      ),

      /// Wrap whole body to dismiss keyboard
      body: GestureDetector(
        onTap: () {
          _emailFocusNode.unfocus();
          _phoneFocusNode.unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    /// Profile image
                    Hero(
                      tag: "profilePicHero",
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: CommonNetworkWidget(
                            imageUrl: appState.profileImage,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Username
                    Text(
                      appState.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(thickness: 2, color: AppColors.black),
                    const SizedBox(height: 20),

                    /// Email field
                    CommonTextFormField(
                      leftIcon: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.mail_outline,
                          color: AppColors.black,
                          size: 30,
                        ),
                      ),
                      textFieldController: _emailController,
                      readOnly: true,
                      focusNode: _emailFocusNode,
                      textFontSize: 20,
                    ),

                    /// Phone field
                    if (appState.userPhoneNo.isNotEmpty || _editMode) ...[
                      const SizedBox(height: 20),
                      CommonTextFormField(
                        leftIcon: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.local_phone_outlined,
                            color: AppColors.black,
                            size: 30,
                          ),
                        ),
                        textFieldController: _phoneController,
                        hintText: 'Mobile Number',
                        readOnly: !_editMode,
                        focusNode: _phoneFocusNode,
                        textFontSize: 20,
                        hintFontSize: 20,
                        validator: (String? value) {
                          return validateMobile(value);
                        },
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          if (value.length >= 10) {
                            _formKey.currentState?.validate();
                          }
                        },
                      ),
                    ],

                    if (_editMode) ...[
                      const SizedBox(height: 40),
                      BlocConsumer<UserProfileBloc, UserProfileState>(
                        listener: (context, state) {
                          if (state is UserProfileSuccess) {
                            _toggleEditMode();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('User info updated')),
                            );
                          }
                        },
                        builder: (context, state) {
                          return CircularButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                context.read<UserProfileBloc>().add(
                                  UpdateProfileEvent(
                                    phoneNo:
                                        _phoneController.text.contains('+91')
                                        ? _phoneController.text
                                        : '+91 ${_phoneController.text}',
                                  ),
                                );
                              }
                            },
                            isLoading: state is UserProfileLoading,
                            buttonText: 'Save Profile',
                            buttonColor: AppColors.primaryColor,
                            textColor: AppColors.white,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 40),

                    /// Logout button
                    TextButton(
                      onPressed: () => getIt<AppState>().logOut(),
                      child: Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
      _emailFocusNode.unfocus();
      _phoneFocusNode.unfocus();
      _emailController.text = _appState.email;
      _phoneController.text = _appState.userPhoneNo;
    });
  }
}

String? validateMobile(String? value) {
  if (value == null || value.trim().isEmpty) {
    return "Mobile number is required";
  }

  // Remove all non-digit characters
  String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

  /// Remove country code "91" at start
  if (digits.startsWith('91') && digits.length > 10) {
    digits = digits.substring(2);
  }

  /// After cleaning, must be exactly 10 digits
  if (digits.length != 10) {
    return "Enter a valid 10-digit mobile number";
  }

  /// Must start with 6–9
  final regex = RegExp(r'^[6-9]\d{9}$');

  if (!regex.hasMatch(digits)) {
    return "Enter a valid 10-digit mobile number";
  }

  return null;
}
