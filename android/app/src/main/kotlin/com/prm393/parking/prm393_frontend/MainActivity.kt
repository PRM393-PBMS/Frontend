package com.prm393.parking.prm393_frontend

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // App gửi trạng thái vé (đang gửi xe / đặt chỗ / không có gì) cho widget màn hình chính.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pbms/home_widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        @Suppress("UNCHECKED_CAST")
                        val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                        ParkingWidgetProvider.save(this, data)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
