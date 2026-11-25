class SettingsModel {
  final bool notificationsEnabled;
  final String baseCurrency;
  final String currency; // Acts as displayCurrency
  final bool useLiveExchangeRate;
  final double manualExchangeRate;
  final String language;
  final double monthlyBudget;

  SettingsModel({
    required this.notificationsEnabled,
    required this.baseCurrency,
    required this.currency,
    required this.useLiveExchangeRate,
    required this.manualExchangeRate,
    required this.language,
    required this.monthlyBudget,
  });

  factory SettingsModel.initial() {
    return SettingsModel(
      notificationsEnabled: true,
      baseCurrency: 'LKR (Rs)',
      currency: 'USD (\$)',
      useLiveExchangeRate: false,
      manualExchangeRate: 300.0,
      language: 'English',
      monthlyBudget: 50000.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'baseCurrency': baseCurrency,
      'currency': currency,
      'useLiveExchangeRate': useLiveExchangeRate,
      'manualExchangeRate': manualExchangeRate,
      'language': language,
      'monthlyBudget': monthlyBudget,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      baseCurrency: map['baseCurrency'] ?? 'LKR (Rs)',
      currency: map['currency'] ?? 'USD (\$)',
      useLiveExchangeRate: map['useLiveExchangeRate'] ?? false,
      manualExchangeRate: (map['manualExchangeRate'] ?? 300.0).toDouble(),
      language: map['language'] ?? 'English',
      monthlyBudget: (map['monthlyBudget'] ?? 50000.0).toDouble(),
    );
  }

  SettingsModel copyWith({
    bool? notificationsEnabled,
    String? baseCurrency,
    String? currency,
    bool? useLiveExchangeRate,
    double? manualExchangeRate,
    String? language,
    double? monthlyBudget,
  }) {
    return SettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      currency: currency ?? this.currency,
      useLiveExchangeRate: useLiveExchangeRate ?? this.useLiveExchangeRate,
      manualExchangeRate: manualExchangeRate ?? this.manualExchangeRate,
      language: language ?? this.language,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}
