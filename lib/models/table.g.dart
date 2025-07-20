// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RestaurantTableAdapter extends TypeAdapter<RestaurantTable> {
  @override
  final int typeId = 2;

  @override
  RestaurantTable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RestaurantTable(
      id: fields[0] as int,
      name: fields[1] as String,
      order: fields[2] as int,
      category: fields[3] as String,
      ticketId: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RestaurantTable obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.ticketId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantTableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
