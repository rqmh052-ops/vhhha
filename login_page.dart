import 'package:flutter/material.dart';
import 'api.dart';
import 'common.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool busy = false, hide = true;
  String? error;

  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  Animation<double> _iv(double s, double e) => CurvedAnimation(
        parent: _a,
        curve: Interval(s, e, curve: Curves.easeOutCubic),
      );

  Widget _in(double s, double e, Widget child) {
    final a = _iv(s, e);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position:
            Tween(begin: const Offset(0, .18), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _a.dispose();
    phone.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (phone.text.trim().isEmpty || pass.text.isEmpty) {
      setState(() => error = 'يرجى إدخال رقم الهاتف وكلمة المرور للمتابعة');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    final api = VfApi();
    try {
      await api.login(phone.text, pass.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => HomePage(api: api),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration _dec({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        labelStyle: const TextStyle(
          color: kSub,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: kRed,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x14E60000),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kRed, size: 20),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kRed, width: 1.8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBorder, width: 1.2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // الخلفية العلوية المنحنية
          Container(
            height: 330,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: kHeaderGrad,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(42),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -40,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x14FFFFFF),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x12FFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // محتوى الصفحة
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الشعار والهوية
                      _in(
                        0.0,
                        0.45,
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x26FFFFFF),
                            border: Border.all(
                              color: const Color(0x40FFFFFF),
                              width: 1.5,
                            ),
                          ),
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_offer_rounded,
                              size: 40,
                              color: kRed,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _in(
                        0.1,
                        0.55,
                        const Text(
                          'عروضي',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _in(
                        0.15,
                        0.6,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x24FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'فصّل عروضك وباقاتك على مزاجك بكل سهولة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // بطاقة تسجيل الدخول
                      _in(
                        0.25,
                        0.85,
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x140F172A),
                                blurRadius: 28,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: kRed,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'تسجيل الدخول',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: kText,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'سجّل بحساب أنا فودافون للاستمتاع بالعروض',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: kSub,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_rounded,
                                      color: kRed,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // حقل رقم الهاتف
                              TextField(
                                controller: phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                                decoration: _dec(
                                  label: 'رقم الهاتف',
                                  hint: '010XXXXXXXX',
                                  icon: Icons.phone_android_rounded,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // حقل كلمة المرور
                              TextField(
                                controller: pass,
                                obscureText: hide,
                                onSubmitted: (_) => _go(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                                decoration: _dec(
                                  label: 'كلمة المرور',
                                  hint: 'أدخل كلمة المرور',
                                  icon: Icons.lock_rounded,
                                  suffix: IconButton(
                                    tooltip: hide
                                        ? 'إظهار كلمة المرور'
                                        : 'إخفاء كلمة المرور',
                                    icon: Icon(
                                      hide
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: kSub,
                                      size: 21,
                                    ),
                                    onPressed: () =>
                                        setState(() => hide = !hide),
                                  ),
                                ),
                              ),

                              // رسالة الخطأ إن وجدت
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                child: error == null
                                    ? const SizedBox(width: double.infinity)
                                    : Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFFECACA),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Color(0xFFDC2626),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                error!,
                                                style: const TextStyle(
                                                  color: Color(0xFFB91C1C),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 22),

                              // زر تسجيل الدخول
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: busy ? null : kRedGrad,
                                    color: busy
                                        ? const Color(0xFFCBD5E1)
                                        : null,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: busy
                                        ? null
                                        : const [
                                            BoxShadow(
                                              color: Color(0x40E60000),
                                              blurRadius: 16,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                  ),
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: busy ? null : _go,
                                    child: busy
                                        ? const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'جاري تسجيل الدخول...',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'تسجيل الدخول',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.login_rounded,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ملاحظة الأمان السفلية
                      _in(
                        0.4,
                        1.0,
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 15,
                              color: kSub,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'اتصال آمن ومباشر مع خدمات فودافون الرسمية',
                              style: TextStyle(
                                color: kSub,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
