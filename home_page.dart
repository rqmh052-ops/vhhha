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
  int tab = 0; // 0 = وحدات (يمين)، 1 = ميجابيتس
  int nav = 0; // 0 = العروض، 1 = الكوبونات

  void _reload() => setState(() => bal = widget.api.balance());

  // بعد الشراء الكوبون يظهر بعد ثواني، فنكرر الاستعلام
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
    pc.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  Widget _toggle() {
    const labels = ['عرض الوحدات', 'عرض الميجا بايت'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(26)),
      child: Stack(children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: tab == 0 ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
          child: FractionallySizedBox(
            widthFactor: .5,
            child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22))),
          ),
        ),
        Row(
          children: List.generate(
            2,
            (i) => Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pick(i),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: tab == i ? kRed : Colors.white),
                    child: Text(labels[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _offers() => Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kDark, kRed], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: _toggle(),
        ),
        Expanded(
          child: PageView(
            controller: pc,
            onPageChanged: (i) => setState(() => tab = i),
            children: [
              OfferTab(
                  api: widget.api,
                  type: '6',
                  minDays: 1,
                  title: 'وحدات لكل الشبكات',
                  tagline: 'شبرق نفسك علي مزاجك',
                  unit: 'وحدة',
                  icon: Icons.timer_rounded,
                  onBought: _afterBuy),
              OfferTab(
                  api: widget.api,
                  type: '2',
                  minDays: 2, // أقل شيء يومين
                  title: 'ميجابيتس',
                  tagline: 'نت على قد احتياجك',
                  unit: 'ميجابيتس',
                  icon: Icons.network_cell_rounded,
                  onBought: _afterBuy),
            ],
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: kDark,
          foregroundColor: Colors.white,
          elevation: 0,
          title: FutureBuilder<double>(
            future: bal,
            builder: (c, s) => Text(
              s.hasData ? 'الرصيد: ${ar(fmtNum(s.data!))} جنيه' : 'فصّل عروضك',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _reload),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
            ),
          ],
        ),
        body: IndexedStack(index: nav, children: [_offers(), CouponsTab(api: widget.api)]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: nav,
          indicatorColor: kRed.withOpacity(.15),
          onDestinationSelected: (i) => setState(() => nav = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.local_offer_outlined), selectedIcon: Icon(Icons.local_offer, color: kRed), label: 'العروض'),
            NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard, color: kRed), label: 'الكوبونات'),
          ],
        ),
      );
}
