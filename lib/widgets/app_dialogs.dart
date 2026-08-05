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
    return showDialog<void>(
      context: context,
      builder: (_) => _ItemNameDialog(
        title: title,
        hintText: hintText,
        actionLabel: 'Add',
        isValidName: isValidName,
        onSubmit: onAdd,
      ),
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
    return showDialog<void>(
      context: context,
      builder: (_) => _ItemNameDialog(
        title: title,
        hintText: hintText,
        actionLabel: 'Rename',
        initialValue: initialValue,
        duplicateNameMessage: duplicateNameMessage,
        messageContext: context,
        isValidName: isValidName,
        onSubmit: onRename,
      ),
    );
  }

  static Future<void> showDeleteItemDialog({
    required BuildContext context,
    required String title,
    required String itemName,
    required ValueChanged<String> onDelete,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Do you really want to delete this item?'),
              const SizedBox(height: 8),
              Tooltip(
                message: itemName,
                child: Text(
                  itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
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

class _ItemNameDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String actionLabel;
  final String initialValue;
  final String? duplicateNameMessage;
  final BuildContext? messageContext;
  final bool Function(String name) isValidName;
  final ValueChanged<String> onSubmit;

  const _ItemNameDialog({
    required this.title,
    required this.hintText,
    required this.actionLabel,
    this.initialValue = '',
    this.duplicateNameMessage,
    this.messageContext,
    required this.isValidName,
    required this.onSubmit,
  });

  @override
  State<_ItemNameDialog> createState() => _ItemNameDialogState();
}

class _ItemNameDialogState extends State<_ItemNameDialog> {
  final _fieldKey = GlobalKey();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  double _lastBottomInset = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialValue.length,
      );
    _focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    if (isLandscape && bottomInset > 0 && bottomInset != _lastBottomInset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fieldContext = _fieldKey.currentContext;
        if (mounted && fieldContext != null) {
          Scrollable.ensureVisible(fieldContext, alignment: 0.5);
        }
      });
    }
    _lastBottomInset = bottomInset;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = NameUtils.clean(_controller.text);
    if (widget.isValidName(name)) {
      widget.onSubmit(name);
      Navigator.of(context).pop();
      return;
    }

    _focusNode.requestFocus();
    final message = widget.duplicateNameMessage;
    if (name.isNotEmpty && message != null) {
      ScaffoldMessenger.of(
        widget.messageContext ?? context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return AlertDialog(
      scrollable: true,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 40,
        vertical: isLandscape ? 8 : 24,
      ),
      title: Text(widget.title),
      content: TextField(
        key: _fieldKey,
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
      actionsOverflowDirection: VerticalDirection.up,
    );
  }
}
