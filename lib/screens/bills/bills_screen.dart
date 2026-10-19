import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/bill.dart';
import '../../services/auth_service.dart';
import '../../services/bill_service.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/section_header.dart';
import 'bill_category_icon.dart';

enum _BillFilter {
  all('Todas'),
  pending('Pendentes'),
  paid('Pagas');

  const _BillFilter(this.label);

  final String label;
}

/// Lista de contas a pagar (wireframe 4).
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final AuthService _authService = AuthService();
  final BillService _billService = BillService();

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  _BillFilter _filter = _BillFilter.all;

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.genericError)));
  }

  Future<void> _togglePaid(String userId, Bill bill) async {
    try {
      await _billService.setPaid(userId, bill.id, paid: !bill.isPaid);
    } catch (_) {
      _showError();
    }
  }

  Future<void> _confirmDelete(String userId, Bill bill) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Text('"${bill.description}" será removida.'),
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
      await _billService.delete(userId, bill.id);
    } catch (_) {
      _showError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = _authService.getCurrentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Contas a Pagar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed(AppRoutes.billForm),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: userId == null
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: EmptyState(message: 'Faça login para ver suas contas.'),
              )
            : StreamBuilder<List<Bill>>(
                stream: _billService.watchByMonth(userId, _month),
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

  Widget _buildContent(String userId, List<Bill> bills) {
    final List<Bill> open = bills.where((Bill b) => !b.isPaid).toList();
    final List<Bill> paid = bills.where((Bill b) => b.isPaid).toList();
    double sum(List<Bill> list) => list.fold(0, (s, b) => s + b.amount);

    final List<Bill> visible = switch (_filter) {
      _BillFilter.all => bills,
      _BillFilter.pending => open,
      _BillFilter.paid => paid,
    };

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
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final _BillFilter filter in _BillFilter.values)
              ChoiceChip(
                label: Text(filter.label),
                selected: _filter == filter,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                shape: const StadiumBorder(),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _filter == filter
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: 'A pagar',
                total: sum(open),
                count: open.length,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SummaryCard(
                label: 'Pago no mês',
                total: sum(paid),
                count: paid.length,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: Formatters.monthYear(_month).split(' ').first),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          const EmptyState(
            message: 'Nenhuma conta aqui. Toque em + para adicionar.',
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < visible.length; i++) ...<Widget>[
                  if (i > 0) const Divider(),
                  _BillTile(
                    bill: visible[i],
                    onToggle: () => _togglePaid(userId, visible[i]),
                    onLongPress: () => _confirmDelete(userId, visible[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.total,
    required this.count,
    required this.color,
  });

  final String label;
  final double total;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.currency(total),
                style: textTheme.titleLarge?.copyWith(color: color),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              count == 1 ? '1 conta' : '$count contas',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({
    required this.bill,
    required this.onToggle,
    required this.onLongPress,
  });

  final Bill bill;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final BillStatus status = bill.statusOn(DateTime.now());

    final Color checkColor = switch (status) {
      BillStatus.paid => AppColors.success,
      BillStatus.overdue => AppColors.danger,
      BillStatus.dueTomorrow => AppColors.warning,
      BillStatus.pending => AppColors.border,
    };
    final (String badgeLabel, BadgeTone tone) = switch (status) {
      BillStatus.paid => ('Paga', BadgeTone.success),
      BillStatus.overdue => ('Atrasada', BadgeTone.danger),
      BillStatus.dueTomorrow => ('Amanhã', BadgeTone.warning),
      BillStatus.pending => ('Pendente', BadgeTone.neutral),
    };
    final String subtitle = switch (status) {
      BillStatus.paid => 'Pago em ${Formatters.dayMonth(bill.paidAt!)}',
      BillStatus.overdue => 'Venceu em ${Formatters.dayMonth(bill.dueDate)}',
      _ => 'Vence em ${Formatters.dayMonth(bill.dueDate)}',
    };

    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Semantics(
              button: true,
              label: bill.isPaid ? 'Marcar como pendente' : 'Marcar como paga',
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bill.isPaid ? AppColors.success : null,
                    border: bill.isPaid
                        ? null
                        : Border.all(color: checkColor, width: 2),
                  ),
                  child: bill.isPaid
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.textOnPrimary,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
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
                    style: textTheme.titleMedium?.copyWith(
                      decoration: bill.isPaid
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
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
      ),
    );
  }
}
