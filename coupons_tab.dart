import 'package:flutter/material.dart';
import 'api.dart';
import 'common.dart';

class CouponsTab extends StatefulWidget {
  final VfApi api;
  const CouponsTab({super.key, required this.api});
  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  late Future<List<Coupon>> f = widget.api.coupons();
  String? busyId;

  void _tick() {
    if (mounted) setState(() => f = widget.api.coupons());
  }

  @override
  void initState() {
    super.initState();
    widget.api.couponTick.addListener(_tick);
  }

  @override
  void dispose() {
    widget.api.couponTick.removeListener(_tick);
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => f = widget.api.coupons());
    await f.catchError((_) => <Coupon>[]);
  }

  Future<void> _act(Coupon c) async {
    if (c.scratched) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: kGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                c.name.isEmpty ? 'تفعيل كوبون الهدية' : c.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                ),
                child: Text(
                  c.description.isNotEmpty
                      ? c.description
                      : 'هل ترغب في تفعيل هذه الهدية وإضافتها إلى حسابك الآن؟',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kText,
                    fontWeight: FontWeight.w600,
                  ),
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
                      onPressed: () => Navigator.pop(d, false),
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
                        backgroundColor: kGreen,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(d, true),
                      child: const Text(
                        'تفعيل الآن',
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
    }

    setState(() => busyId = c.id);
    try {
      if (c.scratched) {
        await widget.api.redeem(c.id);
        if (mounted) toast(context, 'تم تفعيل الكوبون بنجاح');
      } else {
        await widget.api.scratch(c.id);
        if (mounted) toast(context, 'تم كشط الكوبون! يمكنك تفعيل الهدية الآن');
      }
    } catch (e) {
      if (mounted) toast(context, '$e', isError: true);
    }
    if (mounted) setState(() => busyId = null);
    await _reload();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: kRed,
        onRefresh: _reload,
        child: FutureBuilder<List<Coupon>>(
          future: f,
          builder: (ctx, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: kRed),
                    SizedBox(height: 14),
                    Text(
                      'جاري تحميل كوبوناتك وهداياك...',
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

            if (s.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: kCardShadow,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: kRed,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'تعذر تحميل الكوبونات',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${s.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: kSub, fontSize: 13.5),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final list = s.data!;
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kBorder),
                      boxShadow: kCardShadow,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFBEB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.redeem_rounded,
                            color: kAmber,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد كوبونات متاحة حالياً',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اشترك في أي عرض من قسم "فصّل عروضك" لتحصل على كوبون هدية مجاني فوراً.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kSub,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kRed,
                            side: const BorderSide(color: kRed),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'تحديث القائمة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final readyCount = list.where((c) => c.scratched).length;
            final lockedCount = list.length - readyCount;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // ملخص الكوبونات العلوي
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
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: kAmber,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لديك ${ar('${list.length}')} كوبونات هدايا',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ar('$lockedCount')} جاهز للكشط • ${ar('$readyCount')} جاهز للتفعيل',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: kSub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'تحديث الكوبونات',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded, color: kRed),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // قائمة بطاقات الكوبونات
                ...list.map((c) {
                  final isBusy = busyId == c.id;
                  final unlocked = c.scratched;
                  final accent = unlocked ? kGreen : kAmber;
                  final softBg = unlocked
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: unlocked
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFDE68A),
                        width: 1.3,
                      ),
                      boxShadow: kCardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: softBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  unlocked
                                      ? Icons.card_giftcard_rounded
                                      : Icons.redeem_rounded,
                                  color: accent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: softBg,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            unlocked
                                                ? 'مكشوط • جاهز للتفعيل'
                                                : 'كوبون مغلق • اكشط هديتك',
                                            style: TextStyle(
                                              color: accent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.name.isEmpty
                                          ? 'كوبون هدية مجاني'
                                          : c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: kText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      unlocked
                                          ? (c.description.isNotEmpty
                                              ? c.description
                                              : 'هدية مجانية جاهزة للتفعيل على رقمك')
                                          : 'اكشط الكوبون الآن لمعرفة هديتك المجانية وتفعيلها فوراً',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: unlocked ? kText : kSub,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: kBorder),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (c.endMs != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.event_available_rounded,
                                        size: 14,
                                        color: kSub,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'ينتهي: ${fmtDate(c.endMs!)}',
                                        style: const TextStyle(
                                          color: kSub,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              SizedBox(
                                height: 42,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: unlocked ? kGreen : kRed,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                  onPressed:
                                      busyId == null ? () => _act(c) : null,
                                  icon: isBusy
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          unlocked
                                              ? Icons.check_circle_rounded
                                              : Icons.auto_awesome_rounded,
                                          size: 18,
                                        ),
                                  label: Text(
                                    unlocked ? 'تفعيل الهدية' : 'اكشط الكوبون',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
}
