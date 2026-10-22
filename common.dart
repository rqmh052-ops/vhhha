import 'package:flutter/material.dart';

// ---------- الألوان الأساسية والهوية البصرية ----------
const kRed = Color(0xFFE60000);
const kDark = Color(0xFF8A0000);
const kDarker = Color(0xFF4A0005);
const kBg = Color(0xFFF4F6F9);
const kSurface = Color(0xFFF8FAFC);
const kBorder = Color(0xFFE2E8F0);
const kText = Color(0xFF0F172A);
const kSub = Color(0xFF64748B);
const kGreen = Color(0xFF059669);
const kAmber = Color(0xFFD97706);

const kHeaderGrad = LinearGradient(
  colors: [Color(0xFF5A0004), Color(0xFFA80000), Color(0xFFE60000)],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);

const kRedGrad = LinearGradient(
  colors: [Color(0xFFE60000), Color(0xFFB80000)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kCardShadow = [
  BoxShadow(
    color: Color(0x0D0F172A),
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

// ---------- دوال تنسيق الأرقام والتواريخ ----------
String ar(String s) {
  const d = '٠١٢٣٤٥٦٧٨٩';
  return s.split('').map((c) {
    final i = '0123456789'.indexOf(c);
    return i >= 0 ? d[i] : (c == '.' ? '٫' : c);
  }).join();
}

String fmtNum(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toString();

String fmtFee(String fee) {
  final n = num.tryParse(fee);
  return ar(n == null ? fee : fmtNum(n));
}

String fmtDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return ar('${d.day}/${d.month}/${d.year}');
}

String daysLabel(int d) {
  if (d == 1) return 'يوم واحد';
  if (d == 2) return 'يومين';
  if (d >= 3 && d <= 10) return '${ar('$d')} أيام';
  return '${ar('$d')} يوم';
}

// ---------- الإشعارات السريعة (Toast) ----------
void toast(BuildContext c, String m, {bool isError = false}) {
  final messenger = ScaffoldMessenger.of(c);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? const Color(0xFFB91C1C) : const Color(0xFF1E293B),
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              m,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
