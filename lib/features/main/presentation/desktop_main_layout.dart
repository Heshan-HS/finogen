import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../home/presentation/desktop_home_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../transfer/presentation/transfer_screen.dart';
import '../../bills/presentation/bills_screen.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../workspace/presentation/workspace_screen.dart';
import '../../crypto/presentation/crypto_trades_screen.dart';
import 'widgets/desktop_sidebar.dart';

class DesktopMainLayout extends ConsumerStatefulWidget {
  const DesktopMainLayout({super.key});

  @override
  ConsumerState<DesktopMainLayout> createState() => _DesktopMainLayoutState();
}

class _DesktopMainLayoutState extends ConsumerState<DesktopMainLayout> {
  final List<Widget> _screens = [
    const DesktopHomeScreen(),
    const TransactionsScreen(),
    const TransferScreen(),
    const BillsScreen(),
    const AccountsScreen(),
    const ReportsScreen(),
    const BudgetScreen(),
    const GoalsScreen(),
    const WorkspaceScreen(),
    const CryptoTradesScreen(),
    const SettingsScreen(),
    const Scaffold(body: Center(child: Text('Help & Support coming soon...', style: TextStyle(color: Colors.white)))), // Index 11 for Help
  ];

  @override
  Widget build(BuildContext context) {
    final rawIndex = ref.watch(mainNavIndexProvider);
    
    // Map negative indices to our array:
    // -1 = Settings (Index 8)
    // -2 = Help (Index 9)
    int viewIndex = 0;
    if (rawIndex >= 0 && rawIndex <= 9) {
      viewIndex = rawIndex;
    } else if (rawIndex == -1) {
      viewIndex = 10;
    } else if (rawIndex == -2) {
      viewIndex = 11;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
      body: Row(
        children: [
          DesktopSidebar(
            selectedIndex: rawIndex,
            onDestinationSelected: (index) {
              ref.read(mainNavIndexProvider.notifier).setIndex(index);
            },
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark ? Colors.white10 : const Color(0xFFe2e8f0),
          ),
          Expanded(
            child: IndexedStack(
              index: viewIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
