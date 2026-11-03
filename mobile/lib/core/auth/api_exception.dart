import 'dart:convert';
import 'package:http/http.dart' as http;

/// Error raised for any non-2xx API response (API_CONTRACTS.md §1.2) or a
/// transport failure (`code == 'NETWORK'`, `status == 0`).
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;
  final String? issue;
  final List<Map<String, dynamic>> details;

  const ApiException({
    required this.status,
    required this.code,
    this.message = '',
    this.issue,
    this.details = const [],
  });

  const ApiException.network()
      : status = 0,
        code = 'NETWORK',
        message = 'network',
        issue = null,
        details = const [];

  const ApiException.unauthenticated()
      : status = 401,
        code = 'UNAUTHENTICATED',
        message = 'unauthenticated',
        issue = null,
        details = const [];

  bool get isNetwork => code == 'NETWORK';
  bool get isUnauthenticated => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isValidation => status == 422;

  /// Field-level validation messages (never contains PII from our side).
  String? detailFor(String field) {
    for (final d in details) {
      if (d['field'] == field) return d['issue']?.toString();
    }
    return null;
  }

  /// Parses the standard error envelope; tolerates non-JSON bodies.
  factory ApiException.fromResponse(http.Response res) {
    String code = 'INTERNAL';
    String message = '';
    String? issue;
    List<Map<String, dynamic>> details = const [];
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final err = body is Map ? body['error'] : null;
      if (err is Map) {
        code = (err['code'] ?? code).toString();
        message = (err['message'] ?? '').toString();
        final d = err['details'];
        if (d is List) {
          details = d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          if (details.isNotEmpty) issue = details.first['issue']?.toString();
        }
      }
    } catch (_) {
      // keep defaults
    }
    return ApiException(
      status: res.statusCode,
      code: code,
      message: message,
      issue: issue,
      details: details,
    );
  }

  @override
  String toString() => 'ApiException($status $code)'; // no payload: avoid logging sensitive data
}

