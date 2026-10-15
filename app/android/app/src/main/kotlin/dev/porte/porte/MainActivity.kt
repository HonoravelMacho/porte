package dev.porte.porte

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "dev.porte/terminal"

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            if (call.method == "openTerminal") {
                val path = call.argument<String>("path") ?: ""
                result.success(openTermux(path))
            } else {
                result.notImplemented()
            }
        }
    }

    /** Tenta RUN_COMMAND do Termux com cwd = pasta atual; false => Dart faz fallback. */
    private fun openTermux(path: String): Boolean {
        return try {
            val intent = Intent("com.termux.action.RUN_COMMAND").apply {
                setClassName("com.termux", "com.termux.app.RunCommandService")
                putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-lic", "cd \"$path\" && exec bash"))
                putExtra("com.termux.RUN_COMMAND_WORKDIR", path)
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
            }
            startService(intent)
            true
        } catch (e: Exception) {
            try {
                // Fallback: abre o app Termux na Play Store
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=com.termux")))
            } catch (_: Exception) {}
            false
        }
    }
}
