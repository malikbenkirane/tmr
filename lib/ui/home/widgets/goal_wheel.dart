import 'package:flutter/material.dart';

@immutable
class GoalWheel extends StatelessWidget {
  const GoalWheel({
    super.key,
    required this.delegate,
    required this.itemExtent,
    required this.width,
    required this.initialItem,
    required this.onSelected,
  });

  final ListWheelChildBuilderDelegate delegate;
  final double itemExtent, width;
  final int initialItem;
  final void Function(int) onSelected;

  @override
  build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .2, .5, .8, 1],
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black,
            Colors.transparent,
            Colors.transparent,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Container(
        width: width,
        margin: EdgeInsets.all(2),
        child: ListWheelScrollView.useDelegate(
          controller: FixedExtentScrollController(initialItem: initialItem),
          onSelectedItemChanged: onSelected,
          physics: FixedExtentScrollPhysics(),
          itemExtent: itemExtent * .92,
          perspective: 0.003,
          diameterRatio: .7,
          childDelegate: delegate,
        ),
      ),
    );
  }
}
