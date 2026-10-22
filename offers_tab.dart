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

class _OfferTabState extends State<OfferTab>
    with AutomaticKeepAliveClientMixin {
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
      final f = all.where((o) => o.days >= widget.minDays).toList();
      if (!mounted) return;
      setState(() {
        offers = f;
        di = 0;
        ai = 0;
        if (f.isEmpty) error = 'لا توجد عروض متاحة لرقمك في هذا القسم حالياً';
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

  Widget _summaryRow(String label, String value, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: kSub,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: highlight ? kRed : kText,
                fontSize: highlight ? 16 : 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

  Future<void> _buy(Offer o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: kRed,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'تأكيد الاشتراك في العرض',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'راجع تفاصيل الباقة قبل تأكيد الخصم من رصيدك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kSub),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  _summaryRow('نوع العرض', widget.title),
                  const Divider(height: 1, color: kBorder),
                  _summaryRow(
                    'الكمية',
                    '${ar(fmtNum(o.amount))} ${widget.unit}',
                  ),
                  const Divider(height: 1, color: kBorder),
                  _summaryRow('مدة الصلاحية', daysLabel(o.days)),
                  const Divider(height: 1, color: kBorder),
                  _summaryRow(
                    'التكلفة الإجمالية',
                    '${fmtFee(o.fee)} جنيه',
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.redeem_rounded, color: kAmber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ستحصل على كوبون هدية مجاني بعد إتمام الاشتراك',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kText,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kRed,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text(
                      'تأكيد الاشتراك',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      if (mounted) toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: kCardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: kRed,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تعذر تحميل العروض',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kSub, fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (offers == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: kRed),
            SizedBox(height: 14),
            Text(
              'جاري تجهيز العروض المناسبة لرقمك...',
              style: TextStyle(
                color: kSub,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final ds = days;
    final am = amounts;
    if (ai >= am.length) ai = 0;
    final sel = am[ai];

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: kRed,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                // بطاقة عنوان القسم
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder),
                    boxShadow: kCardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x14E60000),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(widget.icon, color: kRed, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.tagline,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder),
                        ),
                        child: Text(
                          '${ar('${offers!.length}')} عرض',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // الخطوة الأولى: اختيار عدد الأيام
                Wheel(
                  key: const ValueKey('days'),
                  stepNumber: '١',
                  title: 'اختر مدة صلاحية الباقة',
                  unit: 'يوم صلاحية',
                  badgeText: daysLabel(ds[di]),
                  items: ds.map((d) => ar('$d')).toList(),
                  chipLabels: ds.map((d) => daysLabel(d)).toList(),
                  index: di,
                  onChanged: (i) => setState(() {
                    di = i;
                    ai = 0;
                  }),
                ),
                const SizedBox(height: 16),

                // الخطوة الثانية: اختيار الكمية والسعر
                Wheel(
                  key: ValueKey('amt-${ds[di]}'),
                  stepNumber: '٢',
                  title:
                      'اختر كمية ${widget.unit == 'وحدة' ? 'الوحدات' : 'الميجابيتس'}',
                  unit: widget.unit,
                  badgeText: '${fmtFee(sel.fee)} جنيه',
                  items: am.map((o) => ar(fmtNum(o.amount))).toList(),
                  chipLabels: am
                      .map((o) =>
                          '${ar(fmtNum(o.amount))} ${widget.unit} • ${fmtFee(o.fee)} ج')
                      .toList(),
                  index: ai,
                  onChanged: (i) => setState(() => ai = i),
                ),
                const SizedBox(height: 14),

                // لافتة الكوبون المجاني
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        color: kAmber,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'اكسب كوبون هدية مجاني مع كل عرض هتفصّله الآن!',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // شريط الشراء السفلي المنظم
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: kBorder)),
            boxShadow: [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${ar(fmtNum(sel.amount))} ${widget.unit} • ${daysLabel(sel.days)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: kSub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (c, a) =>
                          FadeTransition(opacity: a, child: c),
                      child: Row(
                        key: ValueKey('${sel.fee}-${sel.amount}-${sel.days}'),
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            fmtFee(sel.fee),
                            style: const TextStyle(
                              color: kText,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'جنيه',
                            style: TextStyle(
                              color: kRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: busy ? null : kRedGrad,
                    color: busy ? const Color(0xFFCBD5E1) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: busy
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x38E60000),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: busy ? null : () => _buy(sel),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                    label: Text(
                      busy ? 'جاري التنفيذ...' : 'اشترك الآن',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// بطاقة اختيار تفاعلية: تجمع بين عجلة السحب السلسة وأزرار الاختيار السريع
class Wheel extends StatefulWidget {
  final String stepNumber, title, unit, badgeText;
  final List<String> items;
  final List<String> chipLabels;
  final int index;
  final ValueChanged<int> onChanged;
  const Wheel({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.unit,
    required this.badgeText,
    required this.items,
    required this.chipLabels,
    required this.index,
    required this.onChanged,
  });
  @override
  State<Wheel> createState() => _WheelState();
}

class _WheelState extends State<Wheel> {
  late final PageController c = PageController(
    initialPage: widget.index,
    viewportFraction: 0.36,
  );

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0 || i >= widget.items.length) return;
    if (c.hasClients) {
      c.animateToPage(
        i,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onChanged(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة (رقم الخطوة + العنوان + الشارة)
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kRed,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  widget.stepNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.badgeText,
                  style: const TextStyle(
                    color: kRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // منطقة العجلة والأزرار الجانبية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                _Arrow(
                  Icons.remove_rounded,
                  widget.index > 0,
                  () => _go(widget.index - 1),
                ),
                Expanded(
                  child: SizedBox(
                    height: 68,
                    child: PageView.builder(
                      controller: c,
                      itemCount: n,
                      onPageChanged: widget.onChanged,
                      itemBuilder: (_, i) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _go(i),
                        child: AnimatedBuilder(
                          animation: c,
                          builder: (_, __) {
                            final p = (c.hasClients &&
                                    c.position.haveDimensions)
                                ? (c.page ?? widget.index.toDouble())
                                : widget.index.toDouble();
                            final d = (p - i).abs().clamp(0.0, 1.0);
                            return Center(
                              child: Opacity(
                                opacity: 1 - 0.65 * d,
                                child: Transform.scale(
                                  scale: 1 - 0.28 * d,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.items[i],
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w900,
                                              color: Color.lerp(
                                                kRed,
                                                kSub,
                                                d,
                                              ),
                                              height: 1.1,
                                            ),
                                          ),
                                          Text(
                                            widget.unit,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color.lerp(
                                                kText,
                                                kSub,
                                                d,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                _Arrow(
                  Icons.add_rounded,
                  widget.index < n - 1,
                  () => _go(widget.index + 1),
                ),
              ],
            ),
          ),

          // أزرار الاختيار السريع المباشر
          if (n > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: n,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = i == widget.index;
                  return GestureDetector(
                    onTap: () => _go(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? kRed : kSurface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: sel ? kRed : kBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.chipLabels[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                sel ? FontWeight.w800 : FontWeight.w600,
                            color: sel ? Colors.white : kText,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final bool on;
  final VoidCallback tap;
  const _Arrow(this.icon, this.on, this.tap);

  @override
  Widget build(BuildContext context) => Material(
        color: on ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        elevation: on ? 1 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: on ? tap : null,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: Icon(
              icon,
              size: 22,
              color: on ? kRed : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      );
}
