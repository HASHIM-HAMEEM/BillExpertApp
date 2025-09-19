import 'package:hive/hive.dart';
import 'client.dart';

part 'invoice.g.dart';

@HiveType(typeId: 10)
enum InvoiceStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  unpaid,
  @HiveField(2)
  partiallyPaid,
  @HiveField(3)
  paid,
  @HiveField(4)
  overdue,
}

@HiveType(typeId: 11)
class InvoiceItem {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String description;

  // Optional free-text name for when no product catalog is used
  @HiveField(7)
  String? name;

  @HiveField(2)
  double quantity;

  @HiveField(3)
  double rate;

  @HiveField(4)
  double taxPercent;

  @HiveField(5)
  double discountValue; // absolute amount or percent depending on discountIsPercent

  @HiveField(6)
  bool discountIsPercent;

  InvoiceItem({
    required this.productId,
    required this.description,
    required this.quantity,
    required this.rate,
    this.taxPercent = 0,
    this.discountValue = 0,
    this.discountIsPercent = true,
  });

  double get lineSubtotal => quantity * rate;

  double get discountAmount =>
      discountIsPercent ? lineSubtotal * (discountValue / 100) : discountValue;

  double get taxable => (lineSubtotal - discountAmount).clamp(0, double.infinity);

  double get taxAmount => taxable * (taxPercent / 100);

  double get lineTotal => taxable + taxAmount;
}

@HiveType(typeId: 12)
class Invoice extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String invoiceNumber;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  Client client;

  @HiveField(5)
  List<InvoiceItem> items;

  @HiveField(6)
  InvoiceStatus status;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? terms;

  @HiveField(9)
  String? currencyCode; // overrides merchant currency for this invoice

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.client,
    required this.items,
    this.status = InvoiceStatus.draft,
    this.notes,
    this.terms,
    this.currencyCode,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.lineSubtotal);
  double get discountTotal => items.fold(0, (sum, i) => sum + i.discountAmount);
  double get taxableTotal => items.fold(0, (sum, i) => sum + i.taxable);
  double get taxAmount => items.fold(0, (sum, i) => sum + i.taxAmount);
  double get totalAmount => items.fold(0, (sum, i) => sum + i.lineTotal);
}


