import 'package:firebase_auth/firebase_auth.dart';

/// Provides the account-scoped accessor ID required by conversation APIs.
///
/// The backend still accepts this value under the compatibility field
/// `conversation_uuid`, but the value is now the signed-in Firebase UID.
class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  Future<void> initialize() async {
    // FirebaseAuth may not have a user before login. Callers resolve the UID
    // lazily so account changes are picked up immediately.
  }

  Future<String> getConversationUuid() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('A signed-in Firebase user is required.');
    }

    return uid;
  }

  String redact(String uid) {
    if (uid.length <= 8) {
      return '****';
    }

    return '${uid.substring(0, 4)}...${uid.substring(uid.length - 4)}';
  }
}
