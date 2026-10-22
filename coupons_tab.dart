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
          title: const Text('تفعيل الكوبون'),
          content: Text(c.description),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('تفعيل')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => busyId = c.id);
    try {
      if (c.scratched) {
        await widget.api.redeem(c.id);
        if (mounted) toast(context, 'تم تفعيل الكوبون');
      } else {
        await widget.api.scratch(c.id);
        if (mounted) toast(context, 'تم كشط الكوبون');
      }
    } catch (e) {
      if (mounted) toast(context, '$e');
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
              return const Center(child: CircularProgressIndicator(color: kRed));
            }
            if (s.hasError) {
              return ListView(children: [
                Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('${s.error}', textAlign: TextAlign.center))),
              ]);
            }
            final list = s.data!;
            if (list.isEmpty) {
              return ListView(children: const [
                Padding(padding: EdgeInsets.all(48), child: Center(child: Text('لا توجد كوبونات حالياً'))),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = list[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.scratched ? kRed : Colors.black12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name.isEmpty ? 'كوبون' : c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (c.scratched) ...[
                          const SizedBox(height: 4),
                          Text(c.description),
                        ] else ...[
                          const SizedBox(height: 4),
                          const Text('كوبون مغلق، اكشطه لتعرف الهدية'),
                        ],
                        if (c.endMs != null) ...[
                          const SizedBox(height: 4),
                          Text('ينتهي: ${fmtDate(c.endMs!)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ]),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kRed),
                      onPressed: busyId == null ? () => _act(c) : null,
                      child: busyId == c.id
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(c.scratched ? 'تفعيل' : 'اكشط'),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      );
}
