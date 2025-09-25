// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MerchantProfileAdapter extends TypeAdapter<MerchantProfile> {
  @override
  final int typeId = 1;

  @override
  MerchantProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MerchantProfile(
      businessName: fields[0] as String,
      logoPath: fields[1] as String?,
      address: fields[2] as String?,
      phone: fields[3] as String?,
      email: fields[4] as String?,
      website: fields[5] as String?,
      taxId: fields[6] as String?,
      bankDetails: fields[7] as String?,
      invoicePrefix: fields[8] as String,
      nextInvoiceNumber: fields[9] as int,
      currencyCode: fields[10] as String,
      displayCurrencyCode: fields[14] as String?,
      defaultTerms: fields[11] as String?,
      defaultNotes: fields[12] as String?,
      defaultDueDays: fields[13] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MerchantProfile obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.logoPath)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.website)
      ..writeByte(6)
      ..write(obj.taxId)
      ..writeByte(7)
      ..write(obj.bankDetails)
      ..writeByte(8)
      ..write(obj.invoicePrefix)
      ..writeByte(9)
      ..write(obj.nextInvoiceNumber)
      ..writeByte(10)
      ..write(obj.currencyCode)
      ..writeByte(11)
      ..write(obj.defaultTerms)
      ..writeByte(12)
      ..write(obj.defaultNotes)
      ..writeByte(13)
      ..write(obj.defaultDueDays)
      ..writeByte(14)
      ..write(obj.displayCurrencyCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
