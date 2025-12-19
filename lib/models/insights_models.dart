import 'dart:convert';

VendorAnalyticsOverview vendorAnalyticsOverviewFromJson(String source) {
  final Map<String, dynamic> decoded = jsonDecode(source);
  if (decoded['data'] is Map<String, dynamic>) {
    return VendorAnalyticsOverview.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map));
  }
  return VendorAnalyticsOverview.empty();
}

StoreRecommendations storeRecommendationsFromJson(String source) {
  final Map<String, dynamic> decoded = jsonDecode(source);
  if (decoded['data'] is Map<String, dynamic>) {
    return StoreRecommendations.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map));
  }
  return StoreRecommendations.empty();
}

class VendorAnalyticsOverview {
  final String storeId;
  final int rangeDays;
  final DateTime generatedAt;
  final AnalyticsTotals totals;
  final Map<String, int> statuses;
  final Map<String, int> sources;
  final List<AnalyticsPoint> timeline;
  final List<TopProductInsight> topProducts;
  final CustomerInsight customers;

  const VendorAnalyticsOverview({
    required this.storeId,
    required this.rangeDays,
    required this.generatedAt,
    required this.totals,
    required this.statuses,
    required this.sources,
    required this.timeline,
    required this.topProducts,
    required this.customers,
  });

  factory VendorAnalyticsOverview.empty() => VendorAnalyticsOverview(
        storeId: '',
        rangeDays: 0,
        generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        totals: AnalyticsTotals.empty(),
        statuses: const {},
        sources: const {},
        timeline: const [],
        topProducts: const [],
        customers: CustomerInsight.empty(),
      );

  factory VendorAnalyticsOverview.fromJson(Map<String, dynamic> json) {
    Map<String, int> _parseSources(dynamic raw) {
      if (raw is Map) {
        return raw.map((key, value) => MapEntry(
              key.toString(),
              int.tryParse(value.toString()) ?? 0,
            ));
      }
      return const {};
    }

    final sourcesRaw = json['orderSources'] ?? json['sources'];
    return VendorAnalyticsOverview(
      storeId: json['storeId']?.toString() ?? '',
      rangeDays: json['rangeDays'] is int
          ? json['rangeDays'] as int
          : int.tryParse(json['rangeDays']?.toString() ?? '') ?? 0,
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
      totals: AnalyticsTotals.fromJson(Map<String, dynamic>.from(
          json['totals'] ?? const <String, dynamic>{})),
      statuses: (json['statuses'] as Map?)?.map((key, value) =>
              MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0)) ??
          const {},
      sources: _parseSources(sourcesRaw),
      timeline: (json['timeline'] as List?)
              ?.map((e) =>
                  AnalyticsPoint.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      topProducts: (json['topProducts'] as List?)
              ?.map((e) => TopProductInsight.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      customers: CustomerInsight.fromJson(Map<String, dynamic>.from(
          json['customers'] ?? const <String, dynamic>{})),
    );
  }
}

class AnalyticsTotals {
  final int orders;
  final int delivered;
  final int cancelled;
  final double revenueDelivered;
  final double avgOrderValue;
  final double returnRate;

  const AnalyticsTotals({
    required this.orders,
    required this.delivered,
    required this.cancelled,
    required this.revenueDelivered,
    required this.avgOrderValue,
    required this.returnRate,
  });

  factory AnalyticsTotals.empty() => const AnalyticsTotals(
        orders: 0,
        delivered: 0,
        cancelled: 0,
        revenueDelivered: 0,
        avgOrderValue: 0,
        returnRate: 0,
      );

  factory AnalyticsTotals.fromJson(Map<String, dynamic> json) =>
      AnalyticsTotals(
        orders: json['orders'] is int
            ? json['orders'] as int
            : int.tryParse(json['orders']?.toString() ?? '') ?? 0,
        delivered: json['delivered'] is int
            ? json['delivered'] as int
            : int.tryParse(json['delivered']?.toString() ?? '') ?? 0,
        cancelled: json['cancelled'] is int
            ? json['cancelled'] as int
            : int.tryParse(json['cancelled']?.toString() ?? '') ?? 0,
        revenueDelivered: _toDouble(json['revenueDelivered']),
        avgOrderValue: _toDouble(json['avgOrderValue']),
        returnRate: _toDouble(json['returnRate']),
      );
}

class AnalyticsPoint {
  final String date;
  final int orders;
  final double revenue;

