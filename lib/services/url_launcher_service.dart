import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_constants.dart';
import '../widgets/app_dialogs.dart';

class UrlLauncherService {
  UrlLauncherService._();

  static Future<void> openBugReport({
    required BuildContext context,
    required String title,
    required String description,
    String? deviceInfo,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final colorScheme = Theme.of(context).colorScheme;
    final issueTitle = '${AppConstants.bugReportSubjectPrefix} $title';
    final body =
        '''
### Description
$description
${deviceInfo != null ? '''
### Device information
$deviceInfo
''' : ''}''';
    final uri = Uri.parse(
      AppConstants.githubIssuesUrl,
    ).replace(queryParameters: {'title': issueTitle, 'body': body});

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
      ClipboardData(text: 'Title: $issueTitle\n\n$body\n\n$uri'),
    );
    AppDialogs.showErrorBubbleWithConfig(
      overlay: overlay,
      colorScheme: colorScheme,
      message: 'Could not open GitHub. Bug report details copied instead.',
    );
  }
}
