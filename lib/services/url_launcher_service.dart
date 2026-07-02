import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  UrlLauncherService._();

  static const donateUrl = 'https://buymeacoffee.com/syktox';
  static const bugReportEmail = 'markus.kammerstetter@hotmail.com';

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
    final subject = '[Counter App Bug] $title';
    final body =
        '''
Description
$description

Device information
$deviceInfo
''';
    final uri = Uri(
      scheme: 'mailto',
      path: bugReportEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

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

    await Clipboard.setData(
      ClipboardData(text: 'To: $bugReportEmail\nSubject: $subject\n\n$body'),
    );
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open email app. Bug report copied instead.'),
      ),
    );
  }
}
