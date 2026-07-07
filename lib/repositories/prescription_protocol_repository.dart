import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prescription_protocol.dart';
import '../services/supabase_sync_service.dart';
import '../utils/search_normalizer.dart';

class PrescriptionProtocolRepository {
  PrescriptionProtocolRepository(this._preferences);

  final SharedPreferences _preferences;
  final _sync = SupabaseSyncService.instance;
  bool _syncedRemote = false;

  static const _key = 'prescription_protocols';

  static Future<PrescriptionProtocolRepository> load() async =>
      PrescriptionProtocolRepository(await SharedPreferences.getInstance());

  Future<List<PrescriptionProtocol>> syncNow() async {
    _syncedRemote = false;
    final protocols = await _syncRemoteOnce(_readLocal(), rethrowErrors: true);
    return _sorted(protocols);
  }

  Future<List<PrescriptionProtocol>> getAll() async =>
      _sorted(await _syncRemoteOnce(_readLocal()));

  Future<List<PrescriptionProtocol>> search(String query) async {
    final normalized = normalizeSearch(query);
    final protocols = await getAll();
    if (normalized.isEmpty) return protocols;
    return protocols
        .where((item) => normalizeSearch(item.name).contains(normalized))
        .toList();
  }

  Future<void> save(PrescriptionProtocol protocol) async {
    final protocols = await getAll();
    final index = protocols.indexWhere((item) => item.id == protocol.id);
    if (index < 0) {
      protocols.add(protocol);
    } else {
      protocols[index] = protocol;
    }
    await _write(protocols);
    try {
      await _sync.upsertProtocol(protocol);
    } catch (error) {
      debugPrint('Falha ao sincronizar protocolo: $error');
    }
  }

  Future<void> delete(String id) async {
    final protocols = await getAll()
      ..removeWhere((item) => item.id == id);
    await _write(protocols);
    try {
      await _sync.deleteProtocol(id);
    } catch (error) {
      debugPrint('Falha ao apagar protocolo sincronizado: $error');
    }
  }

  List<PrescriptionProtocol> _readLocal() {
    final raw = _preferences.getString(_key);
    if (raw == null) return <PrescriptionProtocol>[];
    return (jsonDecode(raw) as List)
        .map(
          (item) => PrescriptionProtocol.fromJson(
            (item as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<void> _write(List<PrescriptionProtocol> protocols) =>
      _preferences.setString(
        _key,
        jsonEncode(protocols.map((item) => item.toJson()).toList()),
      );

  Future<List<PrescriptionProtocol>> _syncRemoteOnce(
    List<PrescriptionProtocol> protocols, {
    bool rethrowErrors = false,
  }) async {
    if (_syncedRemote || !_sync.canSync) return protocols;
    _syncedRemote = true;
    try {
      final remote = await _sync.fetchProtocols();
      final merged = [...protocols];
      for (final protocol in remote) {
        final index = merged.indexWhere((item) => item.id == protocol.id);
        if (index >= 0) {
          merged[index] = protocol;
        } else {
          merged.add(protocol);
        }
      }
      for (final protocol in merged) {
        if (!remote.any((item) => item.id == protocol.id)) {
          await _sync.upsertProtocol(protocol);
        }
      }
      await _write(merged);
      return merged;
    } catch (error) {
      debugPrint('Falha ao sincronizar protocolos: $error');
      if (rethrowErrors) rethrow;
      return protocols;
    }
  }

  List<PrescriptionProtocol> _sorted(List<PrescriptionProtocol> protocols) =>
      protocols
        ..sort(
          (a, b) => normalizeSearch(a.name).compareTo(normalizeSearch(b.name)),
        );
}
