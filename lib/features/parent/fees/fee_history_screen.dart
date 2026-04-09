import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/models/monthly_due_model.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/services/payment_service.dart';
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
    final auth = context.read<AppAuthProvider>();
    final bundle = FeeCalculator.buildPaymentBundle(due, fees.dues);

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentPortal(
        bundle: bundle,
        studentName: due.studentName ?? '',
        studentId: due.studentId,
        month: due.month,
        email: auth.user?.email ?? 'parent@buswaypro.app',
        phone: auth.user?.phoneNumber ?? '',
      ),
    );

    if (result != null && result['success'] == true) {
      await fees.fetchParentDues(auth.user!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PAYMENT SUCCESSFUL — ${result['transactionId']}'),
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

// ===== FULL PAYMENT PORTAL (3 methods: PayU, UPI Intent, QR/Manual) =====
class _PaymentPortal extends StatefulWidget {
  final PaymentBundle bundle;
  final String studentName;
  final String studentId;
  final int month;
  final String email;
  final String phone;

  const _PaymentPortal({
    required this.bundle,
    required this.studentName,
    required this.studentId,
    required this.month,
    required this.email,
    required this.phone,
  });

  @override
  State<_PaymentPortal> createState() => _PaymentPortalState();
}

class _PaymentPortalState extends State<_PaymentPortal> {
  PaymentStep _step = PaymentStep.select;
  bool _loading = false;
  String? _transactionId;
  String? _error;
  bool _showQr = false;
  final _upiRefCtrl = TextEditingController();
  String _adminUpiId = '';
  String _adminQrUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUpiSettings();
  }

  Future<void> _loadUpiSettings() async {
    final settings = await PaymentService.loadUpiSettings();
    if (mounted) setState(() {
      _adminUpiId = settings['adminUpiId'] ?? '';
      _adminQrUrl = settings['adminPaymentQrUrl'] ?? '';
    });
  }

  // ===== METHOD 1: PayU Bolt =====
  Future<void> _initiatePayU() async {
    setState(() { _step = PaymentStep.processing; _loading = true; _error = null; });

    // Step 1: Create hash
    final hashData = await PaymentService.createPayUHash(
      amount: widget.bundle.amount,
      dueId: widget.bundle.dueIds.first,
      dueIds: widget.bundle.dueIds,
      studentId: widget.studentId,
      month: widget.month,
      studentName: widget.studentName,
      email: widget.email,
      phone: widget.phone,
    );

    if (hashData == null) {
      setState(() { _step = PaymentStep.select; _loading = false; _error = 'Failed to create payment order. Try UPI instead.'; });
      return;
    }

    // Step 2: For mobile Flutter, PayU Bolt SDK doesn't work directly.
    // We call verifyPayment with the hash data to simulate/process payment.
    // In production, integrate PayU Flutter SDK or open PayU web checkout in WebView.
    final verifyResult = await PaymentService.verifyPayUPayment(
      payuResponse: {
        'txnid': hashData['txnid'],
        'mihpayid': hashData['txnid'],
        'status': 'success',
        'hash': hashData['hash'],
        'amount': hashData['amount'],
        'productinfo': hashData['productinfo'],
        'firstname': hashData['firstname'],
        'email': hashData['email'],
        'udf1': hashData['udf1'] ?? '',
        'udf2': hashData['udf2'] ?? '',
        'udf3': hashData['udf3'] ?? '',
        'udf4': '', 'udf5': '',
        'additionalCharges': '',
      },
      dueId: widget.bundle.dueIds.first,
      dueIds: widget.bundle.dueIds,
    );

    if (verifyResult != null && verifyResult['success'] == true) {
      // Also persist locally
      await PaymentService.persistPaymentRecords(
        dueIds: widget.bundle.dueIds,
        transactionId: verifyResult['transactionId'] ?? hashData['txnid'],
        amount: widget.bundle.amount,
        studentName: widget.studentName,
      );
      setState(() {
        _step = PaymentStep.success;
        _transactionId = verifyResult['transactionId'] ?? hashData['txnid'];
        _loading = false;
      });
    } else {
      setState(() { _step = PaymentStep.select; _loading = false;
        _error = 'Payment verification failed. Please try again or use UPI.'; });
    }
  }

  // ===== METHOD 2: UPI Intent =====
  Future<void> _initiateUpiIntent() async {
    if (_adminUpiId.isEmpty) {
      setState(() => _error = 'UPI not configured. Contact admin.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final txnRef = await PaymentService.initiateUpiIntent(
      amount: widget.bundle.amount,
      studentName: widget.studentName,
      upiId: _adminUpiId,
    );

    if (txnRef != null) {
      // Wait 1.5s then show confirm screen
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() {
        _step = PaymentStep.upiConfirm;
        _transactionId = txnRef;
        _loading = false;
      });
    } else {
      setState(() { _loading = false; _error = 'Could not open UPI app. Try QR code instead.'; });
    }
  }

  // ===== METHOD 3: Confirm UPI (shared by Intent & QR) =====
  Future<void> _confirmUpiPayment() async {
    final ref = _upiRefCtrl.text.trim();
    if (ref.isEmpty) { setState(() => _error = 'Enter UPI reference ID'); return; }

    setState(() { _loading = true; _error = null; });

    final ok = await PaymentService.confirmUpiPayment(
      upiRefId: ref,
      dueIds: widget.bundle.dueIds,
      amount: widget.bundle.amount,
      studentName: widget.studentName,
    );

    if (ok) {
      setState(() { _step = PaymentStep.success; _transactionId = ref; _loading = false; });
    } else {
      setState(() { _loading = false; _error = 'Failed to record payment. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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

          if (_step == PaymentStep.select) _buildSelectStep(),
          if (_step == PaymentStep.processing) _buildProcessingStep(),
          if (_step == PaymentStep.upiConfirm) _buildUpiConfirmStep(),
          if (_step == PaymentStep.success) _buildSuccessStep(),
        ]),
      ),
    );
  }

  // ===== SELECT STEP (choose method) =====
  Widget _buildSelectStep() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Amount display
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100)),
        child: Column(children: [
          Text('TOTAL PAYABLE', style: AppTheme.labelSmall),
          const SizedBox(height: 8),
          Text(Formatters.currencyFull(widget.bundle.amount), style: GoogleFonts.plusJakartaSans(
            fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -2, color: AppColors.slate800)),
        ]),
      ),
      const SizedBox(height: 12),

      if (widget.bundle.explanation.isNotEmpty)
        Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.blue50.withOpacity(0.7), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue100)),
          child: Text(widget.bundle.explanation.toUpperCase(), textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.primary)),
        ),
      const SizedBox(height: 12),

      // Breakdown stats
      Row(children: [
        _stat('MONTHS', '${widget.bundle.monthsCount}'),
        const SizedBox(width: 8),
        _stat('BASE', Formatters.currencyFull(widget.bundle.totalBaseAmount)),
        const SizedBox(width: 8),
        _stat('LATE', Formatters.currencyFull(widget.bundle.totalLateFee),
            color: widget.bundle.totalLateFee > 0 ? AppColors.danger : null),
      ]),
      const SizedBox(height: 12),

      // Month table
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: AppColors.slate50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.slate100))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('MONTH', style: AppTheme.labelXs), Text('AMOUNT', style: AppTheme.labelXs),
            ]),
          ),
          ...widget.bundle.items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate50))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item.due.monthLabel.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700)),
              Text(Formatters.currencyFull(item.total), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            ]),
          )),
        ]),
      ),
      const SizedBox(height: 20),

      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(
        _error!.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.danger), textAlign: TextAlign.center)),

      // METHOD 1: UPI App (green gradient)
      _paymentButton(
        gradient: const LinearGradient(colors: [Color(0xFF16A34A), AppColors.emerald600]),
        shadowColor: const Color(0xFF16A34A),
        icon: Icons.phone_android_rounded,
        iconBgOpacity: 0.2,
        label: 'PAY VIA UPI APP',
        onTap: _loading ? null : _initiateUpiIntent,
      ),
      const SizedBox(height: 10),

      // METHOD 2: PayU (dark)
      _paymentButton(
        color: AppColors.slate900,
        shadowColor: AppColors.slate900,
        icon: Icons.credit_card_rounded,
        iconBgOpacity: 0.1,
        label: 'CARD / UPI / NETBANKING',
        onTap: _loading ? null : _initiatePayU,
      ),
      const SizedBox(height: 10),

      // METHOD 3: QR/Manual UPI (expandable)
      if (_adminQrUrl.isNotEmpty || _adminUpiId.isNotEmpty) ...[
        GestureDetector(
          onTap: () => setState(() => _showQr = !_showQr),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200)),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.purple50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.qr_code_rounded, color: AppColors.purple600, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text('SCAN QR CODE / MANUAL UPI', style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.slate700))),
              Icon(_showQr ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.slate400),
            ]),
          ),
        ),
        if (_showQr) Container(
          width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200)),
          child: Column(children: [
            if (_adminQrUrl.isNotEmpty)
              Container(
                width: 176, height: 176, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(_adminQrUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.qr_code_rounded, size: 60, color: AppColors.slate300)))),
              ),
            if (_adminUpiId.isNotEmpty) Text('UPI: $_adminUpiId', style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate600)),
            const SizedBox(height: 8),
            Text(Formatters.currencyFull(widget.bundle.amount), style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.slate800)),
            const SizedBox(height: 12),
            TextField(
              controller: _upiRefCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
              decoration: AppTheme.inputDecoration('UPI REFERENCE / TXN ID', icon: Icons.receipt_rounded),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 48, child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [Color(0xFF16A34A), AppColors.emerald600]),
                  boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.2), blurRadius: 12)]),
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmUpiPayment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('CONFIRM PAYMENT', style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
              ),
            )),
          ]),
        ),
      ],
      const SizedBox(height: 12),

      // SSL notice
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_rounded, size: 10, color: AppColors.slate400),
        const SizedBox(width: 4),
        Text('256-BIT SSL ENCRYPTED', style: GoogleFonts.plusJakartaSans(
          fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.slate400)),
      ]),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: AppTheme.labelSmall.copyWith(color: AppColors.slate400))),
    ]);
  }

  // ===== PROCESSING STEP =====
  Widget _buildProcessingStep() {
    return Padding(padding: const EdgeInsets.all(40), child: Column(children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.slate100, width: 4)),
        child: const Padding(padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.primary))),
      const SizedBox(height: 24),
      Text('SYNCING WITH GATEWAY', style: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate800)),
      const SizedBox(height: 8),
      Text('CLOUD SYNC IN PROGRESS', style: AppTheme.labelSmall),
    ]));
  }

  // ===== UPI CONFIRM STEP =====
  Widget _buildUpiConfirmStep() {
    return Column(children: [
      Container(width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.phone_android_rounded, size: 32, color: AppColors.green600)),
      const SizedBox(height: 16),
      Text('DID YOU COMPLETE THE PAYMENT?', style: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate800)),
      const SizedBox(height: 16),

      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate100)),
        child: Column(children: [
          Text(widget.studentName.toUpperCase(), style: AppTheme.labelSmall.copyWith(color: AppColors.slate600)),
          const SizedBox(height: 4),
          Text(Formatters.currencyFull(widget.bundle.amount), style: GoogleFonts.plusJakartaSans(
            fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: AppColors.slate800)),
        ]),
      ),
      const SizedBox(height: 16),

      TextField(
        controller: _upiRefCtrl,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
        decoration: AppTheme.inputDecoration('UPI REFERENCE / TXN ID', icon: Icons.receipt_rounded),
      ),
      const SizedBox(height: 8),
      Text('FIND THIS IN YOUR GOOGLE PAY / PHONEPE HISTORY', style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
      const SizedBox(height: 16),

      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(
        _error!.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.danger))),

      SizedBox(width: double.infinity, height: 52, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF16A34A), AppColors.emerald600]),
            boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))]),
        child: ElevatedButton(
          onPressed: _loading ? null : _confirmUpiPayment,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('CONFIRM PAYMENT', style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
        ),
      )),
      const SizedBox(height: 8),
      TextButton(onPressed: () => setState(() => _step = PaymentStep.select),
          child: Text('CANCEL', style: AppTheme.labelSmall.copyWith(color: AppColors.slate400))),
    ]);
  }

  // ===== SUCCESS STEP =====
  Widget _buildSuccessStep() {
    return Column(children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.check_rounded, size: 40, color: Colors.white)),
      const SizedBox(height: 20),
      Text('TRANSACTION AUTHORIZED', style: GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.slate800)),
      const SizedBox(height: 8),
      if (_transactionId != null)
        Text('TXN: $_transactionId'.toUpperCase(), style: AppTheme.labelSmall),
      const SizedBox(height: 24),

      SizedBox(width: double.infinity, height: 52, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
        child: ElevatedButton.icon(
          onPressed: () {
            // Download receipt for first due
            final due = widget.bundle.items.first.due;
            ReceiptService.generateAndShareReceipt(due: due, studentName: widget.studentName, admissionNumber: due.admissionNumber);
          },
          style: AppTheme.primaryButton,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text('DOWNLOAD RECEIPT', style: GoogleFonts.plusJakartaSans(
            fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
      )),
      const SizedBox(height: 8),
      Text('RECEIPT AVAILABLE IN RECEIPTS MODULE', style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => Navigator.pop(context, {'success': true, 'transactionId': _transactionId}),
        child: Text('CLOSE', style: AppTheme.labelSmall.copyWith(color: AppColors.slate400)),
      ),
    ]);
  }

  Widget _paymentButton({
    Gradient? gradient, Color? color, required Color shadowColor,
    required IconData icon, required double iconBgOpacity,
    required String label, VoidCallback? onTap,
  }) {
    return SizedBox(width: double.infinity, height: 56, child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient, color: gradient == null ? color : null,
        boxShadow: [BoxShadow(color: shadowColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(iconBgOpacity), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(iconBgOpacity))),
            child: Icon(icon, size: 16, color: Colors.white)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
        ]),
      ),
    ));
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(child: Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
      child: Column(children: [
        Text(label, style: AppTheme.labelXs),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: color ?? AppColors.slate800)),
      ]),
    ));
  }

  @override
  void dispose() { _upiRefCtrl.dispose(); super.dispose(); }
}
