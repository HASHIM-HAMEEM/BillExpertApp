import 'package:hive_flutter/hive_flutter.dart';
import '../models/merchant.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/fx_rates.dart';

class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters
    Hive.registerAdapter(MerchantProfileAdapter());
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(InvoiceStatusAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(FxRatesAdapter());

    // Open boxes
    await Hive.openBox<MerchantProfile>('merchant');
    await Hive.openBox<Client>('clients');
    await Hive.openBox<Invoice>('invoices');
    await Hive.openBox<FxRates>('fx_rates');
  }
}


