import 'dart:async';
import 'dart:io';

import 'package:bookplayz/api/api_service.dart';

const String kOfflineMessage =
    'No internet connection. Please check your network and try again.';
const String kTimeoutMessage =
    'The request is taking too long. Please try again.';
const String kServerMessage =
    'Something went wrong on our side. Please try again in a moment.';
const String kGenericMessage = 'Something went wrong. Please try again.';

/// True when [e] is a connectivity problem (offline, DNS failure, no route…).
bool isOfflineError(Object e) {
  if (e is SocketException || e is HandshakeException) return true;
  final s = e.toString();
  return s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('Network is unreachable') ||
      s.contains('Connection refused') ||
      s.contains('Connection reset') ||
      s.contains('Connection closed') ||
      s.contains('HandshakeException') ||
      s.contains('XMLHttpRequest error');
}

/// Turns any thrown error into a short message that is safe to show a user —
/// never a raw exception, host name or URL.
String friendlyError(Object e) {
  if (isOfflineError(e)) return kOfflineMessage;
  if (e is TimeoutException) return kTimeoutMessage;

  if (e is ApiException) {
    if (e.statusCode >= 500) return kServerMessage;
    final m = e.message.trim();
    return m.isEmpty ? kGenericMessage : m;
  }

  // Plain `throw Exception('Readable message')` from our own code.
  final s = e.toString();
  if (e.runtimeType.toString() == '_Exception' && s.startsWith('Exception: ')) {
    final m = s.substring('Exception: '.length).trim();
    if (m.isNotEmpty) return m;
  }

  // FormatException, TypeError, etc. — technical, don't expose.
  return kGenericMessage;
}
