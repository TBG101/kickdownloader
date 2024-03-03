package com.example.kickdownloader

import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File


class MainActivity : FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/battery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "openDir") {
                val path = call.argument<String>("path")
                Log.i("kick", path.toString())
                if (path != null) {
                    openDir(path)
                }
                result.success(null)

            } else {
                result.notImplemented()
            }
        }
    }

    fun openDir(path: String) {
        val directory = File(path)
        Log.i("kick", (directory.exists() && directory.isDirectory).toString())
        if (directory.exists() && directory.isDirectory) {
            // Open the directory using an intent
            val intent = Intent(Intent.ACTION_VIEW)
            val uri: Uri = Uri.parse(path)

            intent.setDataAndType(uri, "resources/*");
            startActivityForResult(intent, 221)
            startActivity(intent);
        }
    }

}
