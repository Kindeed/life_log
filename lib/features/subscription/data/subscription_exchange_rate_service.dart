import 'dart:convert';
import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:life_log/common/utils/date_utils.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_currency.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_exchange_rates.dart';
import 'package:life_log/features/subscription/domain/services/subscription_exchange_rate_reader.dart';

abstract interface class SubscriptionExchangeRateProvider {
  Future<SubscriptionExchangeRates> load(DateTime now);
}

typedef SubscriptionHttpClientFactory = HttpClient Function();

/// Frankfurter is a public, keyless daily-rate service backed by reference
/// rates. The app never sends subscription amounts or account identifiers.
final class FrankfurterSubscriptionExchangeRateProvider
    implements SubscriptionExchangeRateProvider {
  final SubscriptionHttpClientFactory _httpClientFactory;

  FrankfurterSubscriptionExchangeRateProvider({
    SubscriptionHttpClientFactory? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  @override
  Future<SubscriptionExchangeRates> load(DateTime now) async {
    final client = _httpClientFactory();
    try {
      final request = await client
          .getUrl(Uri.parse('https://api.frankfurter.app/latest?from=CNY'))
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('汇率服务返回 ${response.statusCode}', uri: request.uri);
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('汇率服务响应格式不正确');
      }
      final rawRates = decoded['rates'];
      if (rawRates is! Map) {
        throw const FormatException('汇率服务缺少 rates');
      }

      final rates = <String, double>{'CNY': 1};
      for (final currency in SubscriptionCurrency.values) {
        if (currency == SubscriptionCurrency.cny) continue;
        final value = rawRates[currency.code];
        if (value is num && value > 0) {
          // The endpoint returns foreign-currency units per 1 CNY.
          rates[currency.code] = 1 / value.toDouble();
        }
      }

      final responseDate = DateTime.tryParse(decoded['date']?.toString() ?? '');
      return SubscriptionExchangeRates(
        rateDate: dateOnlyLocal(responseDate ?? now),
        fetchedAt: now,
        cnyPerUnit: Map.unmodifiable(rates),
      );
    } finally {
      client.close(force: true);
    }
  }
}

abstract interface class SubscriptionRateCache {
  Object? read();
  Future<void> write(Object value);
}

final class GetStorageSubscriptionRateCache implements SubscriptionRateCache {
  static const _key = 'subscription_exchange_rates_v1';
  final GetStorage storage;

  const GetStorageSubscriptionRateCache({required this.storage});

  @override
  Object? read() => storage.read<dynamic>(_key);

  @override
  Future<void> write(Object value) => storage.write(_key, value);
}

final class SubscriptionExchangeRateService
    implements SubscriptionExchangeRateReader {
  final SubscriptionExchangeRateProvider _provider;
  final SubscriptionRateCache _cache;

  SubscriptionExchangeRateService({
    required SubscriptionExchangeRateProvider provider,
    required SubscriptionRateCache cache,
  }) : _provider = provider,
       _cache = cache;

  @override
  Future<SubscriptionExchangeRates> load(DateTime now) async {
    final localToday = dateOnlyLocal(now);
    final cached = _readCached();
    if (cached != null && dateOnlyLocal(cached.rateDate) == localToday) {
      return cached;
    }

    try {
      final latest = await _provider.load(now);
      await _cache.write(_encode(latest));
      return latest;
    } catch (_) {
      if (cached != null) {
        return cached.copyWith(
          fromCache: true,
          warning: '今日汇率暂未更新，当前使用 ${formatRateDate(cached.rateDate)} 的汇率',
        );
      }
      return SubscriptionExchangeRates.cnyOnly(
        now,
        warning: '汇率暂不可用，外币订阅暂不计入人民币统计',
      );
    }
  }

  SubscriptionExchangeRates? _readCached() {
    try {
      final raw = _cache.read();
      if (raw is! Map) return null;
      final date = DateTime.tryParse(raw['rateDate']?.toString() ?? '');
      final fetchedAt = DateTime.tryParse(raw['fetchedAt']?.toString() ?? '');
      final rawRates = raw['rates'];
      if (date == null || fetchedAt == null || rawRates is! Map) return null;
      final rates = <String, double>{};
      for (final item in rawRates.entries) {
        final value = item.value;
        if (value is num && value > 0) {
          rates[item.key.toString().toUpperCase()] = value.toDouble();
        }
      }
      if (rates['CNY'] != 1) rates['CNY'] = 1;
      if (rates.length == 1) return null;
      return SubscriptionExchangeRates(
        rateDate: dateOnlyLocal(date),
        fetchedAt: fetchedAt,
        cnyPerUnit: Map.unmodifiable(rates),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _encode(SubscriptionExchangeRates rates) {
    return {
      'rateDate': rates.rateDate.toIso8601String(),
      'fetchedAt': rates.fetchedAt.toIso8601String(),
      'rates': rates.cnyPerUnit,
    };
  }
}

String formatRateDate(DateTime date) {
  final local = dateOnlyLocal(date);
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
