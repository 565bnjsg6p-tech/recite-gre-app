import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:recite_gre_app/src/config/supabase_config.dart';
import 'package:recite_gre_app/src/data/app_database.dart';
import 'package:recite_gre_app/src/data/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _VerificationApp(message: 'Running Supabase sync check...'));
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    final result = await verifySupabaseSync();
    runApp(
      _VerificationApp(
        message:
            'SYNC_VERIFICATION_OK\n'
            'email=${result.email}\n'
            'word=${result.word}\n'
            'pushed=${result.pushed}, pulled=${result.pulled}',
      ),
    );
  } on Object catch (error, stackTrace) {
    runApp(
      _VerificationApp(
        message: 'SYNC_VERIFICATION_FAILED\n$error\n$stackTrace',
      ),
    );
  }
}

Future<SyncVerificationResult> verifySupabaseSync() async {
  final runId = DateTime.now().toUtc().microsecondsSinceEpoch;
  final email = 'recite.sync.$runId@example.com';
  const password = 'SyncTest123!';
  final word = 'syncprobe$runId';
  final client = Supabase.instance.client;

  final auth = await client.auth.signUp(
    email: email,
    password: password,
    data: {'display_name': 'Sync Probe', 'preferred_language': 'english'},
  );
  final user = auth.user;
  if (user == null || client.auth.currentSession == null) {
    throw StateError(
      'Supabase sign-up did not return an active session. Check Auth email confirmation settings.',
    );
  }

  final pushDb = AppDatabase(_openVerificationDatabase('push_$runId'));
  final pullDb = AppDatabase(_openVerificationDatabase('pull_$runId'));
  try {
    final now = DateTime.now();
    await pushDb.ensureCompatibleSchema();
    await pushDb.upsertWord(
      WordCardsCompanion.insert(
        id: '${user.id}:$word',
        userId: Value(user.id),
        word: word,
        chineseMeaning: '同步测试词',
        englishMeaning: 'temporary sync verification word',
        greFocus: 'Used only for Supabase sync verification.',
        rootsJson: const Value('[]'),
        synonymsJson: const Value('[]'),
        antonymsJson: const Value('[]'),
        example: const Value(''),
        memoryTip: const Value(''),
        note: const Value('created by tool/verify_supabase_sync_app.dart'),
        tagsJson: const Value('["sync-test"]'),
        mastery: const Value(0),
        dueAt: now,
        reviewCount: const Value(0),
        lapseCount: const Value(0),
        easeFactor: const Value(250),
        intervalDays: const Value(0),
        enrichmentStatus: const Value('queued'),
        syncStatus: const Value('dirty'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await pushDb.addReviewLog(
      userId: user.id,
      wordId: '${user.id}:$word',
      rating: 'known',
      reviewedAt: now,
    );

    final pushService = SupabaseSyncService(database: pushDb, client: client);
    final push = await pushService.syncNow(userId: user.id);
    if (!push.success) {
      throw StateError('Push failed: ${push.message}');
    }

    await pullDb.ensureCompatibleSchema();
    final pullService = SupabaseSyncService(database: pullDb, client: client);
    final pull = await pullService.pullRemoteChanges(userId: user.id);
    if (!pull.success) {
      throw StateError('Pull failed: ${pull.message}');
    }

    final pulledWord = await pullDb.getWordByText(user.id, word);
    final pulledLogs = await pullDb.getAllReviewLogs(user.id);
    if (pulledWord == null) {
      throw StateError('Pulled database does not contain $word.');
    }
    if (pulledWord.chineseMeaning != '同步测试词') {
      throw StateError('Pulled word content does not match pushed content.');
    }
    if (pulledLogs.length != 1) {
      throw StateError('Pulled database has ${pulledLogs.length} review logs.');
    }

    return SyncVerificationResult(
      email: email,
      word: word,
      pushed: push.pushed,
      pulled: pull.pulled,
    );
  } finally {
    await pushDb.close();
    await pullDb.close();
    await client.auth.signOut();
  }
}

QueryExecutor _openVerificationDatabase(String name) {
  return driftDatabase(
    name: 'recite_sync_verify_$name',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

class SyncVerificationResult {
  const SyncVerificationResult({
    required this.email,
    required this.word,
    required this.pushed,
    required this.pulled,
  });

  final String email;
  final String word;
  final int pushed;
  final int pulled;
}

class _VerificationApp extends StatelessWidget {
  const _VerificationApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
