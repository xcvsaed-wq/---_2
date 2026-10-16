import 'package:adhan/adhan.dart';
import 'app_store.dart';

class PrayerInfo {
  final String key;
  final String arabicName;
  final DateTime time;
  const PrayerInfo(this.key, this.arabicName, this.time);
}

const prayerNames = {
  'fajr':    'الفجر',
  'sunrise': 'الشروق',
  'dhuhr':   'الظهر',
  'asr':     'العصر',
  'maghrib': 'المغرب',
  'isha':    'العشاء',
};

class PrayerService {
  static late CalculationParameters _params;

  static Future<void> init() async {
    // الطريقة الرسمية المصرية (الهيئة المصرية العامة للمساحة)
    // في حزمة adhan، اسمها egyptian وليس egyptian_survey_authority
    _params = CalculationMethod.egyptian.getParameters();
    _params.madhab = Madhab.shafi;
  }

  static PrayerTimes _calc(DateTime date, {EgyptianCity? city}) {
    final c = city ?? AppStore.selectedCity;
    final coordinates = Coordinates(c.lat, c.lng);
    final components = DateComponents.from(date);
    return PrayerTimes(coordinates, components, _params);
  }

  static List<PrayerInfo> today({EgyptianCity? city}) {
    final p = _calc(DateTime.now(), city: city);
    return [
      PrayerInfo('fajr',    prayerNames['fajr']!,    p.fajr.toLocal()),
      PrayerInfo('sunrise', prayerNames['sunrise']!, p.sunrise.toLocal()),
      PrayerInfo('dhuhr',   prayerNames['dhuhr']!,   p.dhuhr.toLocal()),
      PrayerInfo('asr',     prayerNames['asr']!,     p.asr.toLocal()),
      PrayerInfo('maghrib', prayerNames['maghrib']!, p.maghrib.toLocal()),
      PrayerInfo('isha',    prayerNames['isha']!,    p.isha.toLocal()),
    ];
  }

  static PrayerInfo next() {
    final now = DateTime.now();
    for (final p in today()) {
      if (p.key == 'sunrise') continue;
      if (p.time.isAfter(now)) return p;
    }
    // كل صلوات النهاردة عدت — فجر بكرة
    final tomorrow = _calc(DateTime.now().add(const Duration(days: 1)));
    return PrayerInfo(
      'fajr',
      prayerNames['fajr']!,
      tomorrow.fajr.toLocal(),
    );
  }

  static List<PrayerInfo> withAdhanOnly({EgyptianCity? city}) {
    return today(city: city).where((p) => p.key != 'sunrise').toList();
  }
}