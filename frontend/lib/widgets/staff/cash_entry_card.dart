import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/daily_cash_entry.dart';
import '../../utils/formatters.dart';

class CashEntryCard extends StatelessWidget {
  final DailyCashEntry entry;
  const CashEntryCard({super.key, required this.entry});

  Color get _accountColor => entry.cashAccountType == 'mano'
      ? const Color(0xFF7C3AED)
      : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accountColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                entry.isLocked ? Icons.lock_rounded : Icons.attach_money,
                color: _accountColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.date(entry.entryDate),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _AccountBadge(
                          label: entry.cashAccountType == 'mano'
                              ? "Mano's"
                              : 'Main',
                          color: _accountColor),
                      if (entry.isLocked) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Locked',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (entry.notes != null &&
                      entry.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.notes!,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              Formatters.currency(entry.cashAmount),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AccountBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
