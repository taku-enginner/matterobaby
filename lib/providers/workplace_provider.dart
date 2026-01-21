import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/workplace.dart';

final workplaceProvider =
    StateNotifierProvider<WorkplaceNotifier, List<Workplace>>((ref) {
  return WorkplaceNotifier();
});

class WorkplaceNotifier extends StateNotifier<List<Workplace>> {
  WorkplaceNotifier() : super([]);

  Box<Workplace>? _box;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<Workplace>(AppConstants.workplaceBoxName);
    state = _box!.values.toList();
  }

  Future<Workplace> addWorkplace({
    required String name,
    required Color color,
    bool isDefault = false,
  }) async {
    // 新しいデフォルトを追加する場合、既存のデフォルトを解除
    if (isDefault) {
      await _clearDefaultFlag();
    }

    final workplace = Workplace(
      id: _uuid.v4(),
      name: name,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
      isDefault: isDefault,
    );
    await _box?.add(workplace);
    state = _box!.values.toList();
    return workplace;
  }

  Future<void> updateWorkplace({
    required Workplace workplace,
    required String name,
    required Color color,
    bool? isDefault,
  }) async {
    // 新しいデフォルトを設定する場合、既存のデフォルトを解除
    if (isDefault == true && !workplace.isDefault) {
      await _clearDefaultFlag();
    }

    final updated = workplace.copyWith(
      name: name,
      colorValue: color.toARGB32(),
      isDefault: isDefault,
    );

    final index =
        _box!.values.toList().indexWhere((w) => w.id == workplace.id);
    if (index != -1) {
      await _box!.putAt(index, updated);
    }

    state = _box!.values.toList();
  }

  Future<void> deleteWorkplace(Workplace workplace) async {
    final index =
        _box!.values.toList().indexWhere((w) => w.id == workplace.id);
    if (index != -1) {
      await _box!.deleteAt(index);
    }
    state = _box!.values.toList();
  }

  Future<void> setDefault(Workplace workplace) async {
    await _clearDefaultFlag();

    final updated = workplace.copyWith(isDefault: true);
    final index =
        _box!.values.toList().indexWhere((w) => w.id == workplace.id);
    if (index != -1) {
      await _box!.putAt(index, updated);
    }

    state = _box!.values.toList();
  }

  Future<void> _clearDefaultFlag() async {
    final workplaces = _box!.values.toList();
    for (var i = 0; i < workplaces.length; i++) {
      if (workplaces[i].isDefault) {
        await _box!.putAt(i, workplaces[i].copyWith(isDefault: false));
      }
    }
  }

  Workplace? getWorkplaceById(String? id) {
    if (id == null) return null;
    try {
      return state.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  Workplace? get defaultWorkplace {
    try {
      return state.firstWhere((w) => w.isDefault);
    } catch (_) {
      return state.isNotEmpty ? state.first : null;
    }
  }
}
