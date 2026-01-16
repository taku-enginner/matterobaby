import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import '../../providers/settings_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/sync_provider.dart';
import '../partner/partner_view_screen.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _partnerCodeController = TextEditingController();
  bool _isJoining = false;
  String? _joinError;

  @override
  void dispose() {
    _partnerCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('共有'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 自分のデータを共有するセクション
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.share,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'パートナーと進捗を共有',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '共有コードを使って、パートナーがあなたの出勤状況をリアルタイムで確認できます',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (settings?.shareCode != null) ...[
              Card(
                elevation: 4,
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '共有コード',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          settings!.shareCode!,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: settings.shareCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('コピーしました')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('コピー'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () {
                              _shareProgress(context, settings.shareCode!, progress);
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('シェア'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 同期ボタン
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: syncStatus == SyncStatus.syncing
                              ? null
                              : () => _syncData(),
                          icon: syncStatus == SyncStatus.syncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  syncStatus == SyncStatus.success
                                      ? Icons.check_circle
                                      : Icons.sync,
                                  color: syncStatus == SyncStatus.success
                                      ? Colors.green
                                      : null,
                                ),
                          label: Text(
                            syncStatus == SyncStatus.syncing
                                ? '同期中...'
                                : syncStatus == SyncStatus.success
                                    ? '同期完了'
                                    : 'データを同期',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _generateNewCode(context),
                child: const Text('新しいコードを生成'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => _generateNewCode(context),
                icon: const Icon(Icons.add),
                label: const Text('共有コードを生成'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // パートナーのデータを見るセクション
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.people,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'パートナーの進捗を見る',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'パートナーから共有されたコードを入力して、進捗を確認できます',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _partnerCodeController,
                      decoration: InputDecoration(
                        labelText: '共有コード',
                        hintText: 'BABY-2026-XXXX',
                        border: const OutlineInputBorder(),
                        errorText: _joinError,
                        prefixIcon: const Icon(Icons.vpn_key),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isJoining ? null : _joinPartner,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        icon: _isJoining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.visibility),
                        label: Text(_isJoining ? '確認中...' : 'パートナーの進捗を見る'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '使い方',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep(context, '1', '共有コードを生成して「データを同期」'),
                    _buildStep(context, '2', 'コードをパートナーにシェア'),
                    _buildStep(context, '3', 'パートナーはコードを入力して進捗を確認'),
                    const SizedBox(height: 8),
                    Text(
                      '※ 出勤を記録したら「データを同期」を押してください',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _generateNewCode(BuildContext context) async {
    final code = _generateShareCode();
    await ref.read(settingsProvider.notifier).setShareCode(code);

    // 自動で同期
    await _syncData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('共有コードを生成・同期しました')),
      );
    }
  }

  String _generateShareCode() {
    final year = DateTime.now().year;
    final random = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'BABY-$year-$suffix';
  }

  Future<void> _syncData() async {
    final syncAction = ref.read(syncActionProvider);
    final success = await syncAction.syncToFirestore();

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データを同期しました')),
      );
    }
  }

  Future<void> _joinPartner() async {
    final code = _partnerCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _joinError = 'コードを入力してください';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _joinError = null;
    });

    try {
      final syncAction = ref.read(syncActionProvider);
      final exists = await syncAction.validateShareCode(code);

      if (!exists) {
        setState(() {
          _joinError = 'このコードは見つかりませんでした';
          _isJoining = false;
        });
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartnerViewScreen(shareCode: code),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _joinError = 'エラーが発生しました';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _shareProgress(BuildContext context, String code, ProgressData? progress) {
    String message = '出勤カウントの進捗を共有します\n\n';
    message += '共有コード: $code\n';
    if (progress != null) {
      message += '\n現在の進捗: ${progress.qualifyingMonths}/12ヶ月達成';
    }
    message += '\n\nこのコードをアプリの「共有」タブで入力すると進捗を確認できます';
    Share.share(message);
  }
}
