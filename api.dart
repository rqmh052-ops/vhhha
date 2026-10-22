import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Offer {
  final String type; // 6 = وحدات, 2 = ميجابيتس
  final String fee;
  final num amount;
  final int days;
  Offer(this.type, this.fee, this.amount, this.days);

  factory Offer.fromJson(Map g) {
    final type = '${g['giftType']}';
    final raw = type == '2' ? g['giftQuota'] : g['giftUnits'];
    return Offer(type, '${g['giftFees']}', num.tryParse('$raw') ?? 0,
        int.tryParse('${g['giftValidity']}') ?? 0);
  }
}

class Coupon {
  final String id, description, name;
  final num amount;
  final int? endMs;
  final int days;
  Coupon(this.id, this.description, this.name, this.amount, this.endMs, this.days);
  bool get scratched => amount > 0;

  factory Coupon.fromJson(Map j) {
    String ch(String n) {
      for (final c in (j['characteristics'] as List? ?? [])) {
        if (c['name'] == n) return '${c['value']}';
      }
      return '';
    }

    return Coupon(
      '${j['id']}',
      '${j['description'] ?? ''}',
      '${j['name'] ?? ''}',
      num.tryParse(ch('amount')) ?? 0,
      j['validFor']?['endDateTime'] as int?,
      int.tryParse(ch('OfferValidity')) ?? 0,
    );
  }
}

class VfApi {
  static const base = 'https://mobile.vodafone.com.eg';
  static const _secret = 'dca0pbLUWXVhXR266Gw1iT5rqwvvJQoN';
  static const _ver = '2026.4.1';
  static const _build = '1139';

