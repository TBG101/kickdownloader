package com.example.kickdownloader

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/battery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent =
                        Intent(this, MyService::class.java) // Build the intent for the service
                    startService(intent)
                    result.success(null)
                }
                "stopService" -> {
                    val intent =
                        Intent(this, MyService::class.java) // Build the intent for the service
                    stopService(intent)
                    result.success(null)
                }

                "openDir" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        playVideo(path)
                    }
                    result.success(null)
                }

                "deviceVersion" -> {
                    result.success(android.os.Build.VERSION.SDK_INT)

                }

                else -> {
                    result.notImplemented()

                }

            }
        }
    }

    private fun playVideo(path: String) {

        // Create a Uri from the file path
        val uri = Uri.parse(path)

        // Create an intent with ACTION_VIEW action
        val intent = Intent(Intent.ACTION_VIEW)

        // Set the data and type for the intent
        intent.setDataAndType(uri, "video/mp4")

        if (intent.resolveActivity(packageManager) != null) {
            // Start the activity with the intent
            startActivity(intent)
        } else {
            // Handle the case where no app can handle the intent
        }
    }

}
