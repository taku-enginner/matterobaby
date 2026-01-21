import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/reward.dart';
import '../../../providers/reward_provider.dart';
import 'reward_card.dart';
import 'reward_form_sheet.dart';

class RewardListSection extends ConsumerWidget {
  const RewardListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final rewards = ref.watch(rewardProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ごほうびリスト',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAddSheet(context, ref),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('追加'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (rewards.isEmpty)
          _buildEmptyState(context, colorScheme, ref)
        else
          ...rewards.map((reward) => RewardCard(
                reward: reward,
                onEdit: () => _showEditSheet(context, ref, reward),
                onDelete: () => _showDeleteDialog(context, ref, reward),
              )),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ColorScheme colorScheme, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'ごほうびを登録しよう',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'くじで当たるごほうびを\n追加してください',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('ごほうびを追加'),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RewardFormSheet(
        onSave: (name, memo, imagePath) {
          ref.read(rewardProvider.notifier).addReward(
                name: name,
                memo: memo,
                imagePath: imagePath,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ごほうびを追加しました')),
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Reward reward) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RewardFormSheet(
        reward: reward,
        onSave: (name, memo, imagePath) {
          ref.read(rewardProvider.notifier).updateReward(
                reward: reward,
                name: name,
                memo: memo,
                imagePath: imagePath,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ごほうびを更新しました')),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${reward.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(rewardProvider.notifier).deleteReward(reward);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ごほうびを削除しました')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
