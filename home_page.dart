import 'package:flutter/material.dart';
import 'api.dart';
import 'common.dart';
import 'coupons_tab.dart';
import 'login_page.dart';
import 'offers_tab.dart';

class HomePage extends StatefulWidget {
  final VfApi api;
  const HomePage({super.key, required this.api});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<double> bal = widget.api.balance();
  final pc = PageController();
  int tab = 0; // 0 = وحدات، 1 = ميجابيتس
  int nav = 0; // 0 = العروض، 1 = الكوبونات

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => bal = widget.api.balance());
    widget.api.couponTick.value++;
  }

  // بعد الشراء الكوبون يظهر بعد ثواني، فنكرر الاستعلام تلقائياً
  Future<void> _afterBuy() async {
    _reload();
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      widget.api.couponTick.value++;
    }
  }

  void _pick(int i) {
    setState(() => tab = i);
    if (pc.hasClients) {
      pc.animateToPage(
        i,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                Icons.logout_rounded,
                color: kRed,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'هل تريد تسجيل الخروج من حسابك الحالي؟',
              textAlign: TextAlign.center,
              style: TextStyle(color: kSub, fontSize: 14),
            ),
            const SizedBox(height: 22),
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
                const SizedBox(width: 12),
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
                      'خروج',
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
    if (ok == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Widget _headerAction(IconData icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
          ),
        ),
      );

  Widget _toggle() {
    const labels = ['وحدات لكل الشبكات', 'باقات الميجابيتس'];
    const icons = [Icons.timer_rounded, Icons.wifi_rounded];
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x2E000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: tab == 0
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(2, (i) {
              final active = tab == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pick(i),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[i],
                          size: 18,
                          color: active ? kRed : Colors.white70,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  active ? FontWeight.w800 : FontWeight.w600,
                              color: active ? kRed : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _topHeader() => Container(
        decoration: const BoxDecoration(
          gradient: kHeaderGrad,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F8A0000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الشريط العلوي (العنوان + الأزرار)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        color: kRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'عروضي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android_rounded,
                                color: Colors.white70,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.api.msisdn.isNotEmpty
                                    ? ar(widget.api.msisdn)
                                    : 'فصّل عروضك',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _headerAction(
                      Icons.refresh_rounded,
                      'تحديث الرصيد والعروض',
                      _reload,
                    ),
                    const SizedBox(width: 8),
                    _headerAction(
                      Icons.logout_rounded,
                      'تسجيل الخروج',
                      _confirmLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // بطاقة الرصيد الحالي
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x24FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x30FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x28FFFFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'الرصيد المتاح',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      FutureBuilder<double>(
                        future: bal,
                        builder: (c, s) {
                          if (s.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            );
                          }
                          if (s.hasData) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ar(fmtNum(s.data!)),
                                    style: const TextStyle(
                                      color: kRed,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'جنيه',
                                    style: TextStyle(
                                      color: kText,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: _reload,
                            child: const Row(
                              children: [
                                Text(
                                  'اضغط للتحديث',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // شريط التبديل بين الوحدات والميجابيتس يظهر في قسم العروض فقط
                if (nav == 0) ...[
                  const SizedBox(height: 14),
                  _toggle(),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _offersView() => PageView(
        controller: pc,
        onPageChanged: (i) => setState(() => tab = i),
        children: [
          OfferTab(
            api: widget.api,
            type: '6',
            minDays: 1,
            title: 'وحدات لكل الشبكات',
            tagline: 'فصّل وحداتك ومكالماتك على مزاجك',
            unit: 'وحدة',
            icon: Icons.timer_rounded,
            onBought: _afterBuy,
          ),
          OfferTab(
            api: widget.api,
            type: '2',
            minDays: 2, // أقل شيء يومين
            title: 'باقات الميجابيتس',
            tagline: 'إنترنت سريع على قد احتياجك',
            unit: 'ميجابيتس',
            icon: Icons.wifi_rounded,
            onBought: _afterBuy,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Column(
          children: [
            _topHeader(),
            Expanded(
              child: IndexedStack(
                index: nav,
                children: [
                  _offersView(),
                  CouponsTab(api: widget.api),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: kBorder)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            selectedIndex: nav,
            indicatorColor: const Color(0x1AE60000),
            onDestinationSelected: (i) => setState(() => nav = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.local_offer_outlined, color: kSub),
                selectedIcon: Icon(Icons.local_offer_rounded, color: kRed),
                label: 'فصّل عروضك',
              ),
              NavigationDestination(
                icon: Icon(Icons.card_giftcard_outlined, color: kSub),
                selectedIcon: Icon(Icons.card_giftcard_rounded, color: kRed),
                label: 'كوبوناتي',
              ),
            ],
          ),
        ),
      );
}
