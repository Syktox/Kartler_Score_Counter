import 'package:flutter/material.dart';

typedef CounterNameCallback = void Function(String counterName);
typedef ReorderItemsCallback = void Function(int oldIndex, int newIndex);

const double _settingsFooterHeight = 80;

class CounterDrawer extends StatelessWidget {
  final List<String> items;
  final String selectedItem;
  final String addButtonLabel;
  final IconData addButtonIcon;
  final bool closeDrawerOnAdd;
  final bool enableReorder;
  final VoidCallback onAddNewItem;
  final CounterNameCallback onSelectItem;
  final CounterNameCallback? onRenameItem;
  final CounterNameCallback onDeleteItem;
  final ReorderItemsCallback? onReorderItems;
  final VoidCallback onOpenSettings;

  const CounterDrawer({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.addButtonLabel,
    required this.addButtonIcon,
    this.closeDrawerOnAdd = true,
    this.enableReorder = false,
    required this.onAddNewItem,
    required this.onSelectItem,
    required this.onRenameItem,
    required this.onDeleteItem,
    this.onReorderItems,
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
                tooltip: 'Rename item',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _clearDrawerFocus();
                onDeleteItem(counter);
              },
              tooltip: 'Delete item',
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
    return ClipRect(
      child: DragBoundary(
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          dragBoundaryProvider: DragBoundary.forRectOf,
          padding: const EdgeInsets.only(bottom: _settingsFooterHeight),
          proxyDecorator: _buildReorderProxy,
          itemCount: items.length + 1,
          onReorderItem: (oldIndex, newIndex) {
            if (oldIndex == items.length || newIndex >= items.length) {
              return;
            }
            if (enableReorder && onReorderItems != null) {
              onReorderItems!(oldIndex, newIndex);
            }
          },
          itemBuilder: (context, index) {
            if (index == items.length) {
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

            return _buildCounterTile(context, items[index], index);
          },
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
                title: const Text('Settings'),
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

    return Drawer(
      backgroundColor: drawerBackgroundColor,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: _settingsFooterHeight,
              child: _buildItemList(),
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
