import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/workspace.dart';
import '../../workspace/notifiers/workspace_notifier.dart';
import '../notifiers/ai_assistant_notifier.dart';

/// Search scope selector for AI assistant
/// Allows users to select which workspaces to search
/// Requirements: 7.3
class SearchScopeSelector extends ConsumerStatefulWidget {
  const SearchScopeSelector({super.key});

  @override
  ConsumerState<SearchScopeSelector> createState() =>
      _SearchScopeSelectorState();
}

class _SearchScopeSelectorState extends ConsumerState<SearchScopeSelector> {
  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAssistantProvider);
    final workspaceState = ref.watch(workspaceProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.search,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '搜索范围:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        _buildScopeDropdown(context, aiState, workspaceState),
        if (aiState.searchScope == SearchScope.selectedWorkspaces) ...[
          const SizedBox(width: 8),
          _buildWorkspaceChips(context, aiState, workspaceState),
        ],
      ],
    );
  }

  Widget _buildScopeDropdown(
    BuildContext context,
    AIAssistantState aiState,
    WorkspaceState workspaceState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SearchScope>(
          value: aiState.searchScope,
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          items: [
            DropdownMenuItem(
              value: SearchScope.currentWorkspace,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder, size: 14),
                  const SizedBox(width: 6),
                  Text(_getCurrentWorkspaceName(workspaceState)),
                ],
              ),
            ),
            const DropdownMenuItem(
              value: SearchScope.selectedWorkspaces,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_copy, size: 14),
                  SizedBox(width: 6),
                  Text('选择工作空间'),
                ],
              ),
            ),
            const DropdownMenuItem(
              value: SearchScope.allWorkspaces,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.all_inbox, size: 14),
                  SizedBox(width: 6),
                  Text('所有工作空间'),
                ],
              ),
            ),
          ],
          onChanged: (scope) {
            if (scope != null) {
              if (scope == SearchScope.selectedWorkspaces) {
                _showWorkspaceSelector(context, workspaceState);
              } else {
                ref.read(aiAssistantProvider.notifier).setSearchScope(scope);
              }
            }
          },
        ),
      ),
    );
  }

  String _getCurrentWorkspaceName(WorkspaceState state) {
    return state.currentWorkspace?.name ?? '当前工作空间';
  }

  Widget _buildWorkspaceChips(
    BuildContext context,
    AIAssistantState aiState,
    WorkspaceState workspaceState,
  ) {
    if (aiState.selectedWorkspaceIds.isEmpty) {
      return TextButton.icon(
        onPressed: () => _showWorkspaceSelector(context, workspaceState),
        icon: const Icon(Icons.add, size: 14),
        label: const Text('选择', style: TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
        ),
      );
    }

    return Flexible(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...aiState.selectedWorkspaceIds.take(3).map((id) {
              final workspace = workspaceState.workspaces
                  .cast<Workspace?>()
                  .firstWhere((w) => w?.uuid == id, orElse: () => null);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  label: Text(
                    workspace?.name ?? id.substring(0, 8),
                    style: const TextStyle(fontSize: 10),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 12),
                  onDeleted: () {
                    final newIds =
                        List<String>.from(aiState.selectedWorkspaceIds)
                          ..remove(id);
                    if (newIds.isEmpty) {
                      ref
                          .read(aiAssistantProvider.notifier)
                          .setSearchScope(SearchScope.currentWorkspace);
                    } else {
                      ref
                          .read(aiAssistantProvider.notifier)
                          .setSelectedWorkspaces(newIds);
                    }
                  },
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
            if (aiState.selectedWorkspaceIds.length > 3)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '+${aiState.selectedWorkspaceIds.length - 3}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 14),
              onPressed: () => _showWorkspaceSelector(context, workspaceState),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: '编辑选择',
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkspaceSelector(
    BuildContext context,
    WorkspaceState workspaceState,
  ) {
    final aiState = ref.read(aiAssistantProvider);
    final selectedIds = Set<String>.from(aiState.selectedWorkspaceIds);

    showDialog(
      context: context,
      builder: (context) => WorkspaceSelectorDialog(
        workspaces: workspaceState.workspaces,
        selectedIds: selectedIds,
        onConfirm: (ids) {
          if (ids.isEmpty) {
            ref
                .read(aiAssistantProvider.notifier)
                .setSearchScope(SearchScope.currentWorkspace);
          } else {
            ref.read(aiAssistantProvider.notifier).setSelectedWorkspaces(ids);
          }
        },
      ),
    );
  }
}

/// Dialog for selecting multiple workspaces
class WorkspaceSelectorDialog extends StatefulWidget {
  final List<Workspace> workspaces;
  final Set<String> selectedIds;
  final void Function(List<String>) onConfirm;

  const WorkspaceSelectorDialog({
    super.key,
    required this.workspaces,
    required this.selectedIds,
    required this.onConfirm,
  });

  @override
  State<WorkspaceSelectorDialog> createState() =>
      _WorkspaceSelectorDialogState();
}

class _WorkspaceSelectorDialogState extends State<WorkspaceSelectorDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择工作空间'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: widget.workspaces.isEmpty
            ? const Center(child: Text('没有可用的工作空间'))
            : ListView.builder(
                itemCount: widget.workspaces.length,
                itemBuilder: (context, index) {
                  final workspace = widget.workspaces[index];
                  final isSelected = _selectedIds.contains(workspace.uuid);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(workspace.uuid);
                        } else {
                          _selectedIds.remove(workspace.uuid);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        if (workspace.icon != null) ...[
                          Text(workspace.icon!,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            workspace.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: workspace.description != null
                        ? Text(
                            workspace.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    dense: true,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              if (_selectedIds.length == widget.workspaces.length) {
                _selectedIds.clear();
              } else {
                _selectedIds = widget.workspaces.map((w) => w.uuid).toSet();
              }
            });
          },
          child: Text(
            _selectedIds.length == widget.workspaces.length ? '取消全选' : '全选',
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_selectedIds.toList());
            Navigator.of(context).pop();
          },
          child: Text('确定 (${_selectedIds.length})'),
        ),
      ],
    );
  }
}
