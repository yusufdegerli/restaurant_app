class TicketItemDto {
  final int ticketId;
  final int menuItemId;
  final String menuItemName;
  final double price;
  final double quantity;
  final String portionName;
  final DateTime? createdDateTime;
  final int creatingUserId;
  final int? departmentId;

  TicketItemDto({
    required this.ticketId,
    required this.menuItemId,
    required this.menuItemName,
    required this.price,
    required this.quantity,
    required this.portionName,
    this.createdDateTime,
    required this.creatingUserId,
    this.departmentId,
  });

  factory TicketItemDto.fromJson(Map<String, dynamic> json) {
    return TicketItemDto(
      ticketId: json['ticketId'] ?? 0,
      menuItemId: json['menuItemId'] ?? 0,
      menuItemName: json['menuItemName'] ?? 'No Name',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      portionName: json['portionName'] ?? 'Normal',
      createdDateTime:
          json['createdDateTime'] != null
              ? DateTime.parse(json['createdDateTime'])
              : null,
      creatingUserId: json['creatingUserId'] ?? 0,
      departmentId: json['departmentId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'menuItemId': menuItemId,
    'menuItemName': menuItemName,
    'price': price,
    'quantity': quantity,
    'portionName': portionName,
    'createdDateTime': createdDateTime?.toIso8601String(),
    'creatingUserId': creatingUserId,
    'departmentId': departmentId,
  };
}

class Ticket {
  final int id;
  final String name;
  final String ticketNumber;
  final String? customerName;
  final double remainingAmount;
  final double totalAmount;
  final String? note;
  final String? tag;
  final bool isClosed;
  final bool isPaid;

  Ticket({
    required this.id,
    required this.name,
    required this.ticketNumber,
    this.customerName,
    required this.remainingAmount,
    required this.totalAmount,
    this.note,
    this.tag,
    required this.isPaid,
    required this.isClosed,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No Name',
      ticketNumber: json['ticketNumber']?.toString() ?? '0',
      customerName: json['customerName'],
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'],
      tag: json['tag'],
      isPaid: json['isPaid'] ?? false,
      isClosed: json['isClosed'] ?? false,
    );
  }
}
