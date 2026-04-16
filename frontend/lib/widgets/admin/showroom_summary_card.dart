import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/showroom.dart';
import '../../utils/formatters.dart';

class ShowroomSummaryCard extends StatelessWidget {
  final Showroom showroom;
  final double? cashTotal;
  final double? cardTotal;
  final VoidCallback? onTap;
  const ShowroomSummaryCard({
    super.key,
    required this.showroom,
    this.cashTotal,
    this.cardTotal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(showroom.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      if (showroom.location != null)
                        Text(showroom.location!,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            if (cashTotal != null || cardTotal != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (cashTotal != null)
                    Expanded(
                      child: _StatItem(
                        label: 'Cash',
                        value: Formatters.currency(cashTotal!),
                        color: AppColors.success,
                        icon: Icons.attach_money,
                      ),
                    ),
                  if (cashTotal != null && cardTotal != null)
                    const SizedBox(width: 10),
                  if (cardTotal != null)
                    Expanded(
                      child: _StatItem(
                        label: 'Card',
                        value: Formatters.currency(cardTotal!),
                        color: AppColors.accent,
                        icon: Icons.credit_card_rounded,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade500)),
            Text(value,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 12, color: color)),
          ],
        )
      ],
    );
  }
}
