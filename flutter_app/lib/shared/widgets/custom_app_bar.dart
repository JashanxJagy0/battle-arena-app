import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          backgroundColor: AppColors.background.withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          leading: leading ??
              (showBackButton && Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: onBackPressed ?? () => Navigator.pop(context),
                    )
                  : null),
          title: title != null
              ? Text(
                  title!,
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                )
              : null,
          actions: actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ),
      ),
    );
  }
}
