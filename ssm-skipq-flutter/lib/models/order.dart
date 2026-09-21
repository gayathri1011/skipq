enum PaymentMethod { razorpay, googlePay, phonePe, payAtCounter }

enum PaymentStatus { pending, paid }

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  pickedUp,
  cancelled,
}

extension OrderStatusExtensions on OrderStatus {
  bool get isActiveOrderStatus {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
      case OrderStatus.ready:
      case OrderStatus.pickedUp:
        return true;
      case OrderStatus.cancelled:
        return false;
    }
  }
}

Order? getCurrentActiveOrderForStudent(List<Order> orders, {String? orderId}) {
  final activeOrders =
      orders.where((order) => order.status.isActiveOrderStatus);
  if (orderId != null) {
    final match = activeOrders.where((order) => order.id == orderId).toList();
    if (match.isNotEmpty) {
      return match.reduce((current, next) =>
          next.createdAt.isAfter(current.createdAt) ? next : current);
    }
    return null;
  }

  if (activeOrders.isEmpty) return null;
  return activeOrders.reduce((current, next) =>
      next.createdAt.isAfter(current.createdAt) ? next : current);
}

extension PaymentMethodX on PaymentMethod {
  String get apiValue {
    switch (this) {
      case PaymentMethod.razorpay:
        return 'RAZORPAY';
      case PaymentMethod.googlePay:
        return 'GOOGLE_PAY';
      case PaymentMethod.phonePe:
        return 'PHONEPE';
      case PaymentMethod.payAtCounter:
        return 'PAY_AT_COUNTER';
    }
  }

  static PaymentMethod fromApi(String? value) {
    switch (value) {
      case 'RAZORPAY':
        return PaymentMethod.razorpay;
      case 'PHONEPE':
        return PaymentMethod.phonePe;
      case 'PAY_AT_COUNTER':
        return PaymentMethod.payAtCounter;
      default:
        return PaymentMethod.googlePay;
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.razorpay:
        return 'Paid Online (Razorpay)';
      case PaymentMethod.googlePay:
        return 'Google Pay (Mock)';
      case PaymentMethod.phonePe:
        return 'PhonePe (Mock)';
      case PaymentMethod.payAtCounter:
        return 'Pay at Counter';
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get apiValue => this == PaymentStatus.paid ? 'PAID' : 'PENDING';

  static PaymentStatus fromApi(String? value) {
    return value == 'PAID' ? PaymentStatus.paid : PaymentStatus.pending;
  }
}

extension OrderStatusX on OrderStatus {
  static OrderStatus fromApi(String? value) {
    switch (value) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
        return OrderStatus.ready;
      case 'PICKED_UP':
      case 'COMPLETED':
        return OrderStatus.pickedUp;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.ready:
        return 'READY';
      case OrderStatus.pickedUp:
        return 'PICKED_UP';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      case OrderStatus.pending:
        return 'PENDING';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Accepted';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Collected';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String? get managerAction {
    switch (this) {
      case OrderStatus.pending:
        return 'Accept';
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        return 'Ready';
      case OrderStatus.ready:
        return 'Collected';
      default:
        return null;
    }
  }
}

class OrderItem {
  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String menuItemId;
  final String name;
  final num price;
  final int quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] as num? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

class OrderStudent {
  const OrderStudent({required this.name, required this.mobile});

  final String name;
  final String mobile;

  factory OrderStudent.fromJson(Map<String, dynamic> json) {
    return OrderStudent(
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.studentId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.tokenNumber,
    required this.createdAt,
    this.note = '',
    this.student,
    this.cancelledBy,
    this.cancelledAt,
    this.hasFeedback = false,
    this.feedback,
  });

  final String id;
  final String studentId;
  final List<OrderItem> items;
  final num total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus status;
  final String tokenNumber;
  final DateTime createdAt;
  final String note;
  final OrderStudent? student;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final bool hasFeedback;
  final SubmittedFeedback? feedback;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num? ?? 0,
      paymentMethod: PaymentMethodX.fromApi(json['paymentMethod'] as String?),
      paymentStatus: PaymentStatusX.fromApi(json['paymentStatus'] as String?),
      status: OrderStatusX.fromApi(json['status'] as String?),
      tokenNumber: json['tokenNumber'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
      student: json['student'] != null
          ? OrderStudent.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      cancelledBy: json['cancelledBy'] as String?,
      cancelledAt: DateTime.tryParse(json['cancelledAt'] as String? ?? ''),
      hasFeedback: json['hasFeedback'] as bool? ?? false,
      feedback: json['feedback'] != null
          ? SubmittedFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  Order copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    bool? hasFeedback,
    SubmittedFeedback? feedback,
  }) {
    return Order(
      id: id,
      studentId: studentId,
      items: items,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      tokenNumber: tokenNumber,
      createdAt: createdAt,
      student: student,
      cancelledBy: cancelledBy,
      hasFeedback: hasFeedback ?? this.hasFeedback,
      feedback: feedback ?? this.feedback,
    );
  }
}

class SubmittedFeedback {
  const SubmittedFeedback({required this.rating, required this.review});

  final int rating;
  final String review;

  factory SubmittedFeedback.fromJson(Map<String, dynamic> json) {
    return SubmittedFeedback(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      review: json['review'] as String? ?? '',
    );
  }
}

class CartItem {
  const CartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.isVeg,
    required this.available,
    this.categoryId = '',
    this.categoryName = '',
  });

  final String menuItemId;
  final String name;
  final num price;
  final int quantity;
  final String imageUrl;
  final bool isVeg;
  final bool available;
  final String categoryId;
  final String categoryName;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuItemId: menuItemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      isVeg: isVeg,
      available: available,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}
