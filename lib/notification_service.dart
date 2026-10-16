import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_store.dart';
import 'prayer_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'prayer_times';
  static const _channelName = 'مواقيت الصلاة';
  static const _channelDesc = 'تنبيهات مواقيت الصلوات الخمس';

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ));
  }

  static Future<bool> requestPermissions() async {
    bool granted = true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
      await android.requestExactAlarmsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> scheduleAll({EgyptianCity? city}) async {
    await cancelAll();
    if (!AppStore.notificationsEnabled) return;

    final prayers = PrayerService.withAdhanOnly(city: city);
    final now = DateTime.now();
    final offset = Duration(minutes: AppStore.minutesBefore);

    int id = 1;
    for (final p in prayers) {
      final target = p.time.subtract(offset);
      if (target.isBefore(now)) {
        id++;
        continue;
      }
      final scheduled = tz.TZDateTime.from(target, tz.local);

      await _plugin.zonedSchedule(
        id,
        'حان وقت صلاة ${p.arabicName}',
        _bodyFor(p),
        scheduled,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // ── إجباري في flutter_local_notifications v17+ ──
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: p.key,
      );
      id++;
    }
  }

  static String _bodyFor(PrayerInfo p) {
    if (AppStore.minutesBefore > 0) {
      return 'باقي ${AppStore.minutesBefore} دقيقة على صلاة ${p.arabicName} — الله أكبر';
    }
    return 'الله أكبر — حي على الصلاة، حي على الفلاح';
  }

  static NotificationDetails _details() {
    final sound = AppStore.adhanEnabled
        ? const RawResourceAndroidNotificationSound('adhan')
        : null;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: sound,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }
}