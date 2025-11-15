import 'package:flutter/material.dart';
import 'package:appliances_flutter/models/api_error.dart';
import 'package:appliances_flutter/models/appliancess_model.dart';

class FetchAppliancess {
  final List<AppliancessModel>? data;
  final bool isLoading;
  final ApiError? error;
  final VoidCallback refetch;

  FetchAppliancess({
    required this.data,
    required this.isLoading,
    required this.error,
    required this.refetch,
  });
}
