import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/error_indicator.dart';

class Loader extends StatelessWidget {
  const Loader({
    super.key,
    required this.error,
    required this.running,
    required this.onError,
    required this.child,
  });
  final bool error, running;
  final void Function() onError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (running) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error) {
      return ErrorIndicator(
        title: 'Error Loading Home',
        label: 'Try Again',
        onPressed: onError,
      );
    }

    return child;
  }
}
