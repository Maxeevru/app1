import 'dart:async';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ ДОБАВЛЕНО

// ============================================================
// ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
// ============================================================
String _lastSmsContent = "";
final AudioPlayer _audioPlayer = AudioPlayer();
final FlutterLocalNotificationsPlugin _notificationsPlugin = // ✅ ДОБАВЛЕНО
    FlutterLocalNotificationsPlugin();

// ============================================================
// ГЛАВНАЯ ТОЧКА ВХОДА
// ============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// ============================================================
// ФОНОВЫЙ ОБРАБОТЧИК СМС
// ============================================================
@pragma('vm:entry-point')
void backGroundMessageHandler(SmsMessage message) async {
  final String? body = message.body;
  if (body == null) return;

  _lastSmsContent = body;
  final String text = body.toUpperCase();

  // Проверка на ОТБОЙ
  if (text.contains("ОТБОЙ") || text.contains("ОТМЕНА")) {
    return;
  }

  // Проверка ключевых слов
  bool isEmergency = false;
  List<String> emergencyKeywords = [
    "RSCHS", "БЕСПИЛОТНАЯ", "РАКЕТНАЯ", "АВИАЦИОННАЯ",
    "ОПАСНОСТЬ", "СНЕГ", "МЕТЕЛЬ", "ГОЛОЛЕД"
  ];

  for (String keyword in emergencyKeywords) {
    if (text.contains(keyword)) {
      isEmergency = true;
      break;
    }
  }

  if (!isEmergency) return;

  // Показ оверлея
  bool? isActive = await FlutterOverlayWindow.isActive();
  if (isActive != true) {
    _lastSmsContent = body;
    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      overlayTitle: "Emergency Alert",
      overlayContent: body,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.left,
    );
  }
}

// ============================================================
// ТОЧКА ВХОДА ДЛЯ ОВЕРЛЕЯ
// ============================================================
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmergencyOverlayScreen(),
    ),
  );
}

// ============================================================
// ГЛАВНЫЙ ЭКРАН
// ============================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Telephony telephony = Telephony.instance;
  String _status = "Проверка разрешений...";
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _initAppLogic();
  }

  Future<void> _initAppLogic() async {
    // Разрешение на оверлей
    bool? overlayAllowed = await FlutterOverlayWindow.isPermissionGranted();
    if (overlayAllowed != true) {
      await FlutterOverlayWindow.requestPermission();
    }

    // Разрешение на СМС
    bool? smsAllowed = await telephony.requestPhoneAndSmsPermissions;

    if (smsAllowed == true) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          backGroundMessageHandler(message);
        },
        onBackgroundMessage: backGroundMessageHandler,
      );

      // ============================================================
      // НОВЫЙ БЛОК ДЛЯ УВЕДОМЛЕНИЙ (вставлен сюда)
      // ============================================================
      const AndroidInitializationSettings initSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsIOS,
      );
      await _notificationsPlugin.initialize(initSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'rsms_channel',
        'РСЧС Оповещения',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      // ============================================================

      setState(() {
        _status = "✅ Утилита успешно запущена!\n\n"
            "📱 Служба РСЧС активна в фоне.\n"
            "📨 При получении экстренной СМС\n"
            "⚠️ появится оповещение поверх всех приложений.\n\n"
            "🔄 Приложение работает даже\n"
            "когда телефон заблокирован.";
        _isServiceRunning = true;
      });
    } else {
      setState(() {
        _status = "❌ Ошибка!\n\n"
            "Дайте доступ к СМС в настройках телефона:\n"
            "Настройки → Приложения → РСЧС → Разрешения → СМС";
        _isServiceRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF111215),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isServiceRunning
                        ? Colors.green.withValues(alpha:0.2)
                        : Colors.red.withValues(alpha:0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isServiceRunning
                        ? Icons.shield_rounded
                        : Icons.warning_rounded,
                    color: _isServiceRunning ? Colors.green : Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isServiceRunning ? _sendTestAlert : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "🧪 ТЕСТОВОЕ ОПОВЕЩЕНИЕ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isServiceRunning
                      ? "🟢 Сервис активен"
                      : "🔴 Сервис остановлен",
                  style: TextStyle(
                    fontSize: 14,
                    color: _isServiceRunning ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendTestAlert() async {
    String testSms = "РСЧС: Краснодарский край, Кущёвский район. "
        "Внимание! Объявлена беспилотная опасность. "
        "Покиньте открытые участки улицы. "
        "В помещении не подходите к окнам! Тел. 112";

    _lastSmsContent = testSms;

    // 👇 ОТПРАВКА УВЕДОМЛЕНИЯ В ШТОРКУ (добавлено)
    await _sendSystemNotification('🚨 РСЧС Оповещение', testSms);

    bool? isActive = await FlutterOverlayWindow.isActive();
    if (isActive != true) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: "Emergency Alert",
        overlayContent: testSms,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.left,
      );
    }
  }

  // ============================================================
  // НОВАЯ ФУНКЦИЯ ДЛЯ ОТПРАВКИ СИСТЕМНЫХ УВЕДОМЛЕНИЙ (добавлена)
  // ============================================================
  Future<void> _sendSystemNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'rsms_channel',
      'РСЧС Оповещения',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notificationsPlugin.show(0, title, body, details);
  }
}

