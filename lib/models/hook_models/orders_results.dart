import 'package:flutter/material.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/orders_model.dart';

class FetchOrders {
  final List<OrdersModel>? data;
  final bool isLoading;
  final ApiError? error;
  final VoidCallback refetch;

  FetchOrders({
    required this.data,
    required this.isLoading,
    required this.error,
    required this.refetch,
  });
}
