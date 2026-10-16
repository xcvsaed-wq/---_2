import 'dart:async';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'app_store.dart';
import 'prayer_service.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.init();
  await NotificationService.init();
  await PrayerService.init();

  if (AppStore.notificationsEnabled) {
    await NotificationService.requestPermissions();
    await NotificationService.scheduleAll();
  }

  runApp(const SalatApp());
}

class SalatApp extends StatefulWidget {
  const SalatApp({super.key});
  @override
  State<SalatApp> createState() => _SalatAppState();
}

class _SalatAppState extends State<SalatApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مواقيت الصلاة',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppStore.isDark ? ThemeMode.dark : ThemeMode.light,
      home: SalatHome(onThemeChanged: () => setState(() {})),
    );
  }
}

class SalatHome extends StatefulWidget {
  const SalatHome({super.key, required this.onThemeChanged});
  final VoidCallback onThemeChanged;

  @override
  State<SalatHome> createState() => _SalatHomeState();
}

class _SalatHomeState extends State<SalatHome> {
  Timer? _ticker;
  late List<PrayerInfo> _prayers;
  late PrayerInfo _next;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _refresh() {
    _prayers = PrayerService.today();
    _next = PrayerService.next();
    _tick();
  }

  void _tick() {
    final now = DateTime.now();
    final diff = _next.time.difference(now);
    if (diff.isNegative) {
      _refresh();
      return;
    }
    setState(() => _remaining = diff);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(onThemeChanged: widget.onThemeChanged),
      ),
    );
    _refresh();
    await NotificationService.scheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _header(now),
            const SizedBox(height: 20),
            _nextCard(),
            const SizedBox(height: 22),
            _sectionTitle('مواقيت اليوم'),
            const SizedBox(height: 12),
            ..._prayers.map(_prayerTile),
            const SizedBox(height: 24),
            _settingsButton(),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'مواقيت الصلاة • الإصدار 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(DateTime now) {
    final hijri = _hijriString(now);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'السلام عليكم',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'مواقيت الصلاة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$hijri — ${_gregorianString(now)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'الوضع الليلي',
          onPressed: () async {
            await AppStore.saveDark(!AppStore.isDark);
            widget.onThemeChanged();
          },
          icon: Icon(
            AppStore.isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _nextCard() {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'الصلاة القادمة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppStore.selectedCity.name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'صلاة ${_next.arabicName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(_next.time),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _timeUnit('$h', 'ساعة'),
              const SizedBox(width: 10),
              _timeUnit('$m', 'دقيقة'),
              const SizedBox(width: 10),
              _timeUnit('$s', 'ثانية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeUnit(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value.padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayerTile(PrayerInfo p) {
    final isNext = p.key == _next.key;
    final isSunrise = p.key == 'sunrise';
    final passed = DateTime.now().isAfter(p.time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isNext
              ? AppTheme.primary.withValues(alpha: 0.10)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isNext
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 1.4)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isNext ? AppTheme.primaryGradient : null,
                color: isNext
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFor(p.key),
                color: isNext
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.arabicName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: passed && !isNext
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isNext ? 'الصلاة القادمة' : (passed ? 'فاتت' : 'قادمة'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isNext
                          ? AppTheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _fmt(p.time),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isNext ? AppTheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'fajr':    return Icons.nightlight_round;
      case 'sunrise': return Icons.wb_twilight;
      case 'dhuhr':   return Icons.wb_sunny_outlined;
      case 'asr':     return Icons.wb_sunny;
      case 'maghrib': return Icons.wb_twilight;
      case 'isha':    return Icons.bedtime_outlined;
    }
    return Icons.access_time;
  }

  Widget _settingsButton() {
    return FilledButton.tonalIcon(
      onPressed: _openSettings,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size.fromHeight(52),
      ),
      icon: const Icon(Icons.settings_outlined),
      label: const Text(
        'الإعدادات',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  static String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.hour < 12 ? 'ص' : 'م';
    return '$h:$m $p';
  }

  static String _gregorianString(DateTime t) {
    const months = [
      'يناير','فبراير','مارس','أبريل','مايو','يونيو',
      'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر',
    ];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
  }

  static String _hijriString(DateTime t) {
    // تحويل تقريبي للهجري (خوارزمية كويتية مبسطة)
    final jd = _julianDay(t);
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j = (((10985 - l2) / 5316).floor()) *
            (((50 * l2) / 17719).floor()) +
        ((l2 / 5670).floor()) * (((43 * l2) / 15238).floor());
    final l3 = l2 -
        ((30 - j) / 15).floor() * (((17719 * j) / 50).floor()) -
        (j / 16).floor() * (((15238 * j) / 43).floor()) +
        29;
    final m = ((24 * l3) / 709).floor();
    final d = l3 - ((709 * m) / 24).floor();
    final y = 30 * n + j - 30;
    const hMonths = [
      'محرم','صفر','ربيع الأول','ربيع الآخر','جمادى الأولى','جمادى الآخرة',
      'رجب','شعبان','رمضان','شوال','ذو القعدة','ذو الحجة',
    ];
    return '$d ${hMonths[m - 1]} $y هـ';
  }

  static double _julianDay(DateTime t) {
    int y = t.year, m = t.month;
    final d = t.day;
    if (m <= 2) { y -= 1; m += 12; }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d + b - 1524.5;
  }
}

// ═══════════════════════════════════════════════════════════
//  Settings Screen
// ═══════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onThemeChanged});
  final VoidCallback onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _pickCity() async {
    final selected = await showModalBottomSheet<EgyptianCity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44, height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'اختر المدينة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: egyptianCities.length,
                  itemBuilder: (_, i) {
                    final c = egyptianCities[i];
                    final sel = c.id == AppStore.cityId;
                    return ListTile(
                      leading: Icon(
                        sel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: sel ? AppTheme.primary : null,
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(
                          fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${c.lat.toStringAsFixed(2)}° , ${c.lng.toStringAsFixed(2)}°',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      await AppStore.saveCity(selected.id);
      await NotificationService.scheduleAll();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _sectionLabel('المدينة'),
          _card([
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text(
                'المدينة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(AppStore.selectedCity.name),
              trailing: const Icon(Icons.chevron_left),
              onTap: _pickCity,
            ),
          ]),
          const SizedBox(height: 18),
          _sectionLabel('الإشعارات'),
          _card([
            SwitchListTile.adaptive(
              value: AppStore.notificationsEnabled,
              onChanged: (v) async {
                await AppStore.saveNotifications(v);
                if (v) {
                  await NotificationService.requestPermissions();
                  await NotificationService.scheduleAll();
                } else {
                  await NotificationService.cancelAll();
                }
                setState(() {});
              },
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text(
                'تفعيل إشعارات الصلاة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('تنبيه تلقائي عند دخول وقت كل صلاة'),
            ),
            const Divider(height: 1),
            SwitchListTile.adaptive(
              value: AppStore.adhanEnabled,
              onChanged: AppStore.notificationsEnabled
                  ? (v) async {
                      await AppStore.saveAdhan(v);
                      await NotificationService.scheduleAll();
                      setState(() {});
                    }
                  : null,
              secondary: const Icon(Icons.volume_up_outlined),
              title: const Text(
                'صوت الأذان',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('تشغيل صوت مخصص عند الإشعار'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text(
                'التذكير قبل الصلاة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                AppStore.minutesBefore == 0
                    ? 'عند الأذان مباشرةً'
                    : 'قبل ${AppStore.minutesBefore} دقيقة',
              ),
              trailing: const Icon(Icons.chevron_left),
              enabled: AppStore.notificationsEnabled,
              onTap: () async {
                final v = await _pickMinutes();
                if (v != null) {
                  await AppStore.saveMinutesBefore(v);
                  await NotificationService.scheduleAll();
                  setState(() {});
                }
              },
            ),
          ]),
          const SizedBox(height: 18),
          _sectionLabel('المظهر'),
          _card([
            SwitchListTile.adaptive(
              value: AppStore.isDark,
              onChanged: (v) async {
                await AppStore.saveDark(v);
                widget.onThemeChanged();
                setState(() {});
              },
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text(
                'الوضع الليلي',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'طريقة الحساب: الهيئة المصرية العامة للمساحة',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'المنطقة الزمنية: Africa/Cairo',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          s,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Future<int?> _pickMinutes() async {
    const options = [0, 5, 10, 15, 20, 30];
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              'التذكير قبل الصلاة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...options.map((m) => ListTile(
                  leading: Icon(
                    AppStore.minutesBefore == m
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppStore.minutesBefore == m ? AppTheme.primary : null,
                  ),
                  title: Text(
                    m == 0 ? 'عند الأذان مباشرةً' : 'قبل $m دقيقة',
                    style: TextStyle(
                      fontWeight: AppStore.minutesBefore == m
                          ? FontWeight.w900
                          : FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, m),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}