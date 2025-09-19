import 'package:hive/hive.dart';

part 'merchant.g.dart';

@HiveType(typeId: 1)
class MerchantProfile {
  @HiveField(0)
  final String businessName;

  @HiveField(1)
  final String? logoPath;

  @HiveField(2)
  final String? address;

  @HiveField(3)
  final String? phone;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final String? website;

  @HiveField(6)
  final String? taxId;

  @HiveField(7)
  final String? bankDetails;

  @HiveField(8)
  final String invoicePrefix;

  @HiveField(9)
  final int nextInvoiceNumber;

  @HiveField(10)
  final String currencyCode;

  @HiveField(11)
  final String? defaultTerms;

  @HiveField(12)
  final String? defaultNotes;

  @HiveField(13)
  final int? defaultDueDays;

  const MerchantProfile({
    required this.businessName,
    this.logoPath,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.taxId,
    this.bankDetails,
    this.invoicePrefix = 'INV',
    this.nextInvoiceNumber = 1,
    this.currencyCode = 'USD',
    this.defaultTerms,
    this.defaultNotes,
    this.defaultDueDays,
  });

  MerchantProfile copyWith({
    String? businessName,
    String? logoPath,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? taxId,
    String? bankDetails,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? currencyCode,
    String? defaultTerms,
    String? defaultNotes,
    int? defaultDueDays,
  }) {
    return MerchantProfile(
      businessName: businessName ?? this.businessName,
      logoPath: logoPath ?? this.logoPath,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      bankDetails: bankDetails ?? this.bankDetails,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      defaultTerms: defaultTerms ?? this.defaultTerms,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      defaultDueDays: defaultDueDays ?? this.defaultDueDays,
    );
  }
}
