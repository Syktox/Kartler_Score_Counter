import 'package:flutter/material.dart';

import '../utils/name_utils.dart';

class AppDialogs {
  const AppDialogs._();

  static Future<void> showAddItemDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    required bool Function(String name) isValidName,
    required ValueChanged<String> onAdd,
  }) {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          final name = NameUtils.clean(controller.text);
          if (isValidName(name)) {
            onAdd(name);
            Navigator.of(dialogContext).pop();
            return;
          }

          focusNode.requestFocus();
        }

        return AlertDialog(
          scrollable: true,
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: submit, child: const Text('Add')),
          ],
          actionsOverflowDirection: VerticalDirection.up,
        );
      },
    );
  }

  static Future<void> showRenameItemDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required String hintText,
    required String duplicateNameMessage,
    required bool Function(String name) isValidName,
    required ValueChanged<String> onRename,
  }) {
    final focusNode = FocusNode();
    final controller = TextEditingController(text: initialValue)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: initialValue.length,
      );

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          final name = NameUtils.clean(controller.text);
          if (name.isNotEmpty && isValidName(name)) {
            onRename(name);
            Navigator.of(dialogContext).pop();
            return;
          }

          focusNode.requestFocus();

          if (name.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(duplicateNameMessage)));
          }
        }

        return AlertDialog(
          scrollable: true,
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: submit, child: const Text('Rename')),
          ],
          actionsOverflowDirection: VerticalDirection.up,
        );
      },
    );
  }

  static Future<void> showDeleteItemDialog({
    required BuildContext context,
    required String title,
    required String itemName,
    required ValueChanged<String> onDelete,
    bool autofocusDelete = false,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text('Do you really want to delete "$itemName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              autofocus: autofocusDelete,
              onPressed: () {
                onDelete(itemName);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
