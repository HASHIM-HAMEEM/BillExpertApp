import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/client.dart';

abstract class ClientRepository {
  Future<List<Client>> getAll();
  Stream<List<Client>> watchAll();
  Future<void> upsert(Client client);
  Future<void> delete(String id);
}

class HiveClientRepository implements ClientRepository {
  HiveClientRepository(this._box);

  final Box<Client> _box;

  @override
  Future<List<Client>> getAll() async => _box.values.toList();

  @override
  Stream<List<Client>> watchAll() async* {
    yield _box.values.toList();
    await for (final _ in _box.watch()) {
      yield _box.values.toList();
    }
  }

  @override
  Future<void> upsert(Client client) async {
    await _box.put(client.id, client);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final box = Hive.box<Client>('clients');
  return HiveClientRepository(box);
});


