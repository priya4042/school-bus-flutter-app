import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/models/monthly_due_model.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../utils/fee_calculator.dart';
import '../../shared/widgets/stat_card.dart';

class FeeHistoryScreen extends StatefulWidget {
  const FeeHistoryScreen({super.key});

  @override
  State<FeeHistoryScreen> createState() => _FeeHistoryScreenState();
}

class _FeeHistoryScreenState extends State<FeeHistoryScreen> {
  String? _selectedStudentId;
  String _search = '';
  bool _showFuture = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    await context.read<FeeProvider>().fetchParentDues(auth.user!.id);
  }

  Future<void> _handlePay(MonthlyDue due) async {
    final fees = context.read<FeeProvider>();
    final bundle = FeeCalculator.buildPaymentBundle(due, fees.dues);

    // Show payment bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentSheet(bundle: bundle, studentName: due.studentName ?? ''),
    );

    if (confirmed == true) {
      final txnId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      for (final id in bundle.dueIds) {
        await fees.recordPayment(id, transactionId: txnId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PAYMENT SUCCESSFUL — $txnId'),
          backgroundColor: AppColors.success,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final fees = context.watch<FeeProvider>();

    var dues = fees.dues.toList();
    if (_selectedStudentId != null) {
      dues = dues.where((d) => d.studentId == _selectedStudentId).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      dues = dues.where((d) =>
          d.monthLabel.toLowerCase().contains(q) ||
          (d.studentName?.toLowerCase().contains(q) ?? false)).toList();
    }

    final paid = dues.where((d) => d.isPaid).toList();
    final unpaid = dues.where((d) => !d.isPaid).toList();
    final totalCleared = paid.fold<double>(0, (s, d) => s + d.totalDue);
    final outstanding = unpaid.fold<double>(0, (s, d) => s + d.totalDue);
    final overdueCount = unpaid.where((d) => d.isOverdue).length;

    // Separate future scheduled
    final now = DateTime.now();
    final futureDues = unpaid.where((d) => d.dueDate.isAfter(now)).toList();
    final actionableDues = dues.where((d) => d.isPaid || (d.dueDate.isBefore(now) || d.dueDate.isAtSameMomentAs(now))).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ===== STATS =====
          Row(children: [
            Expanded(child: _statCard('TOTAL CLEARED', Formatters.currency(totalCleared), AppColors.emerald600)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('OUTSTANDING', Formatters.currency(outstanding), AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('OVERDUE', '$overdueCount', AppColors.red500)),
          ]),
          const SizedBox(height: 16),

          // ===== FILTERS =====
          Container(
            decoration: AppTheme.cardLargeDecoration,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  // Student dropdown
                  if (students.length > 1) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStudentId,
                            isExpanded: true,
                            hint: Text('ALL STUDENTS', style: AppTheme.labelSmall.copyWith(color: AppColors.slate500)),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800),
                            items: [
                              DropdownMenuItem(value: null, child: Text('ALL STUDENTS', style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800))),
                              ...students.map((s) => DropdownMenuItem(value: s.id,
                                  child: Text(s.fullName.toUpperCase(), style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)))),
                            ],
                            onChanged: (v) => setState(() => _selectedStudentId = v),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Search
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate400),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400, size: 20),
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // ===== DUES LIST =====
              if (fees.isLoading)
                const Padding(padding: EdgeInsets.all(40), child: MiniLoader())
              else if (actionableDues.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: EmptyState(icon: Icons.receipt_long_outlined, title: 'NO FEES FOUND'))
              else
                ...actionableDues.map((d) => _dueCard(d, fees.dues)),

              // ===== FUTURE SCHEDULED =====
              if (futureDues.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    GestureDetector(
                      onTap: () => setState(() => _showFuture = !_showFuture),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('FUTURE SCHEDULED (${futureDues.length})', style: AppTheme.labelSmall.copyWith(color: AppColors.slate600)),
                          Icon(_showFuture ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.slate400),
                        ]),
                      ),
                    ),
                    if (_showFuture) ...[
                      const SizedBox(height: 8),
                      ...futureDues.map((d) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.fullMonthLabel.toUpperCase(), style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
                            Text('DUE: ${Formatters.date(d.dueDate)}', style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
                          ]),
                          Text(Formatters.currencyFull(d.amount), style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate600)),
                        ]),
                      )),
                    ],
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(children: [
        Text(label, style: AppTheme.labelXs),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1, color: color)),
      ]),
    );
  }

  Widget _dueCard(MonthlyDue d, List<MonthlyDue> allDues) {
    final isPayable = !d.isPaid && FeeCalculator.isMonthPayable(d, allDues);
    final isLocked = !d.isPaid && !isPayable;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.slate50)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.fullMonthLabel.toUpperCase(), style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
            if (d.studentName != null)
              Text(d.studentName!.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
            const SizedBox(height: 4),
            StatusBadge.fromStatus(d.isPaid ? 'PAID' : d.isOverdue ? 'OVERDUE' : 'PENDING'),
            if (!d.isPaid && d.lateFee > 0)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('LATE: ${Formatters.currencyFull(d.lateFee)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.danger)),
              ),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.currencyFull(d.totalDue), style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            const SizedBox(height: 6),
            if (d.isPaid)
              Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: () => _showReceiptOptions(d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.download_rounded, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('RECEIPT', style: GoogleFonts.plusJakartaSans(
                        fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.success)),
                    ]),
                  ),
                ),
              ])
            else if (isPayable)
              GestureDetector(
                onTap: () => _handlePay(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.primaryButtonShadow(),
                  ),
                  child: Text('PAY NOW', style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                ),
              )
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_rounded, size: 10, color: AppColors.slate400),
                const SizedBox(width: 4),
                Text('PAY PREVIOUS', style: GoogleFonts.plusJakartaSans(
                  fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.slate400)),
              ]),
          ]),
        ]),
      ),
    );
  }

  void _showReceiptOptions(MonthlyDue d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('DOWNLOAD RECEIPT', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
          const SizedBox(height: 16),
          _receiptOption(Icons.picture_as_pdf_rounded, 'PDF RECEIPT', () {
            Navigator.pop(ctx);
            ReceiptService.generateAndShareReceipt(due: d, studentName: d.studentName, admissionNumber: d.admissionNumber);
          }),
          _receiptOption(Icons.description_rounded, 'TAX INVOICE', () {
            Navigator.pop(ctx);
            ReceiptService.generateAndShareReceipt(due: d, studentName: d.studentName, admissionNumber: d.admissionNumber);
          }),
          _receiptOption(Icons.receipt_rounded, 'COMPACT RECEIPT', () {
            Navigator.pop(ctx);
            ReceiptService.generateAndShareReceipt(due: d, studentName: d.studentName, admissionNumber: d.admissionNumber);
          }),
        ]),
      ),
    );
  }

  Widget _receiptOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.slate700)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate300),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ===== PAYMENT SHEET (matches PaymentPortal SELECT state) =====
