package dev.porte.porte

import android.content.Intent
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

    /**
     * Abre o Termux na [path] via RUN_COMMAND.
     * Retorna códigos para o Dart dar feedback exato:
     * "ok" | "null_service" (serviço não existe = Termux ausente/incompatível)
     * | "denied" (Android bloqueou o disparo) | "error" (outra falha).
     *
     * Estratégia: Intent explícito direto (sem getPackageInfo, que no
     * Android 11+ pode dizer "não instalado" com o Termux instalado).
     * Tenta startForegroundService (API 26+) e cai para startService se o
     * sistema recusar. A loja só abre quando o serviço não existe.
     *
     * O comando usa ";" (e não "&&"): se o cd falhar (ex.: sem
     * termux-setup-storage), o Termux ainda abre num shell em vez de
     * fechar a sessão na hora e parecer que "nada aconteceu".
     */
    private fun openTermux(path: String): String {
        val intent = Intent("com.termux.action.RUN_COMMAND").apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-lic", "cd \"$path\"; exec bash"))
            putExtra("com.termux.RUN_COMMAND_WORKDIR", path)
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
        }
        // 1) caminho moderno (API 26+)
        if (Build.VERSION.SDK_INT >= 26) {
            try {
                val component = startForegroundService(intent)
                if (component != null) return "ok"
            } catch (e: SecurityException) {
                return "denied"
            } catch (e: Exception) {
                // cai para o startService legado abaixo
            }
        }
        // 2) caminho legado / fallback
        return try {
            @Suppress("DEPRECATION")
            val component = startService(intent)
            if (component == null) {
                openStore()
                "null_service"
            } else {
                "ok"
            }
        } catch (e: SecurityException) {
            "denied"
        } catch (e: Exception) {
            "error"
        }
    }

    /** Termux atual está no F-Droid (a versão da Play Store é antiga/descontinuada). */
    private fun openStore() {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://f-droid.org/packages/com.termux/")))
        } catch (_: Exception) {}
    }
}
