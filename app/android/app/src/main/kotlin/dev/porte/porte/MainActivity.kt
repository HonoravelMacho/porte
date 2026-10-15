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
     * Retorna "ok" | "not_installed" | "error" para o Dart dar feedback exato.
     *
     * Estratégia: dispara o serviço DIRETO com Intent explícito (não sofre a
     * restrição de visibilidade de pacotes do Android 11+). Só abre a loja
     * se o start retornar null (serviço inexistente = Termux ausente) ou
     * lançar exceção. O getPackageInfo saiu do caminho principal porque
     * podia dizer "não instalado" com o Termux instalado.
     *
     * O comando usa ";" (e não "&&"): se o cd falhar (ex.: sem
     * termux-setup-storage), o Termux ainda abre num shell em vez de
     * fechar a sessão na hora e parecer que "nada aconteceu".
     */
    private fun openTermux(path: String): String {
        return try {
            val intent = Intent("com.termux.action.RUN_COMMAND").apply {
                setClassName("com.termux", "com.termux.app.RunCommandService")
                putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-lic", "cd \"$path\"; exec bash"))
                putExtra("com.termux.RUN_COMMAND_WORKDIR", path)
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
            }
            val component = if (Build.VERSION.SDK_INT >= 26) {
                startForegroundService(intent)
            } else {
                @Suppress("DEPRECATION")
                startService(intent)
            }
            if (component == null) {
                openStore()
                "not_installed"
            } else {
                "ok"
            }
        } catch (e: Exception) {
            openStore()
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
