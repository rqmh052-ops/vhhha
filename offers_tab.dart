import 'package:flutter/material.dart';
import 'api.dart';
import 'common.dart';

class OfferTab extends StatefulWidget {
  final VfApi api;
  final String type, title, tagline, unit;
  final int minDays;
  final IconData icon;
  final VoidCallback onBought;
  const OfferTab({
    super.key,
    required this.api,
    required this.type,
    required this.minDays,
    required this.title,
    required this.tagline,
    required this.unit,
    required this.icon,
    required this.onBought,
  });
  @override
  State<OfferTab> createState() => _OfferTabState();
}

class _OfferTabState extends State<OfferTab> with AutomaticKeepAliveClientMixin {
  List<Offer>? offers;
  String? error;
  int di = 0, ai = 0;
  bool busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      offers = null;
      error = null;
    });
    try {
      final all = await widget.api.offers(widget.type);
      // العروض كما رجعت من السيرفر فقط، مع تطبيق الحد الأدنى للأيام
      final f = all.where((o) => o.days >= widget.minDays).toList();
      if (!mounted) return;
      setState(() {
        offers = f;
        di = 0;
        ai = 0;
        if (f.isEmpty) error = 'السيرفر ما رجّع عروض مناسبة لرقمك';
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  List<int> get days => (offers!.map((o) => o.days).toSet().toList()..sort());
  List<Offer> get amounts {
    final l = offers!.where((o) => o.days == days[di]).toList();
    l.sort((a, b) => a.amount.compareTo(b.amount));
    return l;
  }

  Future<void> _buy(Offer o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الاشتراك'),
        content: Text(
            '${ar(fmtNum(o.amount))} ${widget.unit} لمدة ${ar('${o.days}')} أيام بسعر ${fmtFee(o.fee)} جنيه، وسيتم خصمها من رصيدك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kRed),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    try {
      final msg = await widget.api.buy(o);
      if (!mounted) return;
      toast(context, msg);
      widget.onBought();
    } catch (e) {
      if (mounted) toast(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _state(Widget child) => Center(child: Padding(padding: const EdgeInsets.all(24), child: child));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (error != null) {
      return _state(Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.black38),
        const SizedBox(height: 10),
        Text(error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kRed), onPressed: _load, child: const Text('إعادة المحاولة')),
      ]));
    }
    if (offers == null) return _state(const CircularProgressIndicator(color: kRed));

    final ds = days;
    final am = amounts;
    if (ai >= am.length) ai = 0;
    final sel = am[ai];

    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kRed.withOpacity(.1), shape: BoxShape.circle),
              child: Icon(widget.icon, color: kRed, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.tagline, style: const TextStyle(color: Colors.black54)),
                Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          Wheel(
            key: const ValueKey('days'),
            title: 'أولاً، إختار عدد الأيام',
            unit: 'أيام',
            items: ds.map((d) => ar('$d')).toList(),
            index: di,
            onChanged: (i) => setState(() {
              di = i;
              ai = 0;
            }),
          ),
          const SizedBox(height: 16),
          Wheel(
            key: ValueKey('amt-${ds[di]}'),
            title: 'أخيراً، إختار عدد ${widget.unit == 'وحدة' ? 'الوحدات' : 'الميجابيتس'}',
            unit: widget.unit,
            items: am.map((o) => ar(fmtNum(o.amount))).toList(),
            index: ai,
            onChanged: (i) => setState(() => ai = i),
          ),
        ]),
      ),
      Container(
        color: const Color(0xFFEDEDED),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        width: double.infinity,
        child: Row(children: const [
          Icon(Icons.card_giftcard_rounded, color: kRed),
          SizedBox(width: 10),
          Text('اكسب كوبون مع كل عرض هتفصله', style: TextStyle(fontSize: 15)),
        ]),
      ),
      Container(
        color: const Color(0xFF303030),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => FadeTransition(
                opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a), child: c)),
            child: Text('${fmtFee(sel.fee)} جنيه',
                key: ValueKey(sel.fee),
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: busy ? null : () => _buy(sel),
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('إشترك الأن!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    ]);
  }
}

/// عجلة اختيار أفقية: تقليب بالسحب أو بالأسهم، مع تكبير العنصر المختار
class Wheel extends StatefulWidget {
  final String title, unit;
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  const Wheel({
    super.key,
    required this.title,
    required this.unit,
    required this.items,
    required this.index,
    required this.onChanged,
  });
  @override
  State<Wheel> createState() => _WheelState();
}

class _WheelState extends State<Wheel> {
  late final PageController c = PageController(initialPage: widget.index, viewportFraction: .27);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0 || i >= widget.items.length) return;
    c.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(children: [
        Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(children: [
          _Arrow(Icons.chevron_right_rounded, widget.index > 0, () => _go(widget.index - 1)),
          Expanded(
            child: SizedBox(
              height: 80,
              child: PageView.builder(
                controller: c,
                itemCount: n,
                onPageChanged: widget.onChanged,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _go(i),
                  child: AnimatedBuilder(
                    animation: c,
                    builder: (_, __) {
                      final p = (c.hasClients && c.position.haveDimensions) ? (c.page ?? widget.index.toDouble()) : widget.index.toDouble();
                      final d = (p - i).abs().clamp(0.0, 1.0);
                      return Center(
                        child: Opacity(
                          opacity: 1 - .7 * d,
                          child: Transform.scale(
                            scale: 1 - .4 * d,
                            child: Text(widget.items[i],
                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color.lerp(kRed, Colors.black, d))),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _Arrow(Icons.chevron_left_rounded, widget.index < n - 1, () => _go(widget.index + 1)),
        ]),
        Text(widget.unit, style: const TextStyle(color: Colors.black45)),
      ]),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final bool on;
  final VoidCallback tap;
  const _Arrow(this.icon, this.on, this.tap);
  @override
  Widget build(BuildContext context) => IconButton(
        style: IconButton.styleFrom(backgroundColor: Colors.white, elevation: 2, shadowColor: Colors.black26),
        icon: Icon(icon, size: 30),
        onPressed: on ? tap : null,
      );
}
