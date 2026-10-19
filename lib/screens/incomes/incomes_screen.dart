import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/income.dart';
import '../../services/auth_service.dart';
import '../../services/income_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/section_header.dart';
import 'income_category_icon.dart';

/// Lista de receitas do mês (wireframe 3).
class IncomesScreen extends StatefulWidget {
  const IncomesScreen({super.key});

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  final AuthService _authService = AuthService();
  final IncomeService _incomeService = IncomeService();

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _confirmDelete(String userId, Income income) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Excluir receita?'),
        content: Text('"${income.description}" será removida.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _incomeService.delete(userId, income.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.genericError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = _authService.getCurrentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabIncomes)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed(AppRoutes.incomeForm),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: userId == null
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: EmptyState(
                  message: 'Faça login para ver suas receitas.',
                ),
              )
            : StreamBuilder<List<Income>>(
                stream: _incomeService.watchByMonth(userId, _month),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.screenPadding),
                      child: EmptyState(message: AppStrings.genericError),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildContent(userId, snapshot.data!);
                },
              ),
      ),
    );
  }

  Widget _buildContent(String userId, List<Income> incomes) {
    final double total = incomes.fold(0, (sum, i) => sum + i.amount);
    final int count = incomes.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        96,
      ),
      children: <Widget>[
        MonthSelector(
          month: _month,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TotalCard(total: total, count: count),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: AppStrings.incomesEntries),
        const SizedBox(height: AppSpacing.sm),
        if (incomes.isNotEmpty)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < incomes.length; i++) ...<Widget>[
                  if (i > 0) const Divider(),
                  _IncomeTile(
                    income: incomes[i],
                    onLongPress: () => _confirmDelete(userId, incomes[i]),
                  ),
                ],
              ],
            ),
          ),
        if (incomes.isNotEmpty) const SizedBox(height: AppSpacing.lg),
        const EmptyState(message: AppStrings.incomesEmpty),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AppStrings.incomesTotal, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                Formatters.currency(total),
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                count == 1 ? '1 lançamento' : '$count lançamentos',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income, required this.onLongPress});

  final Income income;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                incomeCategoryIcon(income.category),
                color: AppColors.primaryDark,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    income.description,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${Formatters.dayMonth(income.receivedAt)} · '
                    '${income.category.label}',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '+ ${Formatters.currency(income.amount)}',
              style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
