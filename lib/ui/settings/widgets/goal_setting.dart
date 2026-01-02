import 'package:flutter/material.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class GoalSetting extends StatelessWidget {
  const GoalSetting({
    super.key,
    required this.label,
    required this.goal,
    required this.onTap,
  });
  final String label;
  final Duration goal;
  final void Function() onTap;

  static const double size = 48 * .8;

  @override
  build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          spacing: 10,
          children: [
            Text('(${formatUntilGoal(goal, Duration())})'),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: cs.secondaryContainer, // background colour
                shape: BoxShape.circle,
                // Optional: a subtle border that also respects the scheme
                border: Border.all(
                  color: cs.onSecondaryContainer.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              // InkWell gives us the material ripple + splash that matches the theme.
              child: Material(
                // Material type “transparency” lets the Container’s colour show.
                type: MaterialType.transparency,
                child: InkWell(
                  // Ink splash colour that respects the colour scheme.
                  splashColor: cs.primary.withValues(alpha: 0.12),
                  // Highlight (pressed) colour.
                  highlightColor: cs.primary.withValues(alpha: 0.08),
                  // Keep the circular clipping for the ripple.
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Center(
                    child: Icon(
                      Icons.edit,
                      size: size * 0.5, // 50 % of the button’s diameter
                      color: cs.onSecondaryContainer, // icon colour
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
