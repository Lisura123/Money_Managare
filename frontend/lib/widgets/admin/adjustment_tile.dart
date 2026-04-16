import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../utils/formatters.dart';

class AdjustmentTile extends StatelessWidget {
  final String date;
  final String adminName;
  final double amount;
  final String reason;
  final bool isCard;
  final String? cardLabel;
  final VoidCallback? onDelete;

  const AdjustmentTile({
    super.key,
    required this.date,
    required this.adminName,
    required this.amount,
    required this.reason,
    this.isCard = false,
    this.cardLabel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPositive
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                color: isPositive ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(date,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        (isPositive ? '+' : '') + Formatters.currency(amount),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(adminName,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  if (cardLabel != null)
                    Text(cardLabel!,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.grey.shade500)),
                  Text(reason,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
