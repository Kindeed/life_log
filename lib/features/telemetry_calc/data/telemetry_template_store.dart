import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import 'package:life_log/features/telemetry_calc/domain/telemetry_calculators.dart';

class TelemetryTemplate {
  final String id;
  final String calculatorId;
  final String name;
  final DateTime updatedAt;
  final Map<String, TelemetryInputValue> values;

  const TelemetryTemplate({
    required this.id,
    required this.calculatorId,
    required this.name,
    required this.updatedAt,
    required this.values,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'calculatorId': calculatorId,
    'name': name,
    'updatedAt': updatedAt.toIso8601String(),
    'values': values.map((key, value) => MapEntry(key, value.toJson())),
  };

  factory TelemetryTemplate.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as Map? ?? {};
    return TelemetryTemplate(
      id: json['id'] as String? ?? '',
      calculatorId: json['calculatorId'] as String? ?? '',
      name: json['name'] as String? ?? '未命名模板',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      values: rawValues.map(
        (key, value) => MapEntry(
          key.toString(),
          TelemetryInputValue.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }
}

class TelemetryTemplateStore {
  static const _storageKey = 'telemetry_calc_templates_v1';

  final GetStorage _storage;

  TelemetryTemplateStore({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  List<TelemetryTemplate> loadTemplates(String calculatorId) {
    return _loadAll()
        .where((template) => template.calculatorId == calculatorId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<TelemetryTemplate> loadRecent({int limit = 3}) {
    return _loadAll().take(limit).toList();
  }

  Future<void> saveTemplate(
    String calculatorId,
    String name,
    Map<String, TelemetryInputValue> values,
  ) async {
    final templates = _loadAll();
    final id = '${calculatorId}_${DateTime.now().microsecondsSinceEpoch}';
    templates.removeWhere(
      (template) =>
          template.calculatorId == calculatorId &&
          template.name.trim() == name.trim(),
    );
    templates.add(
      TelemetryTemplate(
        id: id,
        calculatorId: calculatorId,
        name: name.trim().isEmpty ? '未命名模板' : name.trim(),
        updatedAt: DateTime.now(),
        values: Map.of(values),
      ),
    );
    await _saveAll(templates);
  }

  Future<void> deleteTemplate(String templateId) async {
    final templates = _loadAll()
      ..removeWhere((template) => template.id == templateId);
    await _saveAll(templates);
  }

  Future<void> renameTemplate(String templateId, String name) async {
    final templates = _loadAll();
    final index = templates.indexWhere((template) => template.id == templateId);
    if (index == -1) return;
    final template = templates[index];
    templates[index] = TelemetryTemplate(
      id: template.id,
      calculatorId: template.calculatorId,
      name: name.trim().isEmpty ? '未命名模板' : name.trim(),
      updatedAt: DateTime.now(),
      values: template.values,
    );
    await _saveAll(templates);
  }

  List<TelemetryTemplate> _loadAll() {
    final raw = _storage.read<String>(_storageKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (json) =>
                TelemetryTemplate.fromJson(Map<String, dynamic>.from(json)),
          )
          .where((template) => template.id.isNotEmpty)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } on Object {
      return [];
    }
  }

  Future<void> _saveAll(List<TelemetryTemplate> templates) {
    final encoded = jsonEncode(
      templates.map((template) => template.toJson()).toList(growable: false),
    );
    return _storage.write(_storageKey, encoded);
  }
}
