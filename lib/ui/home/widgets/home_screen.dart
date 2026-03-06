import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/view_models/signal_noise_ratio.dart';
import 'package:too_many_tabs/ui/home/widgets/new_routine.dart';
import 'package:too_many_tabs/ui/home/widgets/routines_list.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
import 'package:too_many_tabs/utils/result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.homeModel,
    required this.notesModel,
    required this.settingsModel,
  });

  final HomeViewmodel homeModel;
  final NotesViewmodel notesModel;
  final SettingsViewmodel settingsModel;

  @override
  createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isSomePopupShown = false;
  bool showNewRoutinePopup = false;
  RoutineSummary? tappedRoutine;
  SignalNoiseRatio? signalNoiseRatio;

  late final AppLifecycleListener _listener;
  late final Timer t;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () async {
        await widget.homeModel.load.execute();
      },
    );

    _requestPermission();
    _isAndroidPermissionGranted();
    _initSNR();

    const MethodChannel(
      'com.example.tooManyTabs/settings',
    ).setMethodCallHandler((MethodCall call) async {
      debugPrint(call.method);
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    t.cancel();
    super.dispose();
  }

  void _updateSNR() async {
    final now = DateTime.now();
    await widget.homeModel.updateSignalNoiseRatio.execute(now);
    {
      final result =
          widget.homeModel.updateSignalNoiseRatio.result
              as Result<SignalNoiseRatio?>;
      switch (result) {
        case Error<SignalNoiseRatio?>():
          setState(() => signalNoiseRatio = null);
        case Ok<SignalNoiseRatio?>():
          setState(() => signalNoiseRatio = result.value);
      }
    }
    if (widget.homeModel.updateSignalNoiseRatio.error) {
      debugPrint('updateSpecialSessionStatus error');
      return;
    }
  }

  void _initSNR() {
    _updateSNR();
    t = Timer.periodic(const Duration(seconds: 1), (_) async {
      _updateSNR();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    const double actionVerticalOffset = 40;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: labelColor(context, Label.homeAppBarBackground),
        title: Padding(
          padding: EdgeInsets.only(top: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Scaffold(
                            backgroundColor: Colors.black.withValues(alpha: 0),
                            body: TapRegion(
                              onTapOutside: (_) {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 10,
                                children: [],
                              ),
                            ), // Center
                          );
                        },
                      );
                    },
                    child: ListenableBuilder(
                      listenable: widget.homeModel.load,
                      builder: (context, child) {
                        return Loader(
                          error: widget.homeModel.load.error,
                          running: widget.homeModel.load.running,
                          onError: widget.homeModel.load.execute,
                          child: child!,
                        );
                      },
                      child: ListenableBuilder(
                        listenable: widget.homeModel,
                        builder: (context, _) {
                          final r = signalNoiseRatio ?? SignalNoiseRatio();
                          final s = 100 - (r.noise ?? 0);
                          final o = 100 - (r.overtime ?? 0);
                          final width = MediaQuery.of(context).size.width * .5;
                          final radius = 4.0;
                          return Column(
                            spacing: 3,
                            children: [
                              r.meaningful
                                  ? SizedBox(
                                      height: 4,
                                      width: width,
                                      child: Row(
                                        spacing: s >= 98 ? 0 : 5,
                                        children: [
                                          Flexible(
                                            flex: s,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: labelColor(
                                                  context,
                                                  Label.signalBar,
                                                ),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(
                                                    radius,
                                                  ),
                                                  topRight: s >= 98
                                                      ? Radius.circular(radius)
                                                      : Radius.zero,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            flex: 100 - s,
                                            child: Row(
                                              spacing: (s >= 98 || o <= 2)
                                                  ? 0
                                                  : 5,
                                              children: [
                                                Flexible(
                                                  flex: o,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: labelColor(
                                                        context,
                                                        Label.noiseBar,
                                                      ),
                                                      borderRadius: o > 0
                                                          ? null
                                                          : BorderRadius.only(
                                                              topRight:
                                                                  Radius.circular(
                                                                    radius,
                                                                  ),
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  flex: 100 - o,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: labelColor(
                                                        context,
                                                        Label.noiseBar,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                            topRight:
                                                                Radius.circular(
                                                                  radius,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox.shrink(),
                              ListenableBuilder(
                                listenable: widget.settingsModel.load,
                                builder: (context, child) {
                                  return Loader(
                                    error: widget.settingsModel.load.error,
                                    running: widget.settingsModel.load.running,
                                    onError: widget.settingsModel.load.execute,
                                    child: child!,
                                  );
                                },
                                child: ListenableBuilder(
                                  listenable: widget.settingsModel,
                                  builder: (context, _) {
                                    final n =
                                        widget.settingsModel.settings.noise;
                                    return SizedBox(
                                      height: 2,
                                      width: width,
                                      child: Row(
                                        spacing: 5,
                                        children: [
                                          Flexible(
                                            flex: 100 - n,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: labelColor(
                                                  context,
                                                  Label.signalBar,
                                                ),
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    radius,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            flex: n,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: labelColor(
                                                  context,
                                                  Label.noiseBar,
                                                ),
                                                borderRadius: BorderRadius.only(
                                                  bottomRight: Radius.circular(
                                                    radius,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.homeModel.load,
              builder: (context, child) {
                final running = widget.homeModel.load.running,
                    error = widget.homeModel.load.error;
                return Loader(
                  running: running,
                  error: error,
                  onError: widget.homeModel.load.execute,
                  child: child!,
                );
              },
              child: RoutinesList(
                homeModel: widget.homeModel,
                notesModel: widget.notesModel,
              ),
            ),
            showNewRoutinePopup
                ? ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.01, .7, 1],
                      colors: [Colors.black, Colors.black, Colors.transparent],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, .4],
                          colors: [
                            colorScheme.surface,
                            darkMode
                                ? colorScheme.primaryContainer
                                : colorScheme.primaryFixed,
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
            showNewRoutinePopup
                ? Center(
                    child: NewRoutine(
                      closeCancel: () {
                        setState(() {
                          showNewRoutinePopup = false;
                        });
                      },
                      closeCompleted: (id) {
                        setState(() {
                          for (final rs in widget.homeModel.routines) {
                            final routine = rs.$1;
                            if (routine.id == id) {
                              tappedRoutine = routine;
                            }
                          }
                          showNewRoutinePopup = false;
                        });
                      },
                      viewModel: widget.homeModel,
                    ),
                  )
                : Container(),
            isSomePopupShown || showNewRoutinePopup
                ? SizedBox.shrink()
                : Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingAction(
                      onPressed: () {
                        setState(() {
                          showNewRoutinePopup = true;
                        });
                      },
                      icon: Icons.add,
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.addRoutine,
                      ),
                      verticalOffset: actionVerticalOffset,
                    ),
                  ),
            isSomePopupShown || showNewRoutinePopup
                ? Container()
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: FloatingAction(
                      icon: Icons.menu,
                      onPressed: () {
                        context.go(Routes.archives);
                      },
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.backlogRoutine,
                      ),
                      verticalOffset: actionVerticalOffset,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _isAndroidPermissionGranted() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isAndroid) {
      final bool granted =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
      debugPrint('isAndroidPermissionGranted: $granted');
    }
  }

  Future<void> _requestPermission() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (Platform.isAndroid) {
      final plugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await plugin?.requestNotificationsPermission();
      debugPrint('android: granted notifications permissions: $granted');
      final grantedExact = await plugin?.requestExactAlarmsPermission();
      debugPrint('android: granted exact alarms permissions: $grantedExact');
    }
  }
}
