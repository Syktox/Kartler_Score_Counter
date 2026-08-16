import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/name_utils.dart';

class AppDialogs {
  const AppDialogs._();

  static OverlayEntry? _currentErrorBubble;

  static void showErrorBubble(BuildContext context, String message) {
    showErrorBubbleWithConfig(
      overlay: Overlay.of(context, rootOverlay: true),
      colorScheme: Theme.of(context).colorScheme,
      message: message,
    );
  }

  static void showErrorBubbleWithConfig({
    required OverlayState overlay,
    required ColorScheme colorScheme,
    required String message,
  }) {
    _currentErrorBubble?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _ErrorBubble(
        colorScheme: colorScheme,
        message: message,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
          if (identical(_currentErrorBubble, entry)) {
            _currentErrorBubble = null;
          }
        },
      ),
    );
    _currentErrorBubble = entry;
    overlay.insert(entry);
  }

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
        actionLabel: 'Hinzufügen',
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
        actionLabel: 'Umbenennen',
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
              const Text('Möchtest du das wirklich löschen?'),
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
              child: const Text('Abbrechen'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () {
                onDelete(itemName);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Löschen'),
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
      AppDialogs.showErrorBubble(
        widget.messageContext ?? context,
        message,
      );
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
          child: const Text('Abbrechen'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
      actionsOverflowDirection: VerticalDirection.up,
    );
  }
}

class _ErrorBubble extends StatefulWidget {
  final ColorScheme colorScheme;
  final String message;
  final VoidCallback onDismissed;

  const _ErrorBubble({
    required this.colorScheme,
    required this.message,
    required this.onDismissed,
  });

  @override
  State<_ErrorBubble> createState() => _ErrorBubbleState();
}

class _ErrorBubbleState extends State<_ErrorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_opacity);
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 3200), () {
      _controller.reverse().whenCompleteOrCancel(widget.onDismissed);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Positioned(
      left: 24,
      right: 24,
      bottom: height * 0.30,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Material(
                  color: widget.colorScheme.surface,
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: widget.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