class _PaymentSheet extends StatelessWidget {
  final PaymentBundle bundle;
  final String studentName;
  const _PaymentSheet({required this.bundle, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppColors.slate200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Amount display: bg-slate-50 rounded-3xl
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Column(children: [
              Text('TOTAL PAYABLE', style: AppTheme.labelSmall),
              const SizedBox(height: 8),
              Text(Formatters.currencyFull(bundle.amount), style: GoogleFonts.plusJakartaSans(
                fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -2, color: AppColors.slate800)),
            ]),
          ),
          const SizedBox(height: 16),

          // Summary
          if (bundle.explanation.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue50.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue100),
              ),
              child: Text(bundle.explanation.toUpperCase(), textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.primary)),
            ),
          const SizedBox(height: 16),

          // Breakdown stats
          Row(children: [
            _breakdownStat('MONTHS', '${bundle.monthsCount}'),
            const SizedBox(width: 8),
            _breakdownStat('BASE FEES', Formatters.currencyFull(bundle.totalBaseAmount)),
            const SizedBox(width: 8),
            _breakdownStat('LATE FEES', Formatters.currencyFull(bundle.totalLateFee),
                color: bundle.totalLateFee > 0 ? AppColors.danger : null),
          ]),
          const SizedBox(height: 16),

          // Month-wise table
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: AppColors.slate100)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('MONTH', style: AppTheme.labelXs),
                  Text('AMOUNT', style: AppTheme.labelXs),
                ]),
              ),
              ...bundle.items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate50))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(item.due.monthLabel.toUpperCase(), style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700)),
                  Text(Formatters.currencyFull(item.total), style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 24),

          // UPI button (green)
          SizedBox(
            width: double.infinity, height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF16A34A), AppColors.emerald600]),
                boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.phone_android_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('PAY VIA UPI APP', style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Card/PayU button (dark)
          SizedBox(
            width: double.infinity, height: 56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.slate900,
                boxShadow: [BoxShadow(color: AppColors.slate900.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.credit_card_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('CARD / UPI / NETBANKING', style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // SSL notice
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_rounded, size: 10, color: AppColors.slate400),
            const SizedBox(width: 4),
            Text('256-BIT SSL ENCRYPTED', style: GoogleFonts.plusJakartaSans(
              fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.slate400)),
          ]),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: AppTheme.labelSmall.copyWith(color: AppColors.slate400)),
          ),
        ]),
      ),
    );
  }

  Widget _breakdownStat(String label, String value, {Color? color}) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(children: [
        Text(label, style: AppTheme.labelXs),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: color ?? AppColors.slate800)),
      ]),
    ));
  }
}
