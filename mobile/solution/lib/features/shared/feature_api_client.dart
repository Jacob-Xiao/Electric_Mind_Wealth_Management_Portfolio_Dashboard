import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../accounts/account.dart';
import '../holding_detail/holding_detail.dart';

/// Where the mock API lives. Override with
/// `--dart-define=API_BASE_URL=http://192.168.1.20:4001` for a physical device
/// and `--dart-define=MOCK_SCENARIO=large` to pick a mock scenario.
class FeatureApiConfig {
  const FeatureApiConfig({required this.baseUrl, this.scenario = 'default'});

  factory FeatureApiConfig.fromEnvironment() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    const scenario =
        String.fromEnvironment('MOCK_SCENARIO', defaultValue: 'default');
    if (fromDefine.isNotEmpty) {
      return const FeatureApiConfig(baseUrl: fromDefine, scenario: scenario);
    }
    // The Android emulator reaches the host machine at 10.0.2.2.
    final isAndroid = !kIsWeb && Platform.isAndroid;
    return FeatureApiConfig(
      baseUrl: isAndroid ? 'http://10.0.2.2:4001' : 'http://127.0.0.1:4001',
      scenario: scenario,
    );
  }

  final String baseUrl;
  final String scenario;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// HTTP client for the endpoints Tasks 5–10 need (`/accounts`,
/// `/holdings/{ticker}/detail`, `/notification`).
///
/// Portfolio fetching/caching belongs to Tasks 2–4; [getPortfolioJson] exists
/// only so the standalone demo entrypoint can run before the merge.
class FeatureApiClient {
  FeatureApiClient({
    required this.config,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _http = httpClient ?? http.Client();

  final FeatureApiConfig config;
  final Duration timeout;
  final http.Client _http;

  Future<List<Account>> getAccounts() async {
    final json = await _get('/accounts');
    if (json is! List) {
      throw const ApiException('Unexpected /accounts response');
    }
    return json
        .whereType<Map<String, dynamic>>()
        .map(Account.fromJson)
        .toList(growable: false);
  }

  Future<HoldingDetail> getHoldingDetail(String ticker) async {
    final json =
        await _get('/holdings/${Uri.encodeComponent(ticker)}/detail');
    if (json is! Map<String, dynamic>) {
      throw const ApiException('Unexpected holding detail response');
    }
    return HoldingDetail.fromJson(json);
  }

  Future<Map<String, dynamic>> getNotificationExample() async {
    final json = await _get('/notification');
    if (json is! Map<String, dynamic>) {
      throw const ApiException('Unexpected /notification response');
    }
    return json;
  }

  /// Demo-only. Replace with the Task 2–4 repository after the merge.
  Future<Map<String, dynamic>> getPortfolioJson(String portfolioId) async {
    final json = await _get('/portfolios/${Uri.encodeComponent(portfolioId)}');
    if (json is! Map<String, dynamic>) {
      throw const ApiException('Unexpected portfolio response');
    }
    return json;
  }

  Future<Object?> _get(String path) async {
    final uri = Uri.parse('${config.baseUrl}$path')
        .replace(queryParameters: {'scenario': config.scenario});
    final http.Response response;
    try {
      response = await _http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('The request timed out.');
    } catch (e) {
      throw ApiException('Could not reach the server ($e).');
    }

    Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final error = body is Map<String, dynamic> ? body : const {};
    throw ApiException(
      (error['message'] as String?) ?? 'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
      code: error['error'] as String?,
    );
  }

  void close() => _http.close();
}
