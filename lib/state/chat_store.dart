import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../assistant/assistant_engine.dart';
import '../data/backend.dart';
import '../data/models/people.dart' show dateFrom;
import 'auth_store.dart';

/// One line of the conversation: a question or an answer.
class ChatEntry {
  const ChatEntry.user(this.text) : reply = null;
  const ChatEntry.bot(this.reply) : text = null;

  final String? text;
  final AssistantReply? reply;
  bool get fromUser => reply == null;
}

/// The assistant conversation for the signed-in user, and the record of
/// the questions they have asked. Questions are saved to Firestore in
/// `chatMessages` (readable only by their owner) so that "Recent questions"
/// follows them across visits. Answers are not saved: they are worked out
/// again from the user's current records, so they are never out of date.
class ChatStore extends ChangeNotifier {
  ChatStore(this._backend, this._auth) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final Backend _backend;
  final AuthStore _auth;
  StreamSubscription<Object?>? _sub;
  String? _uid;

  final _entries = <ChatEntry>[];
  List<_Saved> _saved = [];

  List<ChatEntry> get entries => List.unmodifiable(_entries);

  /// Distinct earlier questions, newest first.
  List<String> get recent {
    final seen = <String>{};
    final out = <String>[];
    for (final s in _saved) {
      if (seen.add(s.text.toLowerCase())) out.add(s.text);
      if (out.length >= 6) break;
    }
    return out;
  }

  void _onAuth() {
    final id = _auth.currentUser?.id;
    if (id == _uid) return;
    _uid = id;
    _sub?.cancel();
    _entries.clear();
    _saved = [];
    notifyListeners();
    if (id == null) return;
    _sub = _backend
        .col('chatMessages')
        .where('userId', isEqualTo: id)
        .snapshots()
        .listen((s) {
          _saved = [
            for (final d in s.docs)
              _Saved(
                d.data()['text'] as String? ?? '',
                dateFrom(d.data()['createdAt']) ?? DateTime.now(),
              ),
          ]..sort((a, b) => b.at.compareTo(a.at));
          notifyListeners();
        }, onError: (_) {});
  }

  /// Adds the question and its answer to the conversation and saves the
  /// question. Returns nothing; errors saving never block the answer.
  Future<void> ask(String query, AssistantReply reply) async {
    final text = query.trim();
    if (text.isEmpty) return;
    _entries
      ..add(ChatEntry.user(text))
      ..add(ChatEntry.bot(reply));
    notifyListeners();
    final uid = _uid;
    if (uid == null) return;
    try {
      await _backend.col('chatMessages').add({
        'userId': uid,
        'text': text.length > 500 ? text.substring(0, 500) : text,
        'intent': reply.intent,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Not saving a question must never stop the answer being shown.
    }
  }

  /// Clears the conversation on screen.
  void clearConversation() {
    _entries.clear();
    notifyListeners();
  }

  /// Deletes every saved question for this user.
  Future<String?> deleteHistory() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final snap = await _backend
          .col('chatMessages')
          .where('userId', isEqualTo: uid)
          .get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    _sub?.cancel();
    super.dispose();
  }
}

class _Saved {
  const _Saved(this.text, this.at);
  final String text;
  final DateTime at;
}
