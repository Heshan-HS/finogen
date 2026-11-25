import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/novagen_api_service.dart';

class NovaGenAdminState {
  final bool isLoading;
  final NovaGenTelemetryData telemetry;
  final String searchQuery;
  final String selectedFilter; // 'all', 'online', 'expiring', 'expired', 'active'

  const NovaGenAdminState({
    this.isLoading = false,
    required this.telemetry,
    this.searchQuery = '',
    this.selectedFilter = 'all',
  });

  NovaGenAdminState copyWith({
    bool? isLoading,
    NovaGenTelemetryData? telemetry,
    String? searchQuery,
    String? selectedFilter,
  }) {
    return NovaGenAdminState(
      isLoading: isLoading ?? this.isLoading,
      telemetry: telemetry ?? this.telemetry,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  /// Filtered client list according to search query and selected filter tab
  List<NovaGenClientModel> get filteredClients {
    var list = telemetry.clients;

    // Apply Filter
    switch (selectedFilter) {
      case 'online':
        list = list.where((c) => c.online).toList();
        break;
      case 'expiring':
        list = list.where((c) => c.expiresWithin24h || (!c.isExpired && c.daysUntilExpiry <= 3)).toList();
        break;
      case 'expired':
        list = list.where((c) => c.isExpired || c.daysUntilExpiry < 0).toList();
        break;
      case 'active':
        list = list.where((c) => !c.isExpired && c.daysUntilExpiry >= 0).toList();
        break;
      default:
        break;
    }

    // Apply Search
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.rawEmail.toLowerCase().contains(q) ||
            c.inboundRemark.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  /// Top 5 data consumers for the scrolling marquee ticker
  List<NovaGenClientModel> get topConsumers {
    final list = List<NovaGenClientModel>.from(telemetry.clients);
    list.sort((a, b) => b.totalUsedBytes.compareTo(a.totalUsedBytes));
    return list.take(6).toList();
  }
}

class NovaGenAdminNotifier extends Notifier<NovaGenAdminState> {
  final NovaGenApiService _api = NovaGenApiService();
  Timer? _autoRefreshTimer;

  @override
  NovaGenAdminState build() {
    ref.onDispose(() {
      _autoRefreshTimer?.cancel();
    });

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      fetchTelemetry(silent: true);
    });

    // Initial async fetch
    Future.microtask(() => fetchTelemetry());

    return NovaGenAdminState(telemetry: NovaGenTelemetryData.empty());
  }

  Future<void> fetchTelemetry({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final data = await _api.fetchFullTelemetry();
      state = state.copyWith(
        isLoading: false,
        telemetry: data,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        telemetry: NovaGenTelemetryData.empty(e.toString()),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}

final novagenAdminProvider =
    NotifierProvider<NovaGenAdminNotifier, NovaGenAdminState>(
  NovaGenAdminNotifier.new,
);
