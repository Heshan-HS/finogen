import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import 'widgets/desktop_metrics_row.dart';
import 'widgets/desktop_spending_overview.dart';
import 'widgets/desktop_income_expense_chart.dart';
import 'widgets/desktop_quick_actions.dart';
import 'widgets/desktop_crypto_pnl_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/desktop_recent_transactions.dart';
import 'widgets/desktop_budget_status.dart';
import 'widgets/desktop_novagen_business_card.dart';
import '../../../core/providers/goal_providers.dart';
import '../../goals/presentation/helpers/goal_category_helper.dart';
import '../../goals/presentation/widgets/add_goal_sheet.dart';
import '../../goals/presentation/widgets/add_funds_sheet.dart';
import 'widgets/desktop_accounts_card.dart';
import 'package:intl/intl.dart';

class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});
  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(ref),
                const SizedBox(height: 12),
                const DesktopMetricsRow(),
                const SizedBox(height: 24),
                // Main content area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Col 1: Spending & Recent
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const DesktopSpendingOverview(),
                          const SizedBox(height: 24),
                          const DesktopRecentTransactions(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Col 2 & 3 Grouped (Chart, Budget, Actions, Accounts) + Upgrade Banner underneath
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Col 2: Chart & Budget Status
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 320,
                                      child: DesktopIncomeExpenseChart()
                                    ),
                                    const SizedBox(height: 24),
                                    const DesktopBudgetStatus(),
                                    const SizedBox(height: 24),
                                    const DesktopNovaGenBusinessCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Col 3: Quick Actions & Add Expense & Accounts
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    const DesktopAccountsCard(),
                                    const SizedBox(height: 16),
                                    const DesktopQuickActions(),
                                    const SizedBox(height: 16),
                                    DesktopCryptoPnlCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Upgrade banner placed ONLY under Col 2 and Col 3
                          _buildUpgradeBanner(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildFinancialGoals()),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: _buildSmartInsights()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildMonthlyStats()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialGoals() {
    final fmt = NumberFormat('#,##0');
    final goalsAsync = ref.watch(goalsStreamProvider);
    final goals = goalsAsync.value ?? [];
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? const Color(0xFF0D1117) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFe2e8f0);
    final accentColor = AppColors.accent(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textMutedLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.target, color: accentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Goals',
                    style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => AddGoalSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '${goals.length} Active',
                        style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'No active goals yet',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => AddGoalSheet.show(context),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: const Text('Create Goal', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...goals.take(4).map((g) {
              final pct = g.progress;
              final color = Color(g.colorValue);
              final icon = GoalCategoryHelper.getIcon(g.iconName, g.category);

              return GestureDetector(
                onTap: () => AddFundsSheet.show(context, g, isWithdraw: false),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: color, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                g.name,
                                style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            'Rs ${fmt.format(g.currentAmount)} / Rs ${fmt.format(g.targetAmount)}',
                            style: TextStyle(color: textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFe2e8f0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct,
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}% achieved • ${g.milestoneTitle}',
                            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                          if (g.daysRemaining > 0 && !g.isCompleted)
                            Text(
                              '${g.daysRemaining}d left',
                              style: TextStyle(color: textMuted, fontSize: 9.5),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSmartInsights() {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? const Color(0xFF0D1117) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFe2e8f0);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;

    final insights = [
      {'icon': LucideIcons.trendingUp, 'color': const Color(0xFF00D4AA), 'title': 'Spending on Track', 'desc': 'Your expenses this month are 12% lower than last month. Keep it up!', 'tag': 'Positive'},
      {'icon': LucideIcons.alertCircle, 'color': const Color(0xFFF59E0B), 'title': 'Food Budget Alert', 'desc': 'You have used 78% of your Food budget with 8 days left this month.', 'tag': 'Warning'},
      {'icon': LucideIcons.piggyBank, 'color': const Color(0xFF6366F1), 'title': 'Savings Opportunity', 'desc': 'Based on your income pattern, you can save Rs 5,200 more this month.', 'tag': 'Tip'},
      {'icon': LucideIcons.repeat, 'color': const Color(0xFFEC4899), 'title': 'Recurring Payments', 'desc': '3 subscriptions totaling Rs 2,450 are renewing in the next 7 days.', 'tag': 'Reminder'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.3), AppColors.accent(context).withOpacity(0.2)]),
                borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.brain, color: Color(0xFF818CF8), size: 18)),
              const SizedBox(width: 12),
              Text('Smart Insights', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]), borderRadius: BorderRadius.circular(20)),
              child: const Text('AI Powered', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 18),
          ...insights.map((ins) {
            final color = ins['color'] as Color;
            final tagColors = {'Positive': const Color(0xFF00D4AA), 'Warning': const Color(0xFFF59E0B), 'Tip': const Color(0xFF6366F1), 'Reminder': const Color(0xFFEC4899)};
            final tagColor = tagColors[ins['tag'] as String] ?? AppColors.accent(context);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.15))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(ins['icon'] as IconData, color: color, size: 16)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(ins['title'] as String, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: tagColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Text(ins['tag'] as String, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 3),
                  Text(ins['desc'] as String, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textMutedLight, fontSize: 11, height: 1.4)),
                ])),
              ]),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats() {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? const Color(0xFF0D1117) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFe2e8f0);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? Colors.white38 : AppColors.textMutedLight;
    final textMuted2 = isDark ? Colors.white54 : const Color(0xFF94a3b8);
    final accentColor = AppColors.accent(context);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFe2e8f0);

    final fmt = NumberFormat('#,##0');
    final months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
    final incomeData = [42000.0, 48000.0, 38000.0, 52000.0, 45000.0, 50000.0];
    final expenseData = [28000.0, 32000.0, 25000.0, 38000.0, 30000.0, 26000.0];
    final maxVal = 60000.0;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(LucideIcons.barChart2, color: accentColor, size: 18)),
          const SizedBox(width: 12),
          Text('6-Month Trend', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6), Text('Income', style: TextStyle(color: textMuted2, fontSize: 11)),
          const SizedBox(width: 14),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFFF5252), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6), Text('Expense', style: TextStyle(color: textMuted2, fontSize: 11)),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: 100, child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(months.length, (i) {
            final incH = (incomeData[i] / maxVal) * 90;
            final expH = (expenseData[i] / maxVal) * 90;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 8, height: incH, decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [accentColor, accentColor.withOpacity(0.4)]),
                    borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 2),
                  Container(width: 8, height: expH, decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF5252), Color(0x66FF5252)]),
                    borderRadius: BorderRadius.circular(3))),
                ]),
                const SizedBox(height: 5),
                Text(months[i], style: TextStyle(color: textMuted, fontSize: 10)),
              ]),
            ));
          }),
        )),
        const SizedBox(height: 14),
        Divider(color: dividerColor),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _miniStat('Avg Income', 'Rs ${fmt.format(45833)}', accentColor, textMuted),
          _miniStat('Avg Expense', 'Rs ${fmt.format(29833)}', const Color(0xFFFF5252), textMuted),
          _miniStat('Avg Savings', 'Rs ${fmt.format(16000)}', const Color(0xFF00D4AA), textMuted),
        ]),
        const SizedBox(height: 14),
        Text('Top Expense Categories', style: TextStyle(color: textMuted2, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _categoryChip('Food & Groceries', 0.35, const Color(0xFFF59E0B), isDark),
        const SizedBox(height: 6),
        _categoryChip('Living & Housing', 0.28, const Color(0xFF6366F1), isDark),
        const SizedBox(height: 6),
        _categoryChip('Transport', 0.18, const Color(0xFFEC4899), isDark),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color, Color labelColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: labelColor, fontSize: 10)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _categoryChip(String name, double pct, Color color, bool isDark) {
    return Row(children: [
      SizedBox(width: 90, child: Text(name, style: TextStyle(color: isDark ? Colors.white54 : AppColors.textMutedLight, fontSize: 10), overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8),
      Expanded(child: Stack(children: [
        Container(height: 4, decoration: BoxDecoration(color: AppColors.isDark(context) ? Colors.white.withOpacity(0.06) : const Color(0xFFe2e8f0), borderRadius: BorderRadius.circular(2))),
        FractionallySizedBox(widthFactor: pct, child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
      ])),
      const SizedBox(width: 8),
      Text('${(pct * 100).round()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildTopBar(WidgetRef ref) {
    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
      }
    } catch (_) {}

    final userName = user?.displayName ?? 'Guest User';
    final userEmail = user?.email ?? 'Free Plan';
    final photoUrl = user?.photoURL;

    final isDark = AppColors.isDark(context);
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final popupBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final popupTextStyle = TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Welcome back! Here\'s your financial summary.', style: TextStyle(color: textMuted, fontSize: 14)),
          ],
        ),
        Row(
          children: [
            Icon(LucideIcons.calendar, color: textMuted, size: 16),
            const SizedBox(width: 8),
            Text(
              DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textMutedLight, fontSize: 13),
            ),
            const SizedBox(width: 24),
            PopupMenuButton<String>(
              color: popupBg,
              onSelected: (value) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: popupBg,
                    title: Text('Filter Changed', style: TextStyle(color: textPrimary)),
                    content: Text('Dashboard data has been filtered by $value.', style: TextStyle(color: textMuted)),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: AppColors.accent(context))))],
                  ),
                );
              },
              itemBuilder: (ctx) => ['This Week', 'This Month', 'Last Month', 'This Year']
                  .map((e) => PopupMenuItem(value: e, child: Text(e, style: popupTextStyle)))
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Text('This Month', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF022B1E), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronDown, color: isDark ? Colors.white54 : const Color(0xFF005A36), size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            _buildSearchBar(isDark),
            const SizedBox(width: 16),
            // Prominent Top Bar Theme Switcher
            InkWell(
              onTap: () {
                ref.read(themeModeProvider.notifier).toggle();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF022B1E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFF005A36).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark ? LucideIcons.sun : LucideIcons.moon,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF005A36),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDark ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF022B1E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: popupBg,
                    title: Text('Notice', style: TextStyle(color: textPrimary)),
                    content: Text('You have no new notifications at this time.', style: TextStyle(color: textMuted)),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: AppColors.accent(context))))],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Icon(LucideIcons.bell, color: isDark ? Colors.white : const Color(0xFF022B1E), size: 20),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: popupBg,
                    title: Text('Notice', style: TextStyle(color: textPrimary)),
                    content: Text('Profile management will be available in the next update!', style: TextStyle(color: textMuted)),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: AppColors.accent(context))))],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accent(context),
                      radius: 20,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(LucideIcons.user, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                        Text(userEmail, style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronDown, color: textMuted, size: 16),
                  ],
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      width: 300,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFf1f5f9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFe2e8f0)),
      ),
      child: TextField(
        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search transactions, categories...',
          hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textMutedLight, fontSize: 13),
          prefixIcon: Icon(LucideIcons.search, color: isDark ? Colors.white54 : AppColors.textMutedLight, size: 18),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFe2e8f0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Ctrl K', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textMutedLight, fontSize: 10)),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    final isDark = AppColors.isDark(context);
    final accentColor = AppColors.accent(context);
    final bgGradientColors = isDark
        ? const [Color(0xFF0A2A1A), Color(0xFF051510), Color(0xFF0D1117)]
        : [const Color(0xFFe8f5ed), const Color(0xFFf0faf4), const Color(0xFFf8fffe)];
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textMuted = isDark ? Colors.white38 : AppColors.textMutedLight;
    final popupBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: bgGradientColors,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.25)),
            ),
            child: Icon(LucideIcons.sparkles, color: accentColor, size: 20),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('AI Financial Insights', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text('TIP', style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  'Your spending on food is down 10% this month! Keep it up to reach your savings goal.',
                  style: TextStyle(color: textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Row(children: [
            _proChip(LucideIcons.trendingDown, 'Smart Saving', isDark, accentColor),
            const SizedBox(width: 8),
            _proChip(LucideIcons.target, 'On Track', isDark, accentColor),
          ]),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: popupBg,
                  title: Text('Notice', style: TextStyle(color: textPrimary)),
                  content: Text('AI Financial Insights is calculating your personalized report. Please wait...', style: TextStyle(color: textMuted)),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: accentColor)))],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  SizedBox(width: 6),
                  Icon(LucideIcons.arrowRight, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proChip(IconData icon, String label, bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFe8eefb),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFc7d7f5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: accentColor, size: 12),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: isDark ? Colors.white60 : AppColors.textMutedLight, fontSize: 11)),
      ]),
    );
  }
}
