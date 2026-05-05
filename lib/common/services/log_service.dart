import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'cloud_config_service.dart';

/// 日志级别
enum LogLevel { debug, info, warning, error }

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🔧';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  String get levelName {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  @override
  String toString() {
    final time = timestamp.toIso8601String();
    return '[$time] [$levelName] [$tag] $message${stackTrace != null ? '\n$stackTrace' : ''}';
  }
}

/// 日志服务
/// 统一管理应用日志，支持查看和导出
class LogService extends GetxService {
  static LogService get to => Get.find();

  /// 日志缓存（内存中保留最近500条）
  final logs = <LogEntry>[].obs;
  File? _logFile;

  /// 最大日志条数
  static const int maxLogs = 500;

  /// 是否启用 debug 日志（生产环境可关闭）
  final enableDebug = true.obs;

  /// 初始化
  Future<LogService> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/app_logs.txt');
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
      info('LogService', '日志服务已初始化，路径: ${_logFile!.path}');
    } catch (e) {
      debugPrint("Failed to init log file: $e");
    }
    return this;
  }

  LogEntry? get latestError {
    for (final entry in logs.reversed) {
      if (entry.level == LogLevel.error) return entry;
    }
    return null;
  }

  /// 记录 Debug 日志
  void debug(String tag, String message) {
    if (!enableDebug.value) return;
    _log(LogLevel.debug, tag, message);
  }

  /// 记录 Info 日志
  void info(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  /// 记录 Warning 日志
  void warning(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }

  /// 记录 Error 日志
  void error(String tag, String message, [StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, stackTrace?.toString());
  }

  /// 内部日志记录方法
  void _log(LogLevel level, String tag, String message, [String? stackTrace]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      stackTrace: stackTrace,
    );

    // 添加到缓存
    logs.add(entry);

    // 限制日志数量
    if (logs.length > maxLogs) {
      logs.removeAt(0);
    }

    final logString = entry.toString();

    // 同时输出到控制台（开发模式）
    if (kDebugMode) {
      debugPrint(logString);
    }

    // 写入文件
    _logFile?.writeAsString('$logString\n', mode: FileMode.append);
  }

  /// 获取所有日志文本
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== LifeLog 应用日志 ===');
    buffer.writeln('导出时间: ${DateTime.now()}');
    buffer.writeln('日志数量: ${logs.length}');
    buffer.writeln(
      '构建模式: ${kReleaseMode
          ? "release"
          : kProfileMode
          ? "profile"
          : "debug"}',
    );
    if (Get.isRegistered<CloudConfigService>()) {
      final cloudConfig = CloudConfigService.to;
      buffer.writeln('云配置: ${cloudConfig.statusLabel}');
      if (cloudConfig.isConfigured.value) {
        buffer.writeln('Supabase URL: ${cloudConfig.supabaseUrl}');
      }
    }
    buffer.writeln('========================\n');

    for (final log in logs) {
      buffer.writeln(log.toString());
    }

    return buffer.toString();
  }

  /// 清空日志
  void clearLogs() {
    logs.clear();
    // 可选：清空文件
    _logFile?.writeAsString('');
    info('LogService', '日志已清空');
  }

  String exportLatestError() {
    final error = latestError;
    return error?.toString() ?? '暂无错误日志';
  }

  String exportDiagnostics() {
    final buffer = StringBuffer();
    buffer.writeln('=== LifeLog 诊断信息 ===');
    buffer.writeln('时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln(
      '构建模式: ${kReleaseMode
          ? "release"
          : kProfileMode
          ? "profile"
          : "debug"}',
    );
    buffer.writeln('日志数量: ${logs.length}');
    if (Get.isRegistered<CloudConfigService>()) {
      final cloudConfig = CloudConfigService.to;
      buffer.writeln('云配置: ${cloudConfig.statusLabel}');
      if (cloudConfig.isConfigured.value) {
        buffer.writeln('Supabase URL: ${cloudConfig.supabaseUrl}');
      }
    }
    buffer.writeln('最近错误:');
    buffer.writeln(exportLatestError());
    return buffer.toString();
  }

  /// 按级别筛选日志
  List<LogEntry> filterByLevel(LogLevel level) {
    return logs.where((log) => log.level == level).toList();
  }
}
