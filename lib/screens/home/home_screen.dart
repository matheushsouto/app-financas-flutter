import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/bill.dart';
import '../../models/income.dart';
import '../../services/auth_service.dart';
import '../../services/bill_service.dart';
import '../../services/income_service.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../bills/bill_category_icon.dart';

/// Tela inicial com o resumo do mês (wireframe 2).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _upcomingLimit = 3;

  final AuthService _authService = AuthService();
  final IncomeService _incomeService = IncomeService();
  final BillService _billService = BillService();

  final DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  Stream<List<Income>>? _incomes;
  Stream<List<Bill>>? _bills;

  @override
  void initState() {
    super.initState();
    final String? userId = _authService.getCurrentUser?.uid;
    if (userId != null) {
      _incomes = _incomeService.watchByMonth(userId, _month);
      _bills = _billService.watchByMonth(userId, _month);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    context.goNamed(AppRoutes.signIn);
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  String _userName() {
    final User? user = _authService.getCurrentUser;
    final String? name = user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final String? email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: (_incomes == null || _bills == null)
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: EmptyState(message: 'Faça login para ver seu resumo.'),
              )
            : StreamBuilder<List<Income>>(
                stream: _incomes,
                builder: (context, incomesSnap) {
                  return StreamBuilder<List<Bill>>(
                    stream: _bills,
                    builder: (context, billsSnap) {
                      if (incomesSnap.hasError || billsSnap.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.screenPadding),
                          child: EmptyState(message: AppStrings.genericError),
                        );
                      }
                      if (!incomesSnap.hasData || !billsSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildContent(incomesSnap.data!, billsSnap.data!);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildContent(List<Income> incomes, List<Bill> bills) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final double incomeTotal = incomes.fold(0, (s, i) => s + i.amount);
    final double billsTotal = bills.fold(0, (s, b) => s + b.amount);
    final List<Bill> upcoming = bills
        .where((Bill b) => !b.isPaid)
        .take(_upcomingLimit)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _greeting(),
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _userName(),
                    style: textTheme.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Material(
              color: AppColors.surface,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.border),
              ),
              child: IconButton(
                tooltip: 'Sair',
                constraints: const BoxConstraints.tightFor(
                  width: 52,
                  height: 52,
                ),
                onPressed: _signOut,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _BalanceCard(
          monthName: Formatters.monthYear(_month).split(' ').first,
          balance: incomeTotal - billsTotal,
          incomes: incomeTotal,
          bills: billsTotal,
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Próximos vencimentos',
          actionLabel: 'Ver todas',
          onActionPressed: () => context.goNamed(AppRoutes.bills),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (upcoming.isEmpty)
          const EmptyState(message: 'Nenhuma conta pendente neste mês.')
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < upcoming.length; i++) ...<Widget>[
                  if (i > 0) const Divider(),
                  _UpcomingTile(bill: upcoming[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        _TipCard(incomes: incomeTotal, bills: billsTotal),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.monthName,
    required this.balance,
    required this.incomes,
    required this.bills,
  });

  final String monthName;
  final double balance;
  final double incomes;
  final double bills;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color soft = AppColors.textOnPrimary.withValues(alpha: 0.8);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Saldo de ${monthName.toLowerCase()}',
            style: textTheme.bodyLarge?.copyWith(color: soft),
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.currency(balance),
              style: textTheme.displayLarge?.copyWith(
                color: AppColors.textOnPrimary,
                fontSize: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _BalanceMini(label: 'Receitas', value: incomes),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _BalanceMini(label: 'Contas', value: bills),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMini extends StatelessWidget {
  const _BalanceMini({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.currency(value),
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final BillStatus status = bill.statusOn(DateTime.now());

    final (String badgeLabel, BadgeTone tone) = switch (status) {
      BillStatus.paid => ('Paga', BadgeTone.success),
      BillStatus.overdue => ('Atrasada', BadgeTone.danger),
      BillStatus.dueTomorrow => ('Amanhã', BadgeTone.warning),
      BillStatus.pending => ('Pendente', BadgeTone.success),
    };
    final String subtitle = switch (status) {
      BillStatus.overdue => 'Venceu em ${Formatters.dayMonth(bill.dueDate)}',
      BillStatus.dueTomorrow =>
        'Vence amanhã · ${Formatters.dayMonth(bill.dueDate)}',
      _ => 'Vence em ${Formatters.dayMonth(bill.dueDate)}',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              billCategoryIcon(bill.category),
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  bill.description,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                Formatters.currency(bill.amount),
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppBadge(label: badgeLabel, tone: tone),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.incomes, required this.bills});

  final double incomes;
  final double bills;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String message = incomes <= 0
        ? 'Registre suas receitas do mês para ver quanto já está '
              'comprometido com contas.'
        : 'Você já comprometeu ${(bills / incomes * 100).round()}% das '
              'receitas do mês. Tente reservar 10% antes de pagar as contas.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Dica do guia',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