  const AnalyticsPoint({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  factory AnalyticsPoint.fromJson(Map<String, dynamic> json) => AnalyticsPoint(
        date: json['date']?.toString() ?? '',
        orders: json['orders'] is int
            ? json['orders'] as int
            : int.tryParse(json['orders']?.toString() ?? '') ?? 0,
        revenue: _toDouble(json['revenue']),
      );
}

class TopProductInsight {
  final String productId;
  final String title;
  final String image;
  final int sold;
  final double revenue;
  final double price;
  final int stock;

  const TopProductInsight({
    required this.productId,
    required this.title,
    required this.image,
    required this.sold,
    required this.revenue,
    required this.price,
    required this.stock,
  });

  factory TopProductInsight.fromJson(Map<String, dynamic> json) =>
      TopProductInsight(
        productId: json['productId']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Sản phẩm',
        image: json['image']?.toString() ?? '',
        sold: json['sold'] is int
            ? json['sold'] as int
            : int.tryParse(json['sold']?.toString() ?? '') ?? 0,
        revenue: _toDouble(json['revenue']),
        price: _toDouble(json['price']),
        stock: json['stock'] is int
            ? json['stock'] as int
            : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      );
}

class CustomerInsight {
  final int total;
  final int newCustomers;
  final int repeatCustomers;
  final double repeatRate;
  final List<CustomerSummary> topCustomers;

  const CustomerInsight({
    required this.total,
    required this.newCustomers,
    required this.repeatCustomers,
    required this.repeatRate,
    required this.topCustomers,
  });

  factory CustomerInsight.empty() => const CustomerInsight(
        total: 0,
        newCustomers: 0,
        repeatCustomers: 0,
        repeatRate: 0,
        topCustomers: [],
      );

  factory CustomerInsight.fromJson(Map<String, dynamic> json) =>
      CustomerInsight(
        total: json['total'] is int
            ? json['total'] as int
            : int.tryParse(json['total']?.toString() ?? '') ?? 0,
        newCustomers: json['newCustomers'] is int
            ? json['newCustomers'] as int
            : int.tryParse(json['newCustomers']?.toString() ?? '') ?? 0,
        repeatCustomers: json['repeatCustomers'] is int
            ? json['repeatCustomers'] as int
            : int.tryParse(json['repeatCustomers']?.toString() ?? '') ?? 0,
        repeatRate: _toDouble(json['repeatRate']),
        topCustomers: (json['topCustomers'] as List?)
                ?.map((e) => CustomerSummary.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class CustomerSummary {
  final String customerId;
  final String name;
  final String email;
  final int orders;
  final double spend;

  const CustomerSummary({
    required this.customerId,
    required this.name,
    required this.email,
    required this.orders,
    required this.spend,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) =>
      CustomerSummary(
        customerId: json['customerId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Khách hàng',
        email: json['email']?.toString() ?? '',
        orders: json['orders'] is int
            ? json['orders'] as int
            : int.tryParse(json['orders']?.toString() ?? '') ?? 0,
        spend: _toDouble(json['spend']),
      );
}

class StoreRecommendations {
  final String storeId;
  final int rangeDays;
  final DateTime generatedAt;
  final List<RecommendationProduct> trending;
  final List<RestockAlert> restockAlerts;
  final List<BundleIdea> bundleIdeas;

  const StoreRecommendations({
    required this.storeId,
    required this.rangeDays,
    required this.generatedAt,
    required this.trending,
    required this.restockAlerts,
    required this.bundleIdeas,
  });

  factory StoreRecommendations.empty() => StoreRecommendations(
        storeId: '',
        rangeDays: 0,
        generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        trending: const [],
        restockAlerts: const [],
        bundleIdeas: const [],
      );

  factory StoreRecommendations.fromJson(Map<String, dynamic> json) =>
      StoreRecommendations(
        storeId: json['storeId']?.toString() ?? '',
        rangeDays: json['rangeDays'] is int
            ? json['rangeDays'] as int
            : int.tryParse(json['rangeDays']?.toString() ?? '') ?? 0,
        generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
            DateTime.now(),
        trending: (json['trending'] as List?)
                ?.map((e) => RecommendationProduct.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        restockAlerts: (json['restockAlerts'] as List?)
                ?.map((e) =>
                    RestockAlert.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        bundleIdeas: (json['bundleIdeas'] as List?)
                ?.map((e) =>
                    BundleIdea.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class RecommendationProduct {
  final String productId;
  final String title;
  final String image;
  final double price;
  final int stock;
  final int sold;
  final double revenue;
  final double discount;

  const RecommendationProduct({
    required this.productId,
    required this.title,
    required this.image,
    required this.price,
    required this.stock,
    required this.sold,
    required this.revenue,
    required this.discount,
  });

  factory RecommendationProduct.fromJson(Map<String, dynamic> json) =>
      RecommendationProduct(
        productId: (json['productId'] ?? json['id'] ?? '').toString(),
        title: json['title']?.toString() ?? 'Sản phẩm',
        image: json['image']?.toString() ?? '',
        price: _toDouble(json['price']),
        stock: json['stock'] is int
            ? json['stock'] as int
            : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
        sold: json['sold'] is int
            ? json['sold'] as int
            : int.tryParse(json['sold']?.toString() ?? '') ??
                int.tryParse(json['soldCount']?.toString() ?? '') ??
                0,
        revenue: _toDouble(json['revenue']),
        discount: _toDouble(json['discount']),
      );
}

class RestockAlert {
  final String productId;
  final String title;
  final int stock;
  final int sold;
  final int suggestedOrder;
  final String urgency;

  const RestockAlert({
    required this.productId,
    required this.title,
    required this.stock,
    required this.sold,
    required this.suggestedOrder,
    required this.urgency,
  });

  factory RestockAlert.fromJson(Map<String, dynamic> json) => RestockAlert(
        productId: json['productId']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Sản phẩm',
        stock: json['stock'] is int
            ? json['stock'] as int
            : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
        sold: json['sold'] is int
            ? json['sold'] as int
            : int.tryParse(json['sold']?.toString() ?? '') ?? 0,
        suggestedOrder: json['suggestedOrder'] is int
            ? json['suggestedOrder'] as int
            : int.tryParse(json['suggestedOrder']?.toString() ?? '') ?? 0,
        urgency: json['urgency']?.toString() ?? 'low',
      );
}

class BundleIdea {
  final int ordersTogether;
  final List<RecommendationProduct> products;

  const BundleIdea({
    required this.ordersTogether,
    required this.products,
  });

  factory BundleIdea.fromJson(Map<String, dynamic> json) => BundleIdea(
        ordersTogether: json['ordersTogether'] is int
            ? json['ordersTogether'] as int
            : int.tryParse(json['ordersTogether']?.toString() ?? '') ?? 0,
        products: (json['products'] as List?)
                ?.map((e) => RecommendationProduct.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
