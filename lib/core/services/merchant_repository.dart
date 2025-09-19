import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/merchant.dart';

abstract class MerchantRepository {
  Future<MerchantProfile?> getProfile();
  Stream<MerchantProfile?> watchProfile();
  Future<void> saveProfile(MerchantProfile profile);
  Future<void> updateProfile(MerchantProfile profile);
  Future<String> generateNextInvoiceNumber();
}

class HiveMerchantRepository implements MerchantRepository {
  HiveMerchantRepository(this._box);

  final Box<MerchantProfile> _box;
  static const String _key = 'profile';

  @override
  Future<MerchantProfile?> getProfile() async {
    return _box.get(_key);
  }

  @override
  Stream<MerchantProfile?> watchProfile() async* {
    yield _box.get(_key);
    await for (final _ in _box.watch(key: _key)) {
      yield _box.get(_key);
    }
  }

  @override
  Future<void> saveProfile(MerchantProfile profile) async {
    await _box.put(_key, profile);
  }

  @override
  Future<void> updateProfile(MerchantProfile profile) async {
    await _box.put(_key, profile);
  }

  @override
  Future<String> generateNextInvoiceNumber() async {
    final profile = _box.get(_key);
    if (profile == null) {
      // Fallback
      return 'INV-${DateTime.now().year}-001';
    }
    final now = DateTime.now();
    final number = profile.nextInvoiceNumber;
    final formatted = '${profile.invoicePrefix}-${now.year}-${number.toString().padLeft(3, '0')}';
    // increment and save
    final updated = profile.copyWith(nextInvoiceNumber: number + 1);
    await _box.put(_key, updated);
    return formatted;
  }
}

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  final box = Hive.box<MerchantProfile>('merchant');
  return HiveMerchantRepository(box);
});


