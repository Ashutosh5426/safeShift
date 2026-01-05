import 'package:flutter/material.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/routes/navigation_service.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBackPressed;
  final Color backgroundColor;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.leading,
    this.onBackPressed,
    this.actions,
    this.backgroundColor = AppColors.primaryBackgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      leading:
          leading ??
          (showBack
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: (){
                    if(onBackPressed!=null) {
                      onBackPressed!();
                    } else {
                      NavigationService.pop();
                    }
                  },
                )
              : const SizedBox()),

      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
      actions: actions,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }
}
