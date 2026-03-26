import 'package:flutter/material.dart';

import '../services/payment_gateway_service.dart';

class MarketplaceItem {
  MarketplaceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.seller,
    required this.rating,
  });

  final String id;
  final String title;
  final double price;
  final String seller;
  final double rating;

  MarketplaceItem copyWith({
    String? id,
    String? title,
    double? price,
    String? seller,
    double? rating,
  }) {
    return MarketplaceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      seller: seller ?? this.seller,
      rating: rating ?? this.rating,
    );
  }
}

class MarketplaceOrder {
  MarketplaceOrder({
    required this.id,
    required this.items,
    required this.total,
    required this.createdAt,
    this.reviews = const <String, OrderReview>{},
  });

  final String id;
  final List<MarketplaceItem> items;
  final double total;
  final DateTime createdAt;
  final Map<String, OrderReview> reviews;
}

class OrderReview {
  OrderReview({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int rating;
  final String comment;
  final DateTime createdAt;
}

class MarketplaceProvider extends ChangeNotifier {
  bool _canPostListings = false;
  PaymentGatewayService? _paymentGateway;
  bool _processingPayment = false;
  String? _lastPaymentMessage;

  final List<MarketplaceItem> _items = [];

  final List<MarketplaceItem> _cart = [];
  final List<MarketplaceOrder> _orders = [];
  final Map<String, List<OrderReview>> _productReviews = {};

  List<MarketplaceItem> get items => List.unmodifiable(_items);
  List<MarketplaceItem> get cart => List.unmodifiable(_cart);
  List<MarketplaceOrder> get orders => List.unmodifiable(_orders);
  bool get canPostListings => _canPostListings;
  bool get processingPayment => _processingPayment;
  String? get lastPaymentMessage => _lastPaymentMessage;

  void attachPaymentGateway(PaymentGatewayService gateway) {
    _paymentGateway = gateway;
  }

  void setPostingPermission({required bool isAdmin}) {
    _canPostListings = isAdmin;
    notifyListeners();
  }

  String sellerRoomId(MarketplaceItem item) {
    final slug = item.seller
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'seller-$slug';
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.price);

  double itemRating(String itemId, double fallback) {
    final reviews = _productReviews[itemId] ?? const <OrderReview>[];
    if (reviews.isEmpty) return fallback;
    final avg = reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
    return avg;
  }

  void addToCart(MarketplaceItem item) {
    _cart.add(item);
    notifyListeners();
  }

  bool addListing({
    required String title,
    required double price,
    required String seller,
  }) {
    if (!_canPostListings) {
      return false;
    }

    final item = MarketplaceItem(
      id: 'mk-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      price: price,
      seller: seller.trim().isEmpty ? 'Người bán mới' : seller.trim(),
      rating: 5.0,
    );
    _items.insert(0, item);
    notifyListeners();
    return true;
  }

  void removeFromCart(MarketplaceItem item) {
    _cart.remove(item);
    notifyListeners();
  }

  Future<MarketplaceOrder?> placeOrder() async {
    if (_cart.isEmpty) {
      return null;
    }

    _processingPayment = true;
    _lastPaymentMessage = null;
    notifyListeners();

    final orderId = 'ord-${DateTime.now().microsecondsSinceEpoch}';
    final payment = await (_paymentGateway ?? PaymentGatewayService()).processPayment(
      amount: cartTotal,
      currency: 'VND',
      orderId: orderId,
      description: 'SmartLife marketplace checkout',
    );

    if (!payment.success) {
      _processingPayment = false;
      _lastPaymentMessage = payment.message ?? 'Thanh toán thất bại.';
      notifyListeners();
      return null;
    }

    final order = MarketplaceOrder(
      id: orderId,
      items: List<MarketplaceItem>.from(_cart),
      total: cartTotal,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    _cart.clear();
    _processingPayment = false;
    _lastPaymentMessage = payment.message ?? 'Thanh toán thành công (${payment.transactionId}).';
    notifyListeners();
    return order;
  }

  void addReview({
    required String orderId,
    required String itemId,
    required int rating,
    required String comment,
  }) {
    final orderIndex = _orders.indexWhere((e) => e.id == orderId);
    if (orderIndex < 0) return;

    final review = OrderReview(
      rating: rating.clamp(1, 5),
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );

    final order = _orders[orderIndex];
    final nextReviews = Map<String, OrderReview>.from(order.reviews)
      ..[itemId] = review;
    _orders[orderIndex] = MarketplaceOrder(
      id: order.id,
      items: order.items,
      total: order.total,
      createdAt: order.createdAt,
      reviews: nextReviews,
    );

    _productReviews.putIfAbsent(itemId, () => <OrderReview>[]);
    _productReviews[itemId]!.add(review);
    notifyListeners();
  }
}
