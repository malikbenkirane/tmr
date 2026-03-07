import 'package:flutter/material.dart';

@immutable
class Button extends StatelessWidget {
  final IconData icon;
  final String label;
  final void Function() onPressed;
  final ButtonLayout layout;

  const Button({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.layout,
  });

  @override
  build(BuildContext context) {
    final borderRadius = BorderRadius.all(Radius.circular(17));
    return Material(
      elevation: 1,
      borderRadius: borderRadius,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                spacing: 2,
                mainAxisAlignment: MainAxisAlignment.center,
                children: () {
                  final row = [
                    Icon(icon),
                    Text(label, style: TextStyle(fontSize: 16)),
                  ];
                  if (layout == ButtonLayout.iconRight) {
                    return row.reversed.toList();
                  }
                  return row;
                }(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonLayout { iconLeft, iconRight }
