import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/invoice.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> getAll();
  Stream<List<Invoice>> watchAll();
  Future<Invoice?> getById(String id);
  Future<void> upsert(Invoice invoice);
  Future<void> delete(String id);
}

class HiveInvoiceRepository implements InvoiceRepository {
  HiveInvoiceRepository(this._box);

  final Box<Invoice> _box;

  @override
  Future<List<Invoice>> getAll() async => _box.values.toList();

  @override
  Stream<List<Invoice>> watchAll() async* {
    yield _box.values.toList();
    await for (final _ in _box.watch()) {
      yield _box.values.toList();
    }
  }

  @override
  Future<Invoice?> getById(String id) async => _box.get(id);

  @override
  Future<void> upsert(Invoice invoice) async {
    await _box.put(invoice.id, invoice);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final box = Hive.box<Invoice>('invoices');
  return HiveInvoiceRepository(box);
});


