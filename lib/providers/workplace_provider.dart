import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/workplace_datasource.dart';
import '../data/models/workplace.dart';

final workplaceProvider =
    StateNotifierProvider<WorkplaceNotifier, List<Workplace>>((ref) {
  return WorkplaceNotifier();
});

class WorkplaceNotifier extends StateNotifier<List<Workplace>> {
  WorkplaceNotifier() : super([]);

  final _datasource = WorkplaceDatasource();

  Future<void> init() async {
    final data = await _datasource.getAll();
    state = data.map((e) => Workplace.fromJson(e)).toList();
  }

  Future<Workplace> addWorkplace({
    required String name,
    required Color color,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await _datasource.clearDefaultFlag();
    }

    final data = await _datasource.create(
      name: name,
      colorValue: color.toARGB32(),
      isDefault: isDefault,
    );
    final workplace = Workplace.fromJson(data);
    await init();
    return workplace;
  }

  Future<void> updateWorkplace({
    required Workplace workplace,
    required String name,
    required Color color,
    bool? isDefault,
  }) async {
    if (isDefault == true && !workplace.isDefault) {
      await _datasource.clearDefaultFlag();
    }

    await _datasource.update(workplace.id, {
      'name': name,
      'color_value': color.toARGB32(),
      if (isDefault != null) 'is_default': isDefault,
    });

    await init();
  }

  Future<void> deleteWorkplace(Workplace workplace) async {
    await _datasource.delete(workplace.id);
    await init();
  }

  Future<void> setDefault(Workplace workplace) async {
    await _datasource.clearDefaultFlag();
    await _datasource.update(workplace.id, {'is_default': true});
    await init();
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
