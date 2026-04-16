import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? initialShowroomId;
  final int? initialCardAccountId;
  final String? initialCashAccountType;
  final List<Map<String, dynamic>> showrooms;
  final List<Map<String, dynamic>> cardAccounts;
  final bool showCashAccountType;
  final Function(DateTime? start, DateTime? end, int? showroomId,
      int? cardAccountId, String? cashAccountType) onApply;

  const FilterBottomSheet({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialShowroomId,
    this.initialCardAccountId,
    this.initialCashAccountType,
    this.showrooms = const [],
    this.cardAccounts = const [],
    this.showCashAccountType = false,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    int? initialShowroomId,
    int? initialCardAccountId,
    String? initialCashAccountType,
    List<Map<String, dynamic>> showrooms = const [],
    List<Map<String, dynamic>> cardAccounts = const [],
    bool showCashAccountType = false,
    required Function(DateTime? start, DateTime? end, int? showroomId,
            int? cardAccountId, String? cashAccountType)
        onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FilterBottomSheet(
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        initialShowroomId: initialShowroomId,
        initialCardAccountId: initialCardAccountId,
        initialCashAccountType: initialCashAccountType,
        showrooms: showrooms,
        cardAccounts: cardAccounts,
        showCashAccountType: showCashAccountType,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _showroomId;
  int? _cardAccountId;
  String? _cashAccountType;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _showroomId = widget.initialShowroomId;
    _cardAccountId = widget.initialCardAccountId;
    _cashAccountType = widget.initialCashAccountType;
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Filters',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                    label: 'From',
                    value: _fmt(_startDate),
                    onTap: () => _pickDate(true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                    label: 'To',
                    value: _fmt(_endDate),
                    onTap: () => _pickDate(false)),
              ),
            ],
          ),
          if (widget.cardAccounts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Card Account',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              value: _cardAccountId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Card Accounts',
                        style: GoogleFonts.inter(fontSize: 14))),
                ...widget.cardAccounts.map((a) => DropdownMenuItem<int?>(
                    value: a['id'] as int,
                    child: Text(a['label'] as String,
                        style: GoogleFonts.inter(fontSize: 14)))),
              ],
              onChanged: (v) => setState(() => _cardAccountId = v),
            ),
          ],
          if (widget.showCashAccountType) ...[
            const SizedBox(height: 14),
            Text('Cash Account',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              value: _cashAccountType,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Accounts',
                        style: GoogleFonts.inter(fontSize: 14))),
                DropdownMenuItem<String?>(
                    value: 'main',
                    child: Text('Main Account',
                        style: GoogleFonts.inter(fontSize: 14))),
                DropdownMenuItem<String?>(
                    value: 'mano',
                    child: Text("Mano's Account",
                        style: GoogleFonts.inter(fontSize: 14))),
              ],
              onChanged: (v) => setState(() => _cashAccountType = v),
            ),
          ],
          if (widget.showrooms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Showroom',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              value: _showroomId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Showrooms',
                        style: GoogleFonts.inter(fontSize: 14))),
                ...widget.showrooms.map((s) => DropdownMenuItem<int?>(
                    value: s['id'] as int,
                    child: Text(s['name'] as String,
                        style: GoogleFonts.inter(fontSize: 14)))),
              ],
              onChanged: (v) => setState(() => _showroomId = v),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _showroomId = null;
                      _cardAccountId = null;
                      _cashAccountType = null;
                    });
                    widget.onApply(null, null, null, null, null);
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () {
                    widget.onApply(_startDate, _endDate, _showroomId,
                        _cardAccountId, _cashAccountType);
                    Navigator.pop(context);
                  },
                  child: Text('Apply',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 13)),
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
