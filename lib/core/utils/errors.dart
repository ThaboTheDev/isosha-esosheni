import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

const String connectionMessage = 'Check your connection and try again.';

/// RPC error copy comes straight from the backend — those messages are
/// written for members ("You have reached today's limit of 20 interests.").
/// Only network/timeout failures map to the generic connection message.
String friendlyError(Object e) {
  if (e is PostgrestException) return e.message;
  if (e is AuthException) return e.message;
  if (e is StorageException) return e.message;
  if (e is TimeoutException || e is SocketException) return connectionMessage;
  if (e is ClientException) return connectionMessage;
  final s = e.toString();
  if (s.contains('Failed host lookup') ||
      s.contains('Connection refused') ||
      s.contains('timeout') ||
      s.contains('Timeout')) {
    return connectionMessage;
  }
  return s.replaceFirst('Exception: ', '');
}
