import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NovaGenServerHealth {
  final bool isOnline;
  final int cpu;
  final int ram;
  final int disk;
  final String cpuLoad;
  final String memUsedGB;
  final String memTotalGB;
  final double uptimeSeconds;

  const NovaGenServerHealth({
    this.isOnline = false,
    this.cpu = 0,
    this.ram = 0,
    this.disk = 0,
    this.cpuLoad = '0.0',
    this.memUsedGB = '0',
    this.memTotalGB = '0',
    this.uptimeSeconds = 0,
  });

  String get uptimeFormatted {
    if (uptimeSeconds <= 0) return 'Offline';
    final duration = Duration(seconds: uptimeSeconds.toInt());
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final mins = duration.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    return '${hours}h ${mins}m';
  }

  factory NovaGenServerHealth.fromJson(Map<String, dynamic> json) {
    final sys = json['system'] as Map<String, dynamic>? ?? {};
    return NovaGenServerHealth(
      isOnline: json['status'] == 'online',
      cpu: (sys['cpu'] is num) ? (sys['cpu'] as num).toInt() : 0,
      ram: (sys['ram'] is num) ? (sys['ram'] as num).toInt() : 0,
      disk: (sys['disk'] is num) ? (sys['disk'] as num).toInt() : 0,
      cpuLoad: sys['cpuLoad']?.toString() ?? '0.0',
      memUsedGB: sys['memUsedGB']?.toString() ?? '0',
      memTotalGB: sys['memTotalGB']?.toString() ?? '0',
      uptimeSeconds: (json['uptime'] is num) ? (json['uptime'] as num).toDouble() : 0.0,
    );
  }
}

class NovaGenXuiStats {
  final int totalUsers;
  final int activeUsers;
  final int expiringSoon;
  final int expiredUsers;
  final int inactiveUsers;
  final int totalTrafficBytes;
  final String totalTrafficFormatted;
  final int monthlyTrafficBytes;
  final String monthlyTrafficFormatted;
  final int daysRemainingInMonth;

  const NovaGenXuiStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.expiringSoon = 0,
    this.expiredUsers = 0,
    this.inactiveUsers = 0,
    this.totalTrafficBytes = 0,
    this.totalTrafficFormatted = '0 TB',
    this.monthlyTrafficBytes = 0,
    this.monthlyTrafficFormatted = '0 TB',
    this.daysRemainingInMonth = 0,
  });

  factory NovaGenXuiStats.fromJson(Map<String, dynamic> json) {
    final total = (json['totalUsers'] is num) ? (json['totalUsers'] as num).toInt() : 0;
    final active = (json['activeUsers'] is num) ? (json['activeUsers'] as num).toInt() : 0;
    final expired = (json['expiredUsers'] is num) ? (json['expiredUsers'] as num).toInt() : 0;
    final expiring = (json['expiringSoon'] is num) ? (json['expiringSoon'] as num).toInt() : 0;
    final inactive = (total - active).clamp(0, total);

    return NovaGenXuiStats(
      totalUsers: total,
      activeUsers: active,
      expiringSoon: expiring,
      expiredUsers: expired,
      inactiveUsers: inactive,
      totalTrafficBytes: (json['totalTrafficBytes'] is num) ? (json['totalTrafficBytes'] as num).toInt() : 0,
      totalTrafficFormatted: json['totalTrafficFormatted']?.toString() ?? '0 TB',
      monthlyTrafficBytes: (json['monthlyTrafficBytes'] is num) ? (json['monthlyTrafficBytes'] as num).toInt() : 0,
      monthlyTrafficFormatted: json['monthlyTrafficFormatted']?.toString() ?? '0 TB',
      daysRemainingInMonth: (json['daysRemainingInMonth'] is num) ? (json['daysRemainingInMonth'] as num).toInt() : 0,
    );
  }
}

class NovaGenDualNodeStatus {
  final int germanyOnlineCount;
  final int singaporeOnlineCount;
  final List<String> germanyOnlineNames;
  final List<String> singaporeOnlineNames;

  const NovaGenDualNodeStatus({
    this.germanyOnlineCount = 0,
    this.singaporeOnlineCount = 0,
    this.germanyOnlineNames = const [],
    this.singaporeOnlineNames = const [],
  });

  int get totalOnlineCount => germanyOnlineCount + singaporeOnlineCount;

