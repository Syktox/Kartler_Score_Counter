import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  UrlLauncherService._();

  static const donateUrl = 'https://buymeacoffee.com/syktox';
  static const bugReportRepo = 'Syktox/Counter_App';

  static Future<void> openDonateUrl(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(donateUrl);

    final openedInExternalApp = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (openedInExternalApp) {
      return;
    }

    final openedWithDefaultMode = await launchUrl(uri);
    if (openedWithDefaultMode) {
      return;
    }

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Could not open donate URL.')),
    );
  }

  static Future<void> openBugReport({
    required BuildContext context,
    required String title,
    required String description,
    required String deviceInfo,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final body =
        '''
## Description
$description

## Device information
$deviceInfo
''';
    final uri = Uri.https('github.com', '/$bugReportRepo/issues/new', {
      'title': '[Bug] $title',
      'body': body,
    });

    final openedInExternalApp = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (openedInExternalApp) {
      return;
    }

    final openedWithDefaultMode = await launchUrl(uri);
    if (openedWithDefaultMode) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: uri.toString()));
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open bug report. Link copied instead.'),
      ),
    );
  }
}