// ============================================================
// ЭКРАН ОВЕРЛЕЯ
// ============================================================
class EmergencyOverlayScreen extends StatefulWidget {
  const EmergencyOverlayScreen({super.key});

  @override
  State<EmergencyOverlayScreen> createState() => _EmergencyOverlayScreenState();
}

class _EmergencyOverlayScreenState extends State<EmergencyOverlayScreen> {
  Timer? _timer;
  String _region = "";
  String _dangerType = "";
  String _formattedText = "";
  bool _isSoundPlaying = false;

  @override
  void initState() {
    super.initState();
    _parseSmsAndShow();
  }

  void _parseSmsAndShow() {
    String rawSms = _lastSmsContent;
    if (rawSms.isEmpty) {
      rawSms = "Объявлена воздушная опасность. Срочно зайдите в помещение.";
    }

    String smsUpper = rawSms.toUpperCase();

    // Определение региона
    if (smsUpper.contains("КРАСНОДАР") ||
        smsUpper.contains("КУБАНЬ") ||
        smsUpper.contains("КУЩЁВСК") ||
        smsUpper.contains("КУЩЕВСК")) {
      _region = "Краснодарский край";
    } else if (smsUpper.contains("РОСТОВ") ||
        smsUpper.contains("ДОН") ||
        smsUpper.contains("РОСТОВСКАЯ")) {
      _region = "Ростовская область";
    } else {
      _region = "Внимание";
    }

    // Определение типа опасности
    if (smsUpper.contains("БЕСПИЛОТНАЯ")) {
      _dangerType = "БЕСПИЛОТНАЯ ОПАСНОСТЬ";
    } else if (smsUpper.contains("РАКЕТНАЯ")) {
      _dangerType = "РАКЕТНАЯ ОПАСНОСТЬ";
    } else if (smsUpper.contains("АВИАЦИОННАЯ")) {
      _dangerType = "АВИАЦИОННАЯ ОПАСНОСТЬ";
    } else if (smsUpper.contains("СНЕГ") ||
        smsUpper.contains("МЕТЕЛЬ") ||
        smsUpper.contains("ГОЛОЛЕД") ||
        smsUpper.contains("НАЛИПАНИЕ")) {
      _dangerType = "ПОГОДНЫЕ УСЛОВИЯ";
    } else {
      _dangerType = "ЭКСТРЕННАЯ СИТУАЦИЯ";
    }

    // Очистка текста
    String cleanText = rawSms;
    cleanText = cleanText.replaceAll(
        RegExp(r'^[РСЧШХ\s:,-]+', caseSensitive: false),
        ''
    ).trim();
    cleanText = cleanText.replaceAll(RegExp(r'ВНИМАНИЕ!?\s*', caseSensitive: false), '');
    cleanText = cleanText.replaceAll(RegExp(r'РСЧС:?\s*', caseSensitive: false), '');

    if (cleanText.isNotEmpty) {
      cleanText = cleanText[0].toUpperCase() + cleanText.substring(1);
    }

    // Формирование текста
    if (_region == "Внимание") {
      _formattedText = "RSCHS: $_region! Объявлена $_dangerType. $cleanText";
    } else {
      _formattedText = "RSCHS: $_region. Внимание! Объявлена $_dangerType. $cleanText";
    }

    _playAlertSound();

    _timer = Timer(const Duration(seconds: 15), () {
      _closeOverlay();
    });

    setState(() {});
  }

  void _playAlertSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isSoundPlaying = true;
    } catch (e) {
      print("Звук не найден, используем вибрацию");
    }
  }

  void _closeOverlay() async {
    if (_isSoundPlaying) {
      await _audioPlayer.stop();
      _isSoundPlaying = false;
    }
    _timer?.cancel();
    bool? isActive = await FlutterOverlayWindow.isActive();
    if (isActive == true) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isSoundPlaying) {
      _audioPlayer.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.black.withValues(alpha:0.75),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha:0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "🔊",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 14,
            right: 14,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                _closeOverlay();
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.96),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 45,
                      offset: Offset(0, 20),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CustomPaint(
                          size: const Size(22, 20),
                          painter: TrianglePainter(),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "EMERGENCY ALERTS",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _closeOverlay,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha:0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _dangerType,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formattedText,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _closeOverlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "ПОНЯТНО, ПРИНЯЛ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Закроется автоматически через 15 секунд",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ТРЕУГОЛЬНИК
// ============================================================
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFCC00)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = const TextSpan(
      text: '!',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontSize: 14,
        fontFamily: 'Arial',
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
          (size.width - textPainter.width) / 2,
          size.height - textPainter.height - 2
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
