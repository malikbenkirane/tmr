import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/view_models/signal_noise_ratio.dart';

class HeaderEta extends StatefulWidget {
  final HomeViewmodel model;

  const HeaderEta({super.key, required this.model, required this.routines});

  final List<RoutineSummary> routines;

  @override
  createState() => _HeaderEtaSTate();
}

class _HeaderEtaSTate extends State<HeaderEta> {
  late final AppLifecycleListener _listener;

  DateTime _eta = DateTime.now();
  late Timer _timer;
  bool _ticking = false;

  SignalNoiseRatio? signalNoiseRatio;

  @override
  initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _refreshEta);
  }

  @override
  dispose() {
    _listener.dispose();
    if (_ticking) _timer.cancel();
    super.dispose();
  }

  void _refreshEta() async {
    final now = DateTime.now();

    await widget.model.updateSignalNoiseRatio.execute(now);
    signalNoiseRatio = widget.model.signalNoiseRatio;

    var eta = DateTime.now();
    var inPause = true;
    for (final routine in widget.routines) {
      if (routine.running) inPause = false;
      if (routine.lastStarted == null) {
        eta = eta.add(routine.goal);
      } else {
        final left =
            routine.goal -
            routine.spent -
            (routine.running
                ? now.difference(routine.lastStarted!)
                : Duration.zero);
        if (left > Duration.zero) {
          eta = eta.add(left * 1.2);
        }
      }
    }

    setState(() {
      _eta = eta;
    });

    if (inPause && !_ticking) {
      _ticking = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _refreshEta();
      });
    }
    if (!inPause && _ticking) {
      _ticking = false;
      _timer.cancel();
    }
  }

  List<Widget> buildSignalNoiseRatioWidgets() {
    if (signalNoiseRatio == null) {
      return [];
    }
    if (!signalNoiseRatio!.meaningful) {
      return [];
    }
    return [
      Text('${signalNoiseRatio!.signalPercent}'),
      Text('${signalNoiseRatio!.noisePercent}'),
    ];
  }

  @override
  build(BuildContext context) {
    _refreshEta();
    return Row(
      children: [
        ...buildSignalNoiseRatioWidgets(),
        Column(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              spacing: 2,
              children: [
                Icon(
                  Icons.alarm,
                  size: 22,
                  color: labelColor(
                    context,
                    Label.homeScreenDayETA,
                  ).withValues(alpha: .8),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      _format(_eta),
                      style: TextStyle(
                        fontSize: 22,
                        color: labelColor(context, Label.homeScreenDayETA),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        (_eta.hour >= 12 ? "pm" : "am").toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: labelColor(context, Label.homeScreenDayETA),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _format(DateTime t) {
    var h = t.hour;
    if (h == 0 || h == 12) {
      h = 12;
    } else {
      h = h.remainder(12);
    }
    return '$h:${t.minute.toString().padLeft(2, "0")}';
  }
}
