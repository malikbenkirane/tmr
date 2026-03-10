import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

@immutable
class NoteWidget extends StatelessWidget {
  const NoteWidget({super.key, required this.note});
  final NoteSummary note;
  @override
  build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 4,
      children: [
        ...note.fragments.map(
          (fragment) => GestureDetector(
            onTap: fragment.$2
                ? () async {
                    await _launchInBrowser(context, fragment.$1);
                  }
                : null,
            child: Text(
              fragment.$1,
              style: TextStyle(
                fontWeight: note.dismissed ? FontWeight.w200 : null,
                color: fragment.$2 ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchInBrowser(BuildContext context, String url) async {
    final UrlLauncherPlatform launcher = UrlLauncherPlatform.instance;
    if (await launcher.canLaunch(url)) {
      await launcher.launch(
        url,
        useSafariVC: false,
        useWebView: false,
        enableJavaScript: false,
        enableDomStorage: false,
        universalLinksOnly: false,
        headers: {},
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('unable to load $url')));
      }
    }
  }
}
