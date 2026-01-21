import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workplace.dart';
import '../../providers/workplace_provider.dart';

class WorkplaceManagementScreen extends ConsumerWidget {
  const WorkplaceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workplaces = ref.watch(workplaceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('勤務先管理'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: workplaces.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '勤務先を登録してください',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: workplaces.length,
              itemBuilder: (context, index) {
                final workplace = workplaces[index];
                return _WorkplaceListTile(workplace: workplace);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWorkplaceDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
    );
  }

  void _showWorkplaceDialog(BuildContext context, WidgetRef ref,
      [Workplace? workplace]) {
    showDialog(
      context: context,
      builder: (context) => _WorkplaceDialog(workplace: workplace),
    );
  }
}

class _WorkplaceListTile extends ConsumerWidget {
  final Workplace workplace;

  const _WorkplaceListTile({required this.workplace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final workplaceColor = Color(workplace.colorValue);

    return Dismissible(
      key: Key(workplace.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('削除確認'),
            content: Text('「${workplace.name}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('削除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(workplaceProvider.notifier).deleteWorkplace(workplace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${workplace.name}」を削除しました')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: workplaceColor,
          child: workplace.isDefault
              ? const Icon(Icons.star, color: Colors.white, size: 20)
              : null,
        ),
        title: Text(workplace.name),
        subtitle: workplace.isDefault
            ? Text(
                'デフォルト',
                style: TextStyle(color: colorScheme.primary),
              )
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                showDialog(
                  context: context,
                  builder: (context) => _WorkplaceDialog(workplace: workplace),
                );
                break;
              case 'default':
                ref.read(workplaceProvider.notifier).setDefault(workplace);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${workplace.name}」をデフォルトに設定しました')),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('編集'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!workplace.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: ListTile(
                  leading: Icon(Icons.star),
                  title: Text('デフォルトに設定'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkplaceDialog extends ConsumerStatefulWidget {
  final Workplace? workplace;

  const _WorkplaceDialog({this.workplace});

  @override
  ConsumerState<_WorkplaceDialog> createState() => _WorkplaceDialogState();
}

class _WorkplaceDialogState extends ConsumerState<_WorkplaceDialog> {
  late final TextEditingController _nameController;
  late Color _selectedColor;
  late bool _isDefault;

  static const _colors = [
    Color(0xFFE57373), // Red
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFFFFB74D), // Orange
    Color(0xFFFFD54F), // Amber
    Color(0xFFAED581), // Light Green
    Color(0xFF81C784), // Green
    Color(0xFF4DD0E1), // Cyan
    Color(0xFF64B5F6), // Blue
    Color(0xFF7986CB), // Indigo
    Color(0xFFBA68C8), // Purple
    Color(0xFFF06292), // Pink
    Color(0xFF90A4AE), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workplace?.name ?? '');
    _selectedColor = widget.workplace != null
        ? Color(widget.workplace!.colorValue)
        : _colors.first;
    _isDefault = widget.workplace?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.workplace != null;
    final workplaces = ref.watch(workplaceProvider);

    return AlertDialog(
      title: Text(isEditing ? '勤務先を編集' : '勤務先を追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '勤務先名',
                hintText: '例：カフェA、オフィスB',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text(
              '色',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            if (workplaces.isEmpty || (isEditing && workplaces.length == 1)) ...[
              const SizedBox(height: 16),
              Text(
                'この勤務先がデフォルトになります',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value ?? false),
                title: const Text('デフォルトに設定'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _save,
          child: Text(isEditing ? '保存' : '追加'),
        ),
      ],
    );
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(workplaceProvider.notifier);
    final workplaces = ref.read(workplaceProvider);
    final shouldBeDefault =
        _isDefault || workplaces.isEmpty || (widget.workplace != null && workplaces.length == 1);

    if (widget.workplace != null) {
      await notifier.updateWorkplace(
        workplace: widget.workplace!,
        name: name,
        color: _selectedColor,
        isDefault: shouldBeDefault,
      );
    } else {
      await notifier.addWorkplace(
        name: name,
        color: _selectedColor,
        isDefault: shouldBeDefault,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
