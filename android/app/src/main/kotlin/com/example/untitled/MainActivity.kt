package com.example.untitled

import android.content.Context
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.untitled/sms"
    private val smsReceiver = SmsReceiver()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        SmsReceiver.methodChannel = channel

        // Динамически регистрируем приемник СМС с флагами безопасности Android 15
        val filter = IntentFilter("android.provider.Telephony.SMS_RECEIVED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            registerReceiver(smsReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(smsReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(smsReceiver)
        } catch (e: Exception) {
            // Игнорируем если уже удален
        }
    }
}
