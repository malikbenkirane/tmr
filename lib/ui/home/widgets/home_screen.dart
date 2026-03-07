import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/data/services/database/database_prepare.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/button.dart';
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
  RoutineSummary? tappedRoutine;
  bool isPopup = false;

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
              as Result<SignalRatio?>;
      switch (result) {
        case Error<SignalRatio?>():
        // debugPrint('[ERROR] updateSpecialSessionStatus: ${result.error}');
        default:
      }
    }
  }

  void _initSNR() {
    _updateSNR();
    t = Timer.periodic(const Duration(seconds: 1), (_) async {
      _updateSNR();
    });
  }

  Widget _topBar({
    required SignalRatio r,
    required double height,
    required double radius,
  }) {
    final s = 100 - (r.noise ?? 0);
    final o = 100 - (r.overtime ?? 0);
    if (!r.meaningful) {
      return SizedBox.shrink();
    }
    return SizedBox(
      height: height,
      child: Row(
        spacing: (s == 0 || s == 100) ? 0 : 5,
        children: [
          Flexible(
            flex: s,
            child: Container(
              decoration: BoxDecoration(
                color: labelColor(context, Label.signalBar),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: s == 100 ? Radius.circular(radius) : Radius.zero,
                ),
              ),
            ),
          ),
          Flexible(
            flex: 100 - s,
            child: s == 100
                ? SizedBox.shrink()
                : Row(
                    spacing: (o == 100 || o == 0) ? 0 : 5,
                    children: [
                      Flexible(
                        flex: 100 - o,
                        child: Container(
                          decoration: BoxDecoration(
                            color: labelColor(context, Label.noiseBar),
                            borderRadius: BorderRadius.only(
                              topLeft: o >= 0 && s == 0
                                  ? Radius.circular(radius)
                                  : Radius.zero,
                              topRight: o == 0
                                  ? Radius.circular(radius)
                                  : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: o,
                        child: Container(
                          decoration: BoxDecoration(
                            color: labelColor(context, Label.noiseBar),
                            borderRadius: BorderRadius.only(
                              topLeft: s > 0 || o > 0
                                  ? Radius.zero
                                  : Radius.circular(radius),
                              topRight: Radius.circular(radius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar({required double radius, required double height}) {
    return ListenableBuilder(
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
          final n = widget.settingsModel.settings.noise;
          return SizedBox(
            height: height,
            child: Row(
              spacing: 5,
              children: [
                Flexible(
                  flex: 100 - n,
                  child: Container(
                    decoration: BoxDecoration(
                      color: labelColor(context, Label.signalBar),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: n,
                  child: Container(
                    decoration: BoxDecoration(
                      color: labelColor(context, Label.noiseBar),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _restoreStateMenuButton(BuildContext context) {
    return Button(
      layout: ButtonLayout.iconLeft,
      icon: Symbols.arrow_upward,
      label: 'Import',
      onPressed: () async {
        final PlatformFile platformFile;
        {
          final result = await FilePicker.platform.pickFiles();
          if (result == null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: const Text('no picked file')));
            return;
          }
          platformFile = result.files.first;
        }
        final path = platformFile.path;
        if (path == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: const Text('null path')));
          return;
        }
        final result = await restoreDatabase(path);
        switch (result) {
          case Error<void>():
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('restoreDatabase: ${result.error}')),
            );
            return;
          case Ok<void>():
            exit(0);
        }
      },
    );
  }

  Widget _saveStateMenuButton() {
    return Button(
      layout: ButtonLayout.iconRight,
      icon: Symbols.arrow_downward,
      label: "Save",
      onPressed: () async {
        final data = await saveDatabase();

        await FilePicker.platform.saveFile(
          dialogTitle: "Keep state.db safe in a cozy spot!",
          fileName:
              "tmr_state.${DateFormat('MMMM.dd.hh_mm_ss_aa').format(DateTime.now())}.db",
          bytes: data,
        );

        exit(0);
      },
    );
  }

  Widget _menu() {
    final theme = Theme.of(context);
    return TapRegion(
      onTapOutside: (_) {
        Navigator.pop(context);
        setState(() => isPopup = false);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 46, vertical: 0),
        child: Column(
          spacing: 8,
          children: [
            Flexible(
              child: Material(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(37),
                child: Padding(
                  padding: EdgeInsetsGeometry.only(
                    bottom: 14,
                    top: 18,
                    left: 27,
                    right: 27,
                  ),
                  child: Column(
                    spacing: 20,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('State File', style: TextStyle(fontSize: 20)),
                      Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: _saveStateMenuButton()),
                          Expanded(child: _restoreStateMenuButton(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.homeModel,
              builder: (context, _) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 17),
                  child: widget.homeModel.isSignalRatioLocked
                      ? null
                      : Material(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () async {
                              await widget.homeModel.lockSignalRatio.execute();
                              if (widget.homeModel.lockSignalRatio.error) {
                                final result =
                                    widget.homeModel.lockSignalRatio.result
                                        as Result<void>;
                                switch (result) {
                                  case Error<void>():
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result.error.toString()),
                                      ),
                                    );
                                  default:
                                }
                              }
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              setState(() => isPopup = false);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: const Text(
                                    'Lock Signal-Ratio',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar() {
    if (isPopup) {
      return SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Scaffold(
                    backgroundColor: Colors.black.withValues(alpha: 0),
                    body: _menu(), // Center
                  );
                },
              );
              setState(() => isPopup = true);
            },
            child: ListenableBuilder(
              listenable: widget.homeModel.load,
              builder: (context, child) {
                return Loader(
                  error: widget.homeModel.load.error,
                  running: widget.homeModel.load.running,
                  onError: widget.homeModel.load.execute,
                  hide: true,
                  child: child!,
                );
              },
              child: ListenableBuilder(
                listenable: widget.homeModel,
                builder: (context, _) {
                  final r = widget.homeModel.signalRatio ?? SignalRatio();
                  // final width = MediaQuery.of(context).size.width * .3;
                  const radius = 10.0;
                  const height = 8.0;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: height / 2,
                          children: [
                            _topBar(radius: radius, height: height, r: r),
                            _bottomBar(radius: radius, height: height),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _addRoutine(BuildContext context, String name) async {
    try {
      await widget.homeModel.addRoutine.execute(name);
      if (!context.mounted) return;
      final result = widget.homeModel.addRoutine.result as Result<void>;
      switch (result) {
        case Error<void>():
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${result.error}')));
          return;
        default:
      }
      for (final rs in widget.homeModel.routines) {
        final r = rs.$1;
        if (r.id == widget.homeModel.lastCreatedRoutineID!) {
          tappedRoutine = r;
        }
      }
    } finally {
      Navigator.pop(context);
      setState(() => isPopup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isPopup
                        ? SizedBox.shrink()
                        : FloatingAction(
                            onPressed: () {
                              setState(() => isPopup = true);
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Scaffold(
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0,
                                    ),
                                    body: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(40),
                                        child: NewRoutine(
                                          onAdd: (name) =>
                                              _addRoutine(context, name),
                                          onCancel: () {
                                            Navigator.pop(context);
                                            setState(() => isPopup = false);
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.add),
                            colorComposition: colorCompositionFromAction(
                              context,
                              ApplicationAction.addRoutine,
                            ),
                          ),
                    Expanded(child: _bar()),
                    isPopup
                        ? SizedBox.shrink()
                        : FloatingAction(
                            icon: Icon(Icons.menu),
                            onPressed: () {
                              context.go(Routes.archives);
                            },
                            colorComposition: colorCompositionFromAction(
                              context,
                              ApplicationAction.backlogRoutine,
                            ),
                          ),
                  ],
                ),
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
