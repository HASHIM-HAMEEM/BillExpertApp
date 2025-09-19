import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fx_rates.dart';

abstract class FxRatesRepository {
  Future<FxRates?> getFxRates();
  Future<void> saveFxRates(FxRates rates);
}

class HiveFxRatesRepository implements FxRatesRepository {
  static const String _boxName = 'fx_rates';
  static const String _key = 'rates';

  Future<Box> _getBox() => Hive.openBox(_boxName);

  @override
  Future<FxRates?> getFxRates() async {
    final box = await _getBox();
    return box.get(_key) as FxRates?;
  }

  @override
  Future<void> saveFxRates(FxRates rates) async {
    final box = await _getBox();
    await box.put(_key, rates);
  }
}

final fxRatesRepositoryProvider = Provider<FxRatesRepository>((ref) {
  return HiveFxRatesRepository();
});
