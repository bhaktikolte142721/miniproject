import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WardFilter {
  all,
  bed01,
  bed02,
  bed03,
  highRisk,
  batteryLow,
  disconnected,
}

extension WardFilterExt on WardFilter {
  String get label {
    switch (this) {
      case WardFilter.all:
        return 'All Patients';
      case WardFilter.bed01:
        return 'Bed 01';
      case WardFilter.bed02:
        return 'Bed 02';
      case WardFilter.bed03:
        return 'Bed 03';
      case WardFilter.highRisk:
        return 'High Risk';
      case WardFilter.batteryLow:
        return 'Battery Low';
      case WardFilter.disconnected:
        return 'Link Disconnected';
    }
  }
}

/// State notifier for ward grid filter chips
final wardFilterProvider = StateProvider<WardFilter>((ref) => WardFilter.all);
