import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/portfolio.dart';

/// Raised when the mock API responds with a non-success status.
class PortfolioApiException implements Exception {
  const PortfolioApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves the default mock API base URL for the current platform.
///
/// Android emulators reach the host machine at `10.0.2.2`; every other target
/// (desktop, web) uses `localhost`. Override at build time with
/// `--dart-define=API_BASE_URL=...` when the mock runs on a non-default port.
String get defaultBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:4001';
  }
  return 'http://localhost:4001';
}

/// Fetches portfolio data. Abstract so widget tests can inject a fake.
abstract class PortfolioRepository {
  Future<Portfolio> fetchPortfolio(String portfolioId);
}

/// Talks to the supplied mock API over HTTP.
class HttpPortfolioRepository implements PortfolioRepository {
  HttpPortfolioRepository({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<Portfolio> fetchPortfolio(String portfolioId) async {
    final uri = Uri.parse('$_baseUrl/portfolios/$portfolioId');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw PortfolioApiException(
        'Failed to load portfolio: HTTP ${response.statusCode}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Portfolio.fromJson(body);
  }
}