  final _rnd = Random.secure();
  late final String _digitalId = _gen('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 13);
  late final String _deviceId = _gen('0123456789abcdef', 16);

  String msisdn = '';
  String _password = '';
  String _token = '';
  DateTime _exp = DateTime(2000);
  String serviceClass = '';
  final couponTick = ValueNotifier<int>(0);

  String _gen(String chars, int n) =>
      List.generate(n, (_) => chars[_rnd.nextInt(chars.length)]).join();

  Map<String, String> _h({bool json = true, Map<String, String>? extra}) => {
        'clientId': 'AnaVodafoneAndroid',
        'Accept-Language': 'ar',
        'x-agent-operatingsystem': '15',
        'x-agent-device': 'INFINIX Infinix X6728',
        'x-agent-version': _ver,
        'x-agent-build': _build,
        'msisdn': msisdn,
        'device-id': _deviceId,
        'User-Agent': 'okhttp/4.12.0',
        'Accept-Encoding': 'gzip',
        if (json) 'Content-Type': 'application/json; charset=UTF-8',
        if (json) 'Accept': 'application/json',
        ...?extra,
      };

  dynamic _dec(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  String _err(http.Response r) {
    try {
      final j = _dec(r);
      if (j is Map) {
        final m = j['errorMessage'] ?? j['message'] ?? j['reason'] ?? j['error_description'] ?? j['eDesc'];
        if (m != null) return '$m';
      }
    } catch (_) {}
    var b = utf8.decode(r.bodyBytes, allowMalformed: true).replaceAll(RegExp(r'\s+'), ' ');
    if (b.length > 120) b = b.substring(0, 120);
    return 'خطأ من السيرفر (${r.statusCode}) ${r.request?.url.path ?? ''} $b';
  }

  // ---------- تسجيل الدخول ----------
  Future<void> login(String phone, String password) async {
    msisdn = phone.trim();
    _password = password;
    await _auth();
  }

  Future<void> _auth() async {
    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('$base/auth/realms/vf-realm/protocol/openid-connect/token'),
            headers: {
              ..._h(json: false),
              'Accept': 'application/json, text/plain, */*',
              'silentLogin': 'true',
              'digitalId': _digitalId,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'grant_type': 'password',
              'username': msisdn,
              'password': _password,
              'client_secret': _secret,
              'client_id': 'AnaVF',
            },
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException('تعذر الاتصال بالسيرفر، تأكد من الإنترنت');
    }
    if (r.statusCode != 200) {
      if (r.statusCode == 400 || r.statusCode == 401) {
        throw ApiException('رقم الهاتف أو كلمة المرور غير صحيحة');
      }
      throw ApiException(_err(r));
    }
    final j = _dec(r);
    _token = '${j['access_token']}';
    final secs = (j['expires_in'] as num?)?.toInt() ?? 900;
    _exp = DateTime.now().add(Duration(seconds: secs - 30));
    final sc = _scFromJwt(_token);
    if (sc.isNotEmpty) serviceClass = sc;
  }

  String _scFromJwt(String t) {
    try {
      final p = t.split('.')[1];
      final m = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(p))));
      return '${m['userInfo']['serviceClassCode']}';
    } catch (_) {
      return '';
    }
  }

  Future<http.Response> _req(String method, String url,
      {Map<String, String>? extra, String? body}) async {
    if (DateTime.now().isAfter(_exp)) await _auth(); // التوكن عمره 15 دقيقة
    for (var attempt = 0; attempt < 2; attempt++) {
      final rq = http.Request(method, Uri.parse(url));
      rq.headers.addAll(_h(extra: {...?extra, 'Authorization': 'Bearer $_token'}));
      if (body != null) rq.body = body;
      http.Response r;
      try {
        r = await http.Response.fromStream(await rq.send().timeout(const Duration(seconds: 30)));
      } catch (_) {
        throw ApiException('تعذر الاتصال بالسيرفر، تأكد من الإنترنت');
      }
      if (r.statusCode == 401 && attempt == 0) {
        await _auth();
        continue;
      }
      return r;
    }
    throw ApiException('انتهت الجلسة، سجل دخول من جديد');
  }

  // ---------- الرصيد ----------
  Future<double> balance() async {
    final r = await _req(
      'GET',
      '$base/services/dxl/usage/usageConsumptionReport?%40type=aggregated&bucket.product.publicIdentifier=$msisdn',
      extra: {'api-host': 'usageConsumptionHost', 'useCase': 'aggregated', 'api-version': 'v2', 'device-id': _deviceId},
    );
    if (r.statusCode != 200) throw ApiException(_err(r));
    for (final it in (_dec(r) as List)) {
      if (it['@type'] == 'Tariff') {
        if (serviceClass.isEmpty && it['id'] != null) serviceClass = '${it['id']}';
        for (final b in (it['bucket'] as List)) {
          for (final x in (b['bucketBalance'] as List)) {
            if (x['@type'] == 'Remaining') {
              return (x['remainingValue']['amount'] as num).toDouble();
            }
          }
        }
      }
    }
    throw ApiException('تعذر قراءة الرصيد');
  }

  Map<String, String> get _promoExtra => {
        'api-version': 'v2',
        'device-id': _deviceId,
        'buildNumber': _build,
        'operatingSystem': '185001',
        'platform': 'Android',
        'deviceType': 'Infinix-X6728',
      };

  // ---------- العروض (type: 6 وحدات، 2 ميجابيتس) ----------
  Future<List<Offer>> offers(String type) async {
    double bal = 0;
    try {
      bal = await balance();
    } catch (_) {}
    final r = await _req(
      'POST',
      '$base/mobile-app-upgrade/promo/unifiedEligiblityPromo?lang=ar',
      extra: _promoExtra,
      body: jsonEncode({
        'promoId': 2633,
        'channelId': '1',
        'inquiryCustomerInfo': '0',
        'inquireEligibleGifts': '0',
        'inquireCurrentGifts': '1',
        'inquireHistoryGifts': '0',
        'param1': '$bal',
        'param2': int.tryParse(serviceClass) ?? serviceClass,
        'param3': type,
      }),
    );
    if (r.statusCode != 200) throw ApiException(_err(r));
    final j = _dec(r);
    if (j['eCode'] != 0) throw ApiException('${j['errorMessage'] ?? j['eDesc']}');
    final seen = <String>{};
    return (j['gifts'] as List? ?? [])
        .map((g) => Offer.fromJson(g as Map))
        .where((o) => o.amount > 0 && o.days > 0 && o.fee.isNotEmpty)
        .where((o) => seen.add('${o.days}|${o.amount}|${o.fee}'))
        .toList();
  }

  // ---------- الشراء ----------
  Future<String> buy(Offer o) async {
    final r = await _req(
      'POST',
      '$base/mobile-app-upgrade/promo/unifiedRedeemPromo?lang=ar',
      extra: _promoExtra,
      body: jsonEncode({
        'promoId': 2633,
        'channelId': '1',
        'wlistId': 2553,
        'contextualPromoId': '13',
        'triggerId': 189,
        'param3': o.fee,
        'param4': o.days,
        'param6': 0,
        'param1': o.type,
        'param2': o.amount is int ? o.amount : o.amount.toInt(),
      }),
    );
    if (r.statusCode != 200) throw ApiException(_err(r));
    final j = _dec(r);
    if (j['eCode'] != 0) throw ApiException('${j['errorMessage'] ?? j['eDesc']}');
    return 'تم إرسال طلب الاشتراك بنجاح';
  }

  // ---------- الكوبونات ----------
  static const _promoUrl = '$base/services/dxl/promo/promotion';
  Map<String, String> get _promoH =>
      {'channel': 'MOBILE', 'useCase': 'Promo', 'api-version': 'v2', 'device-id': _deviceId};

  Future<List<Coupon>> coupons() async {
    final r = await _req('GET', '$_promoUrl?%40type=Promo&%24.context.type=scratchCoupon', extra: _promoH);
    if (r.statusCode == 404) return [];
    if (r.statusCode != 200) throw ApiException(_err(r));
    return (_dec(r) as List).map((c) => Coupon.fromJson(c as Map)).toList();
  }

  Future<void> scratch(String id) async {
    final r = await _req('POST', _promoUrl,
        extra: _promoH,
        body: jsonEncode({
          'channel': {'id': '5'},
          'context': {'type': 'scratchCoupon'},
          'pattern': [
            {'id': id}
          ],
          '@type': 'Promo'
        }));
    if (r.statusCode != 200) throw ApiException(_err(r));
  }

  Future<void> redeem(String id) async {
    final r = await _req('PATCH', '$_promoUrl/${Uri.encodeComponent(id)}',
        extra: _promoH,
        body: jsonEncode({
          'channel': {'id': '5'},
          'context': {'type': 'scratchCoupon'},
          '@type': 'Promo'
        }));
    if (r.statusCode < 200 || r.statusCode > 299) throw ApiException(_err(r));
  }
}
