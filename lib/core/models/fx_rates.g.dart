// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fx_rates.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FxRatesAdapter extends TypeAdapter<FxRates> {
  @override
  final int typeId = 20;

  @override
  FxRates read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FxRates(
      baseCurrency: fields[0] as String,
      rates: (fields[1] as Map?)?.cast<String, double>(),
    )..fetchedAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, FxRates obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.baseCurrency)
      ..writeByte(1)
      ..write(obj.rates)
      ..writeByte(2)
      ..write(obj.fetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FxRatesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
