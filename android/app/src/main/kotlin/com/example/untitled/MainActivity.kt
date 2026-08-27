package com.example.untitled

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.shounakmulay.telephony.TelephonyPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Инициализация телефонии, чтобы релизная сборка не падала
        TelephonyPlugin.registerWith(flutterEngine)
    }
}
