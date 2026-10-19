import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/bill.dart';
import '../../services/auth_service.dart';
import '../../services/bill_service.dart';
import '../../widgets/app_text_field.dart';

/// Formulário de nova conta a pagar (wireframe 7).
class BillFormScreen extends StatefulWidget {
  const BillFormScreen({super.key});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final AuthService _authService = AuthService();
  final BillService _billService = BillService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  late DateTime _dueDate = _today();
  BillCategory _category = BillCategory.services;
  bool _repeatMonthly = false;
  bool _isSaving = false;

  static DateTime _today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = Formatters.fullDate(_dueDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.bills);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      _dueDate = picked;
      _dateController.text = Formatters.fullDate(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String? userId = _authService.getCurrentUser?.uid;
    if (userId == null) {
      _showMessage('Faça login para registrar contas.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _billService.create(
        userId,
        Bill(
          id: '',
          amount: CurrencyInputFormatter.parse(_amountController.text),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          category: _category,
        ),
        repeatMonthly: _repeatMonthly,
      );
      if (mounted) _goBack();
    } catch (_) {
      _showMessage(AppStrings.genericError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: const Text('Nova conta a pagar'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppTextField(
                        label: 'Valor',
                        controller: _amountController,
                        hintText: '0,00',
                        prefixText: r'R$ ',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: <TextInputFormatter>[
                          CurrencyInputFormatter(),
                        ],
                        validator: Validators.amount,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Descrição',
                        controller: _descriptionController,
                        hintText: 'Ex.: Aluguel, internet…',
                        prefixIcon: Icons.notes_rounded,
                        textInputAction: TextInputAction.done,
                        validator: (String? v) =>
                            Validators.required(v, field: 'A descrição'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Vencimento',
                        controller: _dateController,
                        prefixIcon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Categoria', style: textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          for (final BillCategory category
                              in BillCategory.values)
                            ChoiceChip(
                              label: Text(category.label),
                              selected: _category == category,
                              showCheckmark: false,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              shape: const StadiumBorder(),
                              labelStyle: textTheme.labelLarge?.copyWith(
                                color: _category == category
                                    ? AppColors.textOnPrimary
                                    : AppColors.textPrimary,
                              ),
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        child: SwitchListTile(
                          value: _repeatMonthly,
                          onChanged: (bool v) =>
                              setState(() => _repeatMonthly = v),
                          activeTrackColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          title: Text(
                            'Repetir todo mês',
                            style: textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'Cria a conta automaticamente nos próximos meses',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Text('Salvar conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
