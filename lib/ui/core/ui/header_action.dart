import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';

class HeaderAction extends StatelessWidget {
  const HeaderAction({super.key, required this.icon, required this.onPressed});
  final IconData icon;
  final void Function() onPressed;

  @override
  build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: labelColor(context, Label.homeScreenSettingsWheel),
    );
  }
}
