import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../utils/formatters.dart';

class EntryListTile extends StatelessWidget {
  final String date;
  final String staffName;
  final double amount;
  final bool isLocked;
  final String? showroomName;
  final String? notes;
  final bool isCard;
  final String? cardLabel;
  final String? cashAccountType;
  final VoidCallback? onTap;

  const EntryListTile({
    super.key,
    required this.date,
    required this.staffName,
    required this.amount,
    required this.isLocked,
    this.showroomName,
    this.notes,
    this.isCard = false,
    this.cardLabel,
    this.cashAccountType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accountColor = (!isCard && cashAccountType == 'mano')
        ? const Color(0xFF7C3AED)
        : (isCard ? AppColors.accent : AppColors.success);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isLocked ? AppColors.error : accountColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLocked
                      ? Icons.lock_rounded
                      : (isCard
                          ? Icons.credit_card_rounded
                          : Icons.attach_money),
                  color: isLocked ? AppColors.error : accountColor,
                  size: 18,
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
                        Text(Formatters.currency(amount),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(staffName,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey.shade600)),
                        if (showroomName != null) ...[
                          Text(' · ',
                              style: TextStyle(color: Colors.grey.shade400)),
                          Flexible(
                            child: Text(showroomName!,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    if (!isCard && cashAccountType != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: accountColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cashAccountType == 'mano' ? "Mano's" : 'Main',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: accountColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    if (cardLabel != null)
                      Text(cardLabel!,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey.shade500)),
                    if (notes != null && notes!.isNotEmpty)
                      Text(notes!,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (isLocked)
                const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.lock_rounded,
                        size: 14, color: AppColors.error)),
            ],
          ),
        ),
      ),
    );
  }
}
