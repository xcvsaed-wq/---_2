import 'package:shared_preferences/shared_preferences.dart';

class EgyptianCity {
  final String id;
  final String name;
  final double lat;
  final double lng;
  const EgyptianCity(this.id, this.name, this.lat, this.lng);
}

const egyptianCities = <EgyptianCity>[
  EgyptianCity('cairo',     'القاهرة',    30.0444, 31.2357),
  EgyptianCity('giza',      'الجيزة',     30.0131, 31.2089),
  EgyptianCity('alex',      'الإسكندرية', 31.2001, 29.9187),
  EgyptianCity('portsaid',  'بورسعيد',    31.2653, 32.3019),
  EgyptianCity('suez',      'السويس',     29.9668, 32.5498),
  EgyptianCity('ismailia',  'الإسماعيلية',30.5965, 32.2715),
  EgyptianCity('mansoura',  'المنصورة',   31.0409, 31.3785),
  EgyptianCity('tanta',     'طنطا',       30.7865, 31.0004),
  EgyptianCity('zagazig',   'الزقازيق',   30.5877, 31.5020),
  EgyptianCity('damanhour', 'دمنهور',     31.0341, 30.4682),
  EgyptianCity('kafrelsh',  'كفر الشيخ',  31.1117, 30.9397),
  EgyptianCity('damietta',  'دمياط',      31.4165, 31.8133),
  EgyptianCity('banisuef',  'بني سويف',   29.0661, 31.0994),
  EgyptianCity('fayoum',    'الفيوم',     29.3084, 30.8428),
  EgyptianCity('minya',     'المنيا',     28.1099, 30.7503),
  EgyptianCity('asyut',     'أسيوط',      27.1809, 31.1837),
  EgyptianCity('sohag',     'سوهاج',      26.5591, 31.6957),
  EgyptianCity('qena',      'قنا',        26.1551, 32.7160),
  EgyptianCity('luxor',     'الأقصر',     25.6872, 32.6396),
  EgyptianCity('aswan',     'أسوان',      24.0889, 32.8998),
  EgyptianCity('hurghada',  'الغردقة',    27.2579, 33.8116),
  EgyptianCity('sharm',     'شرم الشيخ',  27.9158, 34.3299),
  EgyptianCity('dahab',     'دهب',        28.5091, 34.5136),
  EgyptianCity('marsa',     'مرسى مطروح', 31.3543, 27.2373),
  EgyptianCity('arish',     'العريش',     31.1313, 33.7984),
  EgyptianCity('siwa',      'سيوة',       29.2032, 25.5195),
];

class AppStore {
  static late SharedPreferences prefs;

  static const _kCity          = 'salat_city';
  static const _kDark          = 'salat_dark';
  static const _kNotif         = 'salat_notif_enabled';
  static const _kAdhan         = 'salat_adhan_enabled';
  static const _kMinutesBefore = 'salat_minutes_before';

  static String cityId = 'cairo';
  static bool isDark = false;
  static bool notificationsEnabled = true;
  static bool adhanEnabled = true;
  static int minutesBefore = 0;

  static EgyptianCity get selectedCity => egyptianCities.firstWhere(
        (c) => c.id == cityId,
        orElse: () => egyptianCities.first,
      );

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    cityId = prefs.getString(_kCity) ?? 'cairo';
    isDark = prefs.getBool(_kDark) ?? false;
    notificationsEnabled = prefs.getBool(_kNotif) ?? true;
    adhanEnabled = prefs.getBool(_kAdhan) ?? true;
    minutesBefore = prefs.getInt(_kMinutesBefore) ?? 0;
  }

  static Future<void> saveCity(String id) async {
    cityId = id;
    await prefs.setString(_kCity, id);
  }

  static Future<void> saveDark(bool v) async {
    isDark = v;
    await prefs.setBool(_kDark, v);
  }

  static Future<void> saveNotifications(bool v) async {
    notificationsEnabled = v;
    await prefs.setBool(_kNotif, v);
  }

  static Future<void> saveAdhan(bool v) async {
    adhanEnabled = v;
    await prefs.setBool(_kAdhan, v);
  }

  static Future<void> saveMinutesBefore(int m) async {
    minutesBefore = m;
    await prefs.setInt(_kMinutesBefore, m);
  }
}