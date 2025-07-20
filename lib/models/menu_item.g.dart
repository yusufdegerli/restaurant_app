// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 1;

  @override
  MenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItem(
      id: fields[0] as int,
      name: fields[1] as String,
      groupCode: fields[2] as String,
      price: fields[3] as double,
      category: fields[4] as String,
      singleSelection: fields[5] as bool,
      multipleSelection: fields[6] as bool,
      hasVariants: fields[7] as bool,
      variants: (fields[8] as List).cast<String>(),
      categories: (fields[9] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.groupCode)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.singleSelection)
      ..writeByte(6)
      ..write(obj.multipleSelection)
      ..writeByte(7)
      ..write(obj.hasVariants)
      ..writeByte(8)
      ..write(obj.variants)
      ..writeByte(9)
      ..write(obj.categories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
