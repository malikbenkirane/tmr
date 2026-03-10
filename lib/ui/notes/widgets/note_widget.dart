import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

@immutable
class NoteWidget extends StatelessWidget {
  final NoteSummary note;

  const NoteWidget({super.key, required this.note});

  @override
  build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        ...note.fragments.map(
          (fragment) => _fragment(
            context,
            providesLaunch: fragment.$2,
            text: fragment.$1,
          ),
        ),
      ],
    );
  }

  Widget _fragment(
    BuildContext context, {
    required bool providesLaunch,
    required String text,
  }) {
    if (!providesLaunch) {
      return Text(
        text,
        style: TextStyle(fontWeight: note.dismissed ? FontWeight.w200 : null),
      );
    }
    return Material(
      borderRadius: BorderRadius.circular(5),
      elevation: .2,
      child: InkWell(
        onTap: () {
          _launchInBrowser(context, text);
        },
        borderRadius: BorderRadius.circular(5),

        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            text,
            style: TextStyle(
              color: labelColor(context, Label.noteLink),
              fontWeight: note.dismissed ? FontWeight.w400 : null,
            ),
          ),
        ),
      ),
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
