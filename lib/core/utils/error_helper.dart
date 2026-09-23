import 'dart:io';
import 'package:dio/dio.dart';

/// Human-friendly message for UI.
String friendlyError(Object e) {
  if (e is DioException) {
    final msg = e.response?.data?['message'];
    if (msg is String) return msg;
    if (msg is List && msg.isNotEmpty) return msg.first.toString();

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Cannot reach server (timeout). Is the backend running?';
      case DioExceptionType.sendTimeout:
        return 'Sending data timed out. Check your connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.transformTimeout:
        return 'Processing the response timed out.';
      case DioExceptionType.badCertificate:
        return 'HTTPS certificate error.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection refused. Check host/port (10.0.2.2 for Android emulator).';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return "You don't have permission.";
      case 404:
        return 'Not found';
      case 429:
        return 'Too many requests. Try again in a minute.';
      case 500:
        return 'Server error. Try again later.';
    }

    // Fall through — show raw type so you can debug
    return 'Network error (${e.type.name}). Check your connection.';
  }
  return e.toString();
}

/// Detailed debug string — use this in logs, NOT in the UI.
String debugDioError(DioException e) {
  final b = StringBuffer()
    ..writeln('DioException: ${e.type.name}')
    ..writeln('message   : ${e.message}')
    ..writeln('uri       : ${e.requestOptions.uri}')
    ..writeln('method    : ${e.requestOptions.method}')
    ..writeln('baseUrl   : ${e.requestOptions.baseUrl}')
    ..writeln('path      : ${e.requestOptions.path}');

  if (e.error is SocketException) {
    final se = e.error as SocketException;
    b
      ..writeln('SocketException:')
      ..writeln('  message: ${se.message}')
      ..writeln('  osError: ${se.osError?.message}');
  } else if (e.error != null) {
    b.writeln('error     : ${e.error}');
  }

  if (e.response != null) {
    b
      ..writeln('status    : ${e.response!.statusCode}')
      ..writeln('body      : ${e.response!.data}');
  }
  return b.toString();
}