  factory NovaGenDualNodeStatus.fromJson(Map<String, dynamic> json) {
    return NovaGenDualNodeStatus(
      germanyOnlineCount: (json['germany'] is num) ? (json['germany'] as num).toInt() : 0,
      singaporeOnlineCount: (json['singapore'] is num) ? (json['singapore'] as num).toInt() : 0,
      germanyOnlineNames: (json['germanyNames'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      singaporeOnlineNames: (json['singaporeNames'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class NovaGenClientModel {
  final String id;
  final String rawEmail;
  final String name;
  final String phone;
  final bool enable;
  final bool online;
  final int expiryTime;
  final DateTime? expiryDate;
  final bool isExpired;
  final bool expiresWithin24h;
  final int totalLimitBytes;
  final int uploadBytes;
  final int downloadBytes;
  final int totalUsedBytes;
  final String inboundRemark;
  final String inboundProtocol;
  final String activeNode; // 'DE', 'SG', or 'OFFLINE'

  const NovaGenClientModel({
    required this.id,
    required this.rawEmail,
    required this.name,
    required this.phone,
    required this.enable,
    required this.online,
    required this.expiryTime,
    this.expiryDate,
    required this.isExpired,
    required this.expiresWithin24h,
    required this.totalLimitBytes,
    required this.uploadBytes,
    required this.downloadBytes,
    required this.totalUsedBytes,
    required this.inboundRemark,
    required this.inboundProtocol,
    this.activeNode = 'OFFLINE',
  });

  double get usedGB => totalUsedBytes / (1024 * 1024 * 1024);
  double get limitGB => totalLimitBytes / (1024 * 1024 * 1024);
  double get uploadGB => uploadBytes / (1024 * 1024 * 1024);
  double get downloadGB => downloadBytes / (1024 * 1024 * 1024);

  double get progressFraction {
    if (totalLimitBytes <= 0) return 0.0;
    return (totalUsedBytes / totalLimitBytes).clamp(0.0, 1.0);
  }

  int get daysUntilExpiry {
    if (expiryDate == null || expiryTime <= 0) return 999;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff;
  }

  factory NovaGenClientModel.fromJson(Map<String, dynamic> json, {List<String>? deOnlineList, List<String>? sgOnlineList}) {
    final rawEmail = json['email']?.toString() ?? '';
    
    // Strict parsing rule from AGENTS.md: split(/[\s_]+/)
    String name = rawEmail;
    String phone = '';
    final parts = rawEmail.split(RegExp(r'[\s_]+'));
    if (parts.length >= 2) {
      final lastPart = parts.last;
      if (RegExp(r'^(07|7|\+94)\d+').hasMatch(lastPart)) {
        phone = lastPart;
        name = parts.sublist(0, parts.length - 1).join(' ');
      } else {
        name = parts.join(' ');
      }
    }

    DateTime? expDate;
    if (json['expiryDate'] != null) {
      try {
        expDate = DateTime.parse(json['expiryDate'].toString());
      } catch (_) {}
    }

    String node = 'OFFLINE';
    final nameLower = name.toLowerCase().trim();
    if (deOnlineList != null && deOnlineList.any((n) => n.toLowerCase() == nameLower)) {
      node = 'DE';
    } else if (sgOnlineList != null && sgOnlineList.any((n) => n.toLowerCase() == nameLower)) {
      node = 'SG';
    } else if (json['online'] == true) {
      node = 'DE';
    }

    return NovaGenClientModel(
      id: json['id']?.toString() ?? '',
      rawEmail: rawEmail,
      name: name.isEmpty ? 'Client' : name,
      phone: phone,
      enable: json['enable'] == true,
      online: node != 'OFFLINE',
      expiryTime: (json['expiryTime'] is num) ? (json['expiryTime'] as num).toInt() : 0,
      expiryDate: expDate,
      isExpired: json['isExpired'] == true,
      expiresWithin24h: json['expiresWithin24h'] == true,
      totalLimitBytes: (json['totalFlow'] is num) ? (json['totalFlow'] as num).toInt() : 0,
      uploadBytes: (json['uploadBytes'] is num) ? (json['uploadBytes'] as num).toInt() : 0,
      downloadBytes: (json['downloadBytes'] is num) ? (json['downloadBytes'] as num).toInt() : 0,
      totalUsedBytes: (json['totalUsedBytes'] is num) ? (json['totalUsedBytes'] as num).toInt() : 0,
      inboundRemark: json['inboundRemark']?.toString() ?? 'NovaGen SpeedNet',
      inboundProtocol: json['inboundProtocol']?.toString() ?? 'vless',
      activeNode: node,
    );
  }
}

class NovaGenTelemetryData {
  final bool isConnected;
  final String? errorMessage;
  final NovaGenServerHealth health;
  final NovaGenXuiStats stats;
  final NovaGenDualNodeStatus dualNodes;
  final List<NovaGenClientModel> clients;
  final DateTime lastUpdated;

  NovaGenTelemetryData({
    required this.isConnected,
    this.errorMessage,
    required this.health,
    required this.stats,
    required this.dualNodes,
    required this.clients,
    required this.lastUpdated,
  });

  factory NovaGenTelemetryData.empty([String? error]) {
    return NovaGenTelemetryData(
      isConnected: false,
      errorMessage: error,
      health: const NovaGenServerHealth(),
      stats: const NovaGenXuiStats(),
      dualNodes: const NovaGenDualNodeStatus(),
      clients: const [],
      lastUpdated: DateTime.now(),
    );
  }
}

class NovaGenApiService {
  static final NovaGenApiService _instance = NovaGenApiService._internal();
  factory NovaGenApiService() => _instance;
  NovaGenApiService._internal();

  static const String baseUrl = 'http://152.53.236.30:5000';
  static const String _tokenPrefKey = 'novagen_api_jwt_token';

  String? _cachedToken;
  DateTime? _tokenExpiry;

  /// Authenticate and retrieve JWT token
  Future<String?> getValidToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedToken != null) {
      if (_tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
        return _cachedToken;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!forceRefresh) {
        final saved = prefs.getString(_tokenPrefKey);
        if (saved != null && saved.isNotEmpty) {
          _cachedToken = saved;
          return saved;
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'heshan67hh',
          'password': 'Heshan@###67hhh20017',
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          final token = data['token'].toString();
          _cachedToken = token;
          _tokenExpiry = DateTime.now().add(const Duration(days: 6));
          await prefs.setString(_tokenPrefKey, token);
          return token;
        }
      }
    } catch (e) {
      debugPrint('[NovaGenApiService] Login error: $e');
    }
    return _cachedToken;
  }

  /// Perform Read-Only GET request
  Future<Map<String, dynamic>?> _get(String endpoint) async {
    final token = await getValidToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Re-authenticate once if expired
        final freshToken = await getValidToken(forceRefresh: true);
        if (freshToken != null) {
          final retry = await http.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $freshToken',
            },
          ).timeout(const Duration(seconds: 6));
          if (retry.statusCode == 200) {
            return jsonDecode(retry.body) as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('[NovaGenApiService] GET $endpoint error: $e');
    }
    return null;
  }

  /// Fetch all telemetry in parallel with zero server load & maximum safety
  Future<NovaGenTelemetryData> fetchFullTelemetry() async {
    try {
      final results = await Future.wait([
        _get('/api/health'),
        _get('/api/xui/stats'),
        _get('/api/xui/servers-online'),
        _get('/api/xui/clients'),
      ]);

      final healthJson = results[0];
      final statsJson = results[1];
      final onlineJson = results[2];
      final clientsJson = results[3];

      final isServerAlive = healthJson != null || statsJson != null;
      if (!isServerAlive) {
        return NovaGenTelemetryData.empty('Cannot connect to Netcup Server (152.53.236.30:5000)');
      }

      final health = healthJson != null
          ? NovaGenServerHealth.fromJson(healthJson)
          : const NovaGenServerHealth();

      final stats = (statsJson != null && statsJson['data'] != null)
          ? NovaGenXuiStats.fromJson(statsJson['data'])
          : const NovaGenXuiStats();

      final dualNodes = (onlineJson != null && onlineJson['data'] != null)
          ? NovaGenDualNodeStatus.fromJson(onlineJson['data'])
          : const NovaGenDualNodeStatus();

      List<NovaGenClientModel> clients = [];
      if (clientsJson != null && clientsJson['data'] is List) {
        final list = clientsJson['data'] as List;
        clients = list.map((c) => NovaGenClientModel.fromJson(
          c as Map<String, dynamic>,
          deOnlineList: dualNodes.germanyOnlineNames,
          sgOnlineList: dualNodes.singaporeOnlineNames,
        )).toList();

        // Sort: Online clients first, then by highest traffic usage descending
        clients.sort((a, b) {
          if (a.online != b.online) return a.online ? -1 : 1;
          return b.totalUsedBytes.compareTo(a.totalUsedBytes);
        });
      }

      return NovaGenTelemetryData(
        isConnected: true,
        health: health,
        stats: stats,
        dualNodes: dualNodes,
        clients: clients,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return NovaGenTelemetryData.empty(e.toString());
    }
  }
}
