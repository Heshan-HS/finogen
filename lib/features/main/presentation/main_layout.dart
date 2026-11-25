import 'desktop_main_layout.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../workspace/presentation/workspace_screen.dart';
import '../../statistics/presentation/statistics_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../../core/providers/navigation_providers.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final Set<int> _loadedTabs = {0};

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const TransactionsScreen();
      case 2:
        return const StatisticsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    if (isDesktop) {
      return const DesktopMainLayout();
    }
    
    final currentIndex = ref.watch(mainNavIndexProvider);
    _loadedTabs.add(currentIndex);
    final isLight = !AppColors.isDark(context);

    Widget contentBody = Stack(
      children: [
        // Page-level ambient background glow
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft, 
                  radius: 1.2,
                  colors: isLight
                      ? [
                          AppColors.primaryLight.withOpacity(0.08),
                          Colors.transparent,
                        ]
                      : [
                          AppColors.primary.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Main content
        IndexedStack(
          index: currentIndex,
          children: List.generate(4, (i) {
            if (_loadedTabs.contains(i)) {
              return _buildScreen(i);
            }
            return const SizedBox.shrink();
          }),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: contentBody,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(mainNavIndexProvider.notifier).setIndex(index),
      ),
    );
  }
}
