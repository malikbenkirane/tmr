import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/data/repositories/routines/special_session_duration.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/header_action.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/view_models/routine_state.dart';
import 'package:too_many_tabs/ui/home/widgets/header_eta.dart';
import 'package:too_many_tabs/ui/home/widgets/new_routine.dart';
import 'package:too_many_tabs/ui/home/widgets/routines_list.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';

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

    t = Timer.periodic(const Duration(seconds: 1), (_) async {
      final now = DateTime.now();
      await widget.homeModel.updateSignalNoiseRatio.execute(now);
      if (widget.homeModel.updateSignalNoiseRatio.error) {
        debugPrint('updateSpecialSessionStatus error');
        return;
      }
    });

    _requestPermission();
    _isAndroidPermissionGranted();

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    const double actionVerticalOffset = 40;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: labelColor(context, Label.homeAppBarBackground),
        title: Padding(
          padding: EdgeInsets.all(0),
          child: ListenableBuilder(
            listenable: widget.homeModel,
            builder: (context, _) {
              final specialSession = widget.homeModel.runningSpecialSession;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                        return Row(
                          spacing: 6,
                          children: [
                            ..._buildAppTitle(
                              context: context,
                              session: specialSession,
                              settings:
                                  widget.settingsModel.settings.specialGoals,
                              state: widget
                                  .homeModel
                                  .specialSessionAllStatum[specialSession],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  ListenableBuilder(
                    listenable: widget.settingsModel.load,
                    builder: (context, child) {
                      final running = widget.settingsModel.load.running,
                          error = widget.settingsModel.load.error;
                      return Loader(
                        error: error,
                        running: running,
                        onError: widget.settingsModel.load.execute,
                        child: child!,
                      );
                    },
                    child: ListenableBuilder(
                      listenable: widget.settingsModel,
                      builder: (context, _) {
                        return Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Scaffold(
                                      backgroundColor: Colors.black.withValues(
                                        alpha: 0,
                                      ),
                                      body: TapRegion(
                                        onTapOutside: (_) {
                                          if (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 10,
                                          children: [
                                            _Button(
                                              dialogContext: context,
                                              label: 'End Pomodoro',
                                              icon: Symbols.timer_off,
                                              onTap: () async {
                                                //TODO
                                              },
                                            ),
                                            _Button(
                                              dialogContext: context,
                                              label: 'Cancel Notifications',
                                              icon: Symbols.cancel,
                                              onTap: () async {
                                                //TODO
                                              },
                                            ),
                                          ],
                                        ),
                                      ), // Center
                                    );
                                  },
                                );
                              },
                              child: HeaderEta(
                                routines: widget.homeModel.routines
                                    .map((rs) => rs.$1)
                                    .toList(),
                                specialGoals:
                                    widget.settingsModel.settings.specialGoals,
                                specialSessionState:
                                    widget.homeModel.specialSessionStatus ??
                                    SpecialSessionDuration(
                                      current: null,
                                      duration: Duration(),
                                    ),
                              ), // HeaderETA
                            ), // GestureDetector
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          HeaderAction(
            icon: Icons.settings,
            onPressed: () => context.go(Routes.settings),
          ),
        ],
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

@immutable
class _Button extends StatelessWidget {
  final Future<void> Function() onTap;
  final String label;
  final IconData icon;
  final BuildContext dialogContext;
  const _Button({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.dialogContext,
  });
  @override
  build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(20),
          textStyle: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 20,
          ),
          color: theme.colorScheme.primary,
          child: InkWell(
            onTap: () async {
              await onTap();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  Icon(icon, color: theme.colorScheme.onPrimary),
                  Text(label),
                ],
              ), // Row
            ), // Padding
          ), // InkWell
        ), // Material
      ],
    ); // TapRegion
  }
}
