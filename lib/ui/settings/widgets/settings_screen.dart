import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/data/services/database/database_prepare.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/button.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
import 'package:too_many_tabs/utils/result.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.viewModel});
  final SettingsViewmodel viewModel;

  @override
  createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLifecycleListener _listener;

  Widget? popupWidget;

  @override
  initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        widget.viewModel.load.execute();
      },
    );
  }

  @override
  dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: labelColor(context, Label.appBarBackground),
        title: Padding(
          padding: EdgeInsets.only(left: 5),
          child: Row(
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                  color: labelColor(context, Label.appBarForeground),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(Routes.home),
            icon: Icon(
              Icons.home,
              color: labelColor(context, Label.appBarForeground),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            child: ListenableBuilder(
              listenable: widget.viewModel.load,
              builder: (context, child) {
                final running = widget.viewModel.load.running,
                    error = widget.viewModel.load.error;
                return Loader(
                  error: error,
                  running: running,
                  onError: widget.viewModel.load.execute,
                  child: child!,
                );
              },
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Button(
                              layout: ButtonLayout.iconLeft,
                              icon: Icons.settings_backup_restore,
                              label: 'Import state.db',
                              onPressed: () async {
                                final PlatformFile platformFile;
                                {
                                  final result = await FilePicker.platform
                                      .pickFiles();
                                  if (result == null) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('no picked file'),
                                      ),
                                    );
                                    return;
                                  }
                                  platformFile = result.files.first;
                                }
                                final path = platformFile.path;
                                if (path == null) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: const Text('null path')),
                                  );
                                  return;
                                }
                                final result = await restoreDatabase(path);
                                switch (result) {
                                  case Error<void>():
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'restoreDatabase: ${result.error}',
                                        ),
                                      ),
                                    );
                                    return;
                                  case Ok<void>():
                                    exit(0);
                                }
                              },
                            ),
                            Button(
                              layout: ButtonLayout.iconLeft,
                              icon: Symbols.download_for_offline,
                              label: "Save state.db",
                              onPressed: () async {
                                final data = await saveDatabase();

                                await FilePicker.platform.saveFile(
                                  dialogTitle:
                                      "Keep state.db safe in a cozy spot!",
                                  fileName:
                                      "tmr_state.${DateFormat('MMMM.dd.hh_mm_ss_aa').format(DateTime.now())}.db",
                                  bytes: data,
                                );

                                exit(0);
                              },
                            ), // _Button save state.db
                          ],
                        ), // Column
                      ), // Center
                    ],
                  );
                },
              ),
            ),
          ),
          popupWidget ?? SizedBox.shrink(),
        ],
      ),
    );
  }
}
