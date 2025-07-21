import 'package:sambapos_app_restorant/models/menu_item_property_groups.dart';

class MenuItemProperty {
  final int id;
  final String name;
  final int? menuItemPropertyGroupId;
  final MenuItemPropertyGroup? menuItemPropertyGroup;
  final int? menuItemId;

  MenuItemProperty({
    required this.id,
    required this.name,
    this.menuItemPropertyGroupId,
    this.menuItemPropertyGroup,
    this.menuItemId,
  });

  factory MenuItemProperty.fromJson(Map<String, dynamic> json) {
    return MenuItemProperty(
      id: json['id'] as int,
      name: json['name'] as String,
      menuItemPropertyGroupId: json['menuItemPropertyGroup_Id'] as int?,
      menuItemPropertyGroup: json['menuItemPropertyGroup'] != null
          ? MenuItemPropertyGroup.fromJson(json['menuItemPropertyGroup'] as Map<String, dynamic>)
          : null,
    );
  }
}
