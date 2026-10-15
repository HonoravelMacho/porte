package dev.porte.porte

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
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

    private fun isInstalled(pkg: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 33) {
                packageManager.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(pkg, 0)
            }
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    /**
     * Abre o Termux na [path] via RUN_COMMAND.
     * Retorna false (e abre a página do Termux) quando ele não está instalado
     * — antes o código retornava true mesmo sem o Termux, e nada acontecia.
     */
    private fun openTermux(path: String): Boolean {
        if (!isInstalled("com.termux")) {
            openStore()
            return false
        }
        return try {
            val intent = Intent("com.termux.action.RUN_COMMAND").apply {
                setClassName("com.termux", "com.termux.app.RunCommandService")
                putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-lic", "cd \"$path\" && exec bash"))
                putExtra("com.termux.RUN_COMMAND_WORKDIR", path)
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
            }
            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
            true
        } catch (e: Exception) {
            openStore()
            false
        }
    }

    /** Termux atual está no F-Droid (a versão da Play Store é antiga/descontinuada). */
    private fun openStore() {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://f-droid.org/packages/com.termux/")))
        } catch (_: Exception) {}
    }
}
