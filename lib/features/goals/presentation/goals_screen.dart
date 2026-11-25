import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/goal_providers.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/repositories/goal_repository.dart';
import 'helpers/goal_category_helper.dart';
import 'widgets/add_goal_sheet.dart';
import 'widgets/add_funds_sheet.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedFilter = 'all'; // 'all', 'active', 'completed', or category key

  // Signature Home Screen Dark Emerald Palette
  static const Color darkEmeraldDeep = Color(0xFF005A36);
  static const Color darkEmeraldLight = Color(0xFF007A4D);
  static const Color darkEmeraldForest = Color(0xFF003823);
  static const Color darkEmeraldObsidian = Color(0xFF001E13);

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final currency = ref.watch(currencySymbolProvider);
    final decimalFormat = NumberFormat('#,##0.00');
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : AppColors.bg(context),
      body: Stack(
        children: [
          // Ambient luxury background glow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.6, -0.7),
                    radius: 1.1,
                    colors: [
                      darkEmeraldDeep.withValues(alpha: isDark ? 0.20 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, goalsAsync.value?.length ?? 0),
                Expanded(
                  child: goalsAsync.when(
                    data: (goals) {
                      if (goals.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      // Calculate aggregate statistics for the Command Center Hero
                      double totalTarget = 0.0;
                      double totalSaved = 0.0;
                      int completedCount = 0;
                      double totalDailyRequired = 0.0;

                      for (var g in goals) {
                        totalTarget += g.targetAmount;
                        totalSaved += g.currentAmount;
                        if (g.isCompleted) completedCount++;
                        totalDailyRequired += g.dailyRequired;
                      }

                      final double overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
                      final double totalRemaining = (totalTarget - totalSaved).clamp(0.0, double.infinity);
                      final double totalMonthlyRequired = totalDailyRequired * 30.0;

                      // Filter goals
                      final filteredGoals = goals.where((g) {
                        if (_selectedFilter == 'all') return true;
                        if (_selectedFilter == 'active') return !g.isCompleted;
                        if (_selectedFilter == 'completed') return g.isCompleted;
                        return g.category == _selectedFilter;
                      }).toList();

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(goalsStreamProvider);
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 90),
                          children: [
                            // 1. Savings Command Center (Matching Home Screen Total Balance Card)
                            _buildCommandCenterHero(
                              context,
                              currency: currency,
                              totalSaved: totalSaved,
                              totalTarget: totalTarget,
                              totalRemaining: totalRemaining,
                              overallProgress: overallProgress,
                              completedCount: completedCount,
                              activeCount: goals.length - completedCount,
                              monthlyPacing: totalMonthlyRequired,
                              decimalFormat: decimalFormat,
                            ),
                            const SizedBox(height: 20),

                            // 2. Filter Tabs
                            _buildFilterRow(goals),
                            const SizedBox(height: 16),

                            // 3. Goals Bento List
                            if (filteredGoals.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                alignment: Alignment.center,
                                child: Text(
                                  'No goals match the selected filter',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ...filteredGoals.map((g) => _buildGoalCard(context, g, currency, decimalFormat)),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: darkEmeraldDeep),
                    ),
                    error: (e, s) => Center(
                      child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalGoals) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle in Expanded (prevents horizontal squeeze or pushing the right button off)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Saving Goals',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: darkEmeraldDeep.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: darkEmeraldDeep.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '$totalGoals Active',
                        style: const TextStyle(
                          color: darkEmeraldDeep,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Milestones & Wealth Locks',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Premium Dark Green "+ New Goal" Button (Crisp, Perfectly sized, Never Cropped)
          GestureDetector(
            onTap: () => AddGoalSheet.show(context),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    darkEmeraldLight,
                    darkEmeraldDeep,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF004F32).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, color: Colors.white, size: 16),
                  SizedBox(width: 5),
                  Text(
                    'New Goal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandCenterHero(
    BuildContext context, {
    required String currency,
    required double totalSaved,
    required double totalTarget,
    required double totalRemaining,
    required double overallProgress,
    required int completedCount,
    required int activeCount,
    required double monthlyPacing,
    required NumberFormat decimalFormat,
  }) {
    final progressPct = (overallProgress * 100).toInt();

    // Matching the Home Screen Total Balance Card exactly!
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            darkEmeraldLight,    // 0xFF007A4D
            darkEmeraldDeep,     // 0xFF005837
            darkEmeraldForest,   // 0xFF003823
            darkEmeraldObsidian, // 0xFF001E13
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004F32).withValues(alpha: 0.38),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: const Color(0xFF00291B).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient soft circles (matching Home Balance Card)
            Positioned(
              top: -35,
              right: -35,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -45,
              left: -25,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Shield Icon + Title + Funded Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SAVINGS COMMAND CENTER',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Total Wealth Locked',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '$progressPct% Funded',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Big Amount Row (Crisp White High Contrast)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$currency ${decimalFormat.format(totalSaved)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'of $currency ${decimalFormat.format(totalTarget)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Glowing Multi-Color Progress Bar (Home palette)
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: overallProgress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFC8F73A), // Bright lime-glow
                                Color(0xFF86F278), // Fresh spring green
                                Color(0xFF4EDBA4), // Crisp mint
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF86F278).withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Balanced 2-Metric Sub Bar (Zero-Overflow Responsive Frosted Container)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildHeroSubMetric(
                            label: 'Remaining Target',
                            value: '$currency ${NumberFormat('#,##0').format(totalRemaining)}',
                            icon: LucideIcons.target,
                            iconColor: const Color(0xFFFCD34D),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 26,
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHeroSubMetric(
                            label: monthlyPacing > 0 ? 'Required Pace' : 'Vaults Status',
                            value: monthlyPacing > 0
                                ? '+$currency${NumberFormat('#,##0').format(monthlyPacing)}/mo'
                                : '$activeCount In Progress • $completedCount Done',
                            icon: monthlyPacing > 0 ? LucideIcons.sparkles : LucideIcons.checkCircle2,
                            iconColor: const Color(0xFF93C5FD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSubMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(List<GoalModel> allGoals) {
    final isDark = AppColors.isDark(context);

    final filters = [
      {'key': 'all', 'label': 'All Vaults (${allGoals.length})'},
      {'key': 'active', 'label': 'In Progress'},
      {'key': 'completed', 'label': 'Conquered 👑'},
      {'key': 'emergency', 'label': 'Emergency'},
      {'key': 'tech', 'label': 'Tech & Gear'},
      {'key': 'novagen', 'label': 'NovaGen'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            darkEmeraldLight,
                            darkEmeraldDeep,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? darkEmeraldDeep
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF004F32).withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    GoalModel goal,
    String currency,
    NumberFormat decimalFormat,
  ) {
    final isDark = AppColors.isDark(context);
    final categoryDef = GoalCategoryHelper.getCategory(goal.category);
    final progressPct = (goal.progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: goal.isCompleted
                ? darkEmeraldDeep.withValues(alpha: 0.5)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
            width: goal.isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Title, Category, Priority, Options Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: darkEmeraldDeep.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: darkEmeraldDeep.withValues(alpha: 0.25)),
                  ),
                  child: Icon(
                    GoalCategoryHelper.getIcon(goal.iconName, goal.category),
                    color: darkEmeraldDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (goal.priority == 'high')
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'HIGH',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            categoryDef.label,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (goal.deadline != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            Text(
                              goal.daysRemaining > 0
                                  ? '${goal.daysRemaining}d left'
                                  : (goal.isCompleted ? 'Goal Conquered' : 'Past deadline'),
                              style: TextStyle(
                                color: goal.daysRemaining <= 7 && !goal.isCompleted
                                    ? Colors.redAccent
                                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    size: 18,
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'deposit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.plusCircle, size: 16, color: darkEmeraldDeep),
                          SizedBox(width: 8),
                          Text('Deposit Funds'),
                        ],
                      ),
                    ),
                    if (goal.currentAmount > 0)
                      const PopupMenuItem(
                        value: 'withdraw',
                        child: Row(
                          children: [
                            Icon(LucideIcons.arrowUpRight, size: 16, color: Colors.orangeAccent),
                            SizedBox(width: 8),
                            Text('Withdraw Cash'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'adjust',
                      child: Row(
                        children: [
                          Icon(LucideIcons.sliders, size: 16, color: Color(0xFF8B5CF6)),
                          SizedBox(width: 8),
                          Text('Fix / Set Balance'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.edit2, size: 16, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text('Edit Goal'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Delete Vault', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'deposit') {
                      AddFundsSheet.show(context, goal, initialAction: FundAction.deposit);
                    } else if (val == 'withdraw') {
                      AddFundsSheet.show(context, goal, initialAction: FundAction.withdraw);
                    } else if (val == 'adjust') {
                      AddFundsSheet.show(context, goal, initialAction: FundAction.adjust);
                    } else if (val == 'edit') {
                      AddGoalSheet.show(context, goal: goal);
                    } else if (val == 'delete') {
                      _showDeleteDialog(context, goal);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Middle Numbers Row (Expanded & FittedBox for zero overflow)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$currency ${decimalFormat.format(goal.currentAmount)}',
                          style: TextStyle(
                            color: isDark ? Colors.white : darkEmeraldDeep,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: $currency ${decimalFormat.format(goal.targetAmount)}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: darkEmeraldDeep.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: darkEmeraldDeep.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progressPct%',
                        style: const TextStyle(
                          color: darkEmeraldDeep,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${goal.milestoneTitle}',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1E293B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Milestone Progress Bar (Dark Emerald Gradient)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: goal.progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          darkEmeraldLight,
                          darkEmeraldDeep,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF004F32).withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Smart Pacing Forecast Banner
            if (!goal.isCompleted && goal.dailyRequired > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, size: 13, color: darkEmeraldDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Save $currency${NumberFormat('#,##0').format(goal.dailyRequired)}/day (or $currency${NumberFormat('#,##0').format(goal.monthlyRequired)}/mo) to hit deadline.',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF334155),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (goal.isCompleted)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: darkEmeraldDeep.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: darkEmeraldDeep.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 14, color: darkEmeraldDeep),
                    SizedBox(width: 8),
                    Text(
                      '👑 Milestone Accomplished! 100% Target Met.',
                      style: TextStyle(
                        color: darkEmeraldDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Action Row: Proportional 3-Button Layout with zero overflow
            Row(
              children: [
                _buildQuickDepositBtn(context, goal, 1000),
                const SizedBox(width: 8),
                _buildQuickDepositBtn(context, goal, 5000),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: () => AddFundsSheet.show(context, goal, initialAction: FundAction.deposit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            darkEmeraldLight,
                            darkEmeraldDeep,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF004F32).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.plusCircle, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              goal.isCompleted ? 'Add More' : 'Deposit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDepositBtn(BuildContext context, GoalModel goal, double amount) {
    final isDark = AppColors.isDark(context);

    return Expanded(
      flex: 3,
      child: GestureDetector(
        onTap: () async {
          final repo = ref.read(goalRepositoryProvider);
          final previousAmount = goal.currentAmount;
          final updated = goal.copyWith(currentAmount: previousAmount + amount);
          await repo.updateGoal(updated);
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1E293B),
                content: Text('Deposited +Rs ${NumberFormat('#,##0').format(amount)} to ${goal.name}!'),
                action: SnackBarAction(
                  label: 'UNDO',
                  textColor: const Color(0xFFC8F73A),
                  onPressed: () async {
                    await repo.updateGoal(goal.copyWith(currentAmount: previousAmount));
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9.5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '+Rs ${NumberFormat('#,##0').format(amount)}',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: darkEmeraldDeep.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: darkEmeraldDeep.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF004F32).withValues(alpha: 0.2), blurRadius: 20),
                ],
              ),
              child: const Icon(LucideIcons.target, size: 32, color: darkEmeraldDeep),
            ),
            const SizedBox(height: 20),
            Text(
              'No Saving Vaults Yet',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first goal to unlock wealth forecasting, milestone rewards, and smart daily pacing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => AddGoalSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      darkEmeraldLight,
                      darkEmeraldDeep,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004F32).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plusCircle, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Create Goal Vault',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text('Delete Goal Vault', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${goal.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(goalRepositoryProvider).deleteGoal(goal.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
