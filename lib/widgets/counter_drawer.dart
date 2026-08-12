import 'package:flutter/material.dart';

typedef CounterNameCallback = void Function(String counterName);
typedef ReorderItemsCallback = void Function(int oldIndex, int newIndex);

const double _settingsFooterHeight = 80;
const double _extraActionTileHeight = 56;

class CounterDrawer extends StatelessWidget {
  final List<String> items;
  final String selectedItem;
  final String addButtonLabel;
  final IconData addButtonIcon;
  final bool closeDrawerOnAdd;
  final bool enableReorder;
  final bool showAddButton;
  final VoidCallback onAddNewItem;
  final String? secondaryActionLabel;
  final String? secondaryActionSubtitle;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final CounterNameCallback onSelectItem;
  final CounterNameCallback? onRenameItem;
  final CounterNameCallback onDeleteItem;
  final ReorderItemsCallback? onReorderItems;
  final List<Widget> extraActions;
  final bool pinExtraActions;
  final VoidCallback onOpenSettings;

  const CounterDrawer({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.addButtonLabel,
    required this.addButtonIcon,
    this.closeDrawerOnAdd = true,
    this.enableReorder = false,
    this.showAddButton = true,
    required this.onAddNewItem,
    this.secondaryActionLabel,
    this.secondaryActionSubtitle,
    this.secondaryActionIcon,
    this.onSecondaryAction,
    required this.onSelectItem,
    required this.onRenameItem,
    required this.onDeleteItem,
    this.onReorderItems,
    this.extraActions = const [],
    this.pinExtraActions = true,
    required this.onOpenSettings,
  });

  void _clearDrawerFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _buildCounterTile(BuildContext context, String counter, int index) {
    return Container(
      key: ValueKey(counter),
      child: ListTile(
        focusColor: Colors.transparent,
        title: Tooltip(
          message: counter,
          child: Text(counter, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRenameItem != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _clearDrawerFocus();
                  onRenameItem!(counter);
                },
                tooltip: 'Umbenennen',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _clearDrawerFocus();
                onDeleteItem(counter);
              },
              tooltip: 'Löschen',
            ),
            if (enableReorder)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.drag_handle),
                ),
              ),
          ],
        ),
        onTap: () {
          _clearDrawerFocus();
          onSelectItem(counter);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildReorderProxy(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return ClipRect(
      key: const ValueKey('drawer-reorder-proxy'),
      child: Material(
        key: const ValueKey('drawer-reorder-proxy-material'),
        elevation: 0,
        child: child,
      ),
    );
  }

  Widget _buildItemList() {
    final includeExtraInList = !pinExtraActions;
    final hasSecondaryAction = onSecondaryAction != null;
    final leadingTiles = (showAddButton ? 1 : 0) + (hasSecondaryAction ? 1 : 0);

    return ClipRect(
      child: DragBoundary(
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          dragBoundaryProvider: DragBoundary.forRectOf,
          padding: EdgeInsets.only(
            bottom: includeExtraInList ? _settingsFooterHeight : 16,
          ),
          proxyDecorator: _buildReorderProxy,
          itemCount:
              items.length +
              leadingTiles +
              (includeExtraInList ? extraActions.length : 0),
          onReorderItem: (oldIndex, newIndex) {
            if (oldIndex >= items.length || newIndex >= items.length) {
              return;
            }
            if (enableReorder && onReorderItems != null) {
              onReorderItems!(oldIndex, newIndex);
            }
          },
          itemBuilder: (context, index) {
            if (showAddButton && index == items.length) {
              return ListTile(
                key: const ValueKey('add-item-tile'),
                focusColor: Colors.transparent,
                leading: Icon(addButtonIcon),
                title: Text(addButtonLabel),
                onTap: () {
                  _clearDrawerFocus();
                  if (closeDrawerOnAdd) {
                    Navigator.of(context).pop();
                  }
                  onAddNewItem();
                },
              );
            }

            if (hasSecondaryAction &&
                index == items.length + (showAddButton ? 1 : 0)) {
              return ListTile(
                key: const ValueKey('secondary-action-tile'),
                focusColor: Colors.transparent,
                leading: Icon(secondaryActionIcon),
                title: Text(secondaryActionLabel!),
                subtitle: secondaryActionSubtitle == null
                    ? null
                    : Text(secondaryActionSubtitle!),
                onTap: () {
                  _clearDrawerFocus();
                  Navigator.of(context).pop();
                  onSecondaryAction!();
                },
              );
            }

            if (includeExtraInList) {
              final extraIndex = index - items.length - leadingTiles;
              if (extraIndex >= 0 && extraIndex < extraActions.length) {
                return KeyedSubtree(
                  key: ValueKey('drawer-extra-action-$extraIndex'),
                  child: extraActions[extraIndex],
                );
              }
            }

            return _buildCounterTile(context, items[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildExtraActionsBlock(BuildContext context) {
    final drawerBackgroundColor =
        DrawerTheme.of(context).backgroundColor ??
        Theme.of(context).colorScheme.surface;

    return KeyedSubtree(
      key: const ValueKey('drawer-extra-actions'),
      child: Material(
        color: drawerBackgroundColor,
        elevation: 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            for (var i = 0; i < extraActions.length; i++)
              KeyedSubtree(
                key: ValueKey('drawer-extra-action-$i'),
                child: extraActions[i],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsFooter(BuildContext context) {
    final drawerBackgroundColor =
        DrawerTheme.of(context).backgroundColor ??
        Theme.of(context).colorScheme.surface;

    return KeyedSubtree(
      key: const ValueKey('drawer-settings-footer'),
      child: Material(
        color: drawerBackgroundColor,
        elevation: 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            SizedBox(
              height: _settingsFooterHeight - 1,
              child: ListTile(
                focusColor: Colors.transparent,
                leading: const Icon(Icons.settings),
                title: const Text('Einstellungen'),
                onTap: () {
                  _clearDrawerFocus();
                  Navigator.of(context).pop();
                  onOpenSettings();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerBackgroundColor =
        DrawerTheme.of(context).backgroundColor ??
        Theme.of(context).colorScheme.surface;
    final extraActionsHeight = pinExtraActions
        ? extraActions.length * _extraActionTileHeight
        : 0.0;

    return Drawer(
      backgroundColor: drawerBackgroundColor,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: extraActionsHeight + _settingsFooterHeight,
              child: _buildItemList(),
            ),
            if (pinExtraActions && extraActions.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: _settingsFooterHeight,
                child: _buildExtraActionsBlock(context),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSettingsFooter(context),
            ),
          ],
        ),
      ),
    );
  }
}
