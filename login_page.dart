import 'package:flutter/material.dart';
import 'api.dart';
import 'common.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool busy = false, hide = true;
  String? error;
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  Animation<double> _iv(double s, double e) =>
      CurvedAnimation(parent: _a, curve: Interval(s, e, curve: Curves.easeOutCubic));

  Widget _in(double s, double e, Widget child) {
    final a = _iv(s, e);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(a),
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
      setState(() => error = 'اكتب الرقم وكلمة المرور');
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
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => HomePage(api: api),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  InputDecoration _dec(String l, IconData i, {Widget? suffix}) => InputDecoration(
        labelText: l,
        prefixIcon: Icon(i, color: kRed),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kRed, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kDark, kRed, Color(0xFFF6F6F8)], stops: [0, .38, .38]),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _in(
                    0,
                    .5,
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 6))
                      ]),
                      child: const Icon(Icons.local_offer_rounded, size: 52, color: kRed),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _in(.1, .6, const Text('عروضي', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(height: 4),
                  _in(.15, .65, const Text('فصّل عروضك على مزاجك', style: TextStyle(color: Colors.white70))),
                  const SizedBox(height: 40),
                  _in(
                    .3,
                    .85,
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      child: Column(children: [
                        TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('رقم الهاتف', Icons.phone_rounded),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: pass,
                          obscureText: hide,
                          onSubmitted: (_) => _go(),
                          decoration: _dec('كلمة المرور', Icons.lock_rounded,
                              suffix: IconButton(
                                icon: Icon(hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                onPressed: () => setState(() => hide = !hide),
                              )),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: error == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                                ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: busy ? null : _go,
                            child: busy
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text('تسجيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
