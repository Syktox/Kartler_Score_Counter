import 'package:flutter/material.dart';

typedef CounterNameCallback = void Function(String counterName);
typedef ReorderItemsCallback = void Function(int oldIndex, int newIndex);

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

  Widget _buildCounterTile(BuildContext context, String counter, int index) {
    final isSelected = counter == selectedItem;

    return Container(
      key: ValueKey(counter),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.08),
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
                onPressed: () => onRenameItem!(counter),
                tooltip: 'Rename item',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onDeleteItem(counter),
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        top: true,
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: DragBoundary(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    dragBoundaryProvider: DragBoundary.forRectOf,
                    proxyDecorator: _buildReorderProxy,
                    itemCount: items.length + 1,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex == items.length || newIndex > items.length) {
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
                          leading: Icon(addButtonIcon),
                          title: Text(addButtonLabel),
                          onTap: () {
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
              ),
            ),
            Material(
              key: const ValueKey('drawer-settings-footer'),
              color:
                  Theme.of(context).drawerTheme.backgroundColor ??
                  Theme.of(context).canvasColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.of(context).pop();
                        onOpenSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
