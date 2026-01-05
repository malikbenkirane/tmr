import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.initialOpen,
    required this.distance,
    required this.children,
    required this.spreadAngle,
  });

  final bool? initialOpen;
  final double distance;
  final double spreadAngle;
  final List<Widget> children;

  @override
  createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  bool _open = false;

  static const double _translateAll = 50;

  @override
  initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
    );
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _position(_buildTapToCloseFab()),
          ..._buildExpandingActionButtons(),
          _position(_buildTapToOpenFab()),
        ],
      ),
    );
  }

  Widget _position(Widget child) {
    return Positioned(
      right: _translateAll,
      bottom: _translateAll,
      child: child,
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = (widget.spreadAngle) / (count - 1);
    for (
      var i = 0, angleInDegress = -(widget.spreadAngle - 90) / 2;
      i < count;
      i++, angleInDegress += step
    ) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegress,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          translateAll: _translateAll,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          color: Theme.of(context).colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(_open ? 0.7 : 1, _open ? 0.7 : 1, 1),
        curve: const Interval(0, .5, curve: Curves.easeInOut),
        child: AnimatedOpacity(
          opacity: _open ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            shape: const CircleBorder(),
            onPressed: _toggle,
            child: const Icon(Symbols.action_key),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.translateAll,
  });

  final double directionInDegrees, maxDistance, translateAll;
  final Animation<double> progress;
  final Widget child;

  @override
  build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * math.pi / 180,
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4 + offset.dx + translateAll,
          bottom: 4 + offset.dy + translateAll,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * 3 * math.pi / 4,
            child: child!,
          ),
        );
      },
      child: FadeTransition(opacity: progress, child: child),
    );
  }
}
