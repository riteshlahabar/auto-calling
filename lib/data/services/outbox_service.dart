// lib/data/services/outbox_service.dart
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';

typedef OutboxItem = Map<String, dynamic>;

class OutboxService {
  static const boxName = 'dialer_outbox';
  late final Box<OutboxItem> _box;

  Future<void> init() async {
    _box = await Hive.openBox<OutboxItem>(boxName);
  }

  Future<void> enqueue(OutboxItem item) async {
    // Idempotency hint: include a composite id in the item if you want dedupe
    await _box.add(item);
  }

  bool get isEmpty => _box.isEmpty;

  Future<void> flush({
    required Future<void> Function(OutboxItem item) sender,
    required bool Function() isOnline,
  }) async {
    if (!isOnline()) return;

    // Snapshot keys to avoid concurrent modification during deletes
    final keys = _box.keys.toList();
    for (final dynamic k in keys) {
      if (!isOnline()) break;

      // No cast needed; Box<OutboxItem>.get returns OutboxItem?
      final OutboxItem? item = _box.get(k);
      if (item == null) continue;

      try {
        await sender(item);
        await _box.delete(k);
      } on DioException {
        // Leave item for a future retry; break to avoid tight failure loops
        break;
      } catch (_) {
        // Unknown error; avoid spinning
        break;
      }
    }
  }
}
