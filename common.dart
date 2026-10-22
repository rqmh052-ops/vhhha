import 'package:flutter/material.dart';

const kRed = Color(0xFFE60000);
const kDark = Color(0xFF7F0000);

String ar(String s) {
  const d = '٠١٢٣٤٥٦٧٨٩';
  return s.split('').map((c) {
    final i = '0123456789'.indexOf(c);
    return i >= 0 ? d[i] : (c == '.' ? '٫' : c);
  }).join();
}

String fmtNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

String fmtFee(String fee) {
  final n = num.tryParse(fee);
  return ar(n == null ? fee : fmtNum(n));
}

String fmtDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return ar('${d.day}/${d.month}/${d.year}');
}

void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
