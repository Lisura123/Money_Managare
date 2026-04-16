import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/formatters.dart';
import '../../config/theme.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final bool showSign;
  final double fontSize;
  final FontWeight fontWeight;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.showSign = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    Color color;
    String prefix = '';
    if (showSign) {
      if (isNegative) {
        color = AppColors.error;
        prefix = '▼ ';
      } else if (amount > 0) {
        color = AppColors.success;
        prefix = '▲ ';
      } else {
        color = AppColors.textSecondary;
      }
    } else {
      color =
          Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    }
    return Text(
      '$prefix${Formatters.currency(amount.abs())}',
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
