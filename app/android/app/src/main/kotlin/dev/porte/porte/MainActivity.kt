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
            } else if (call.method == "launchTermux") {
                result.success(launchTermux())
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Abre o Termux na [path] via RUN_COMMAND.
     * Retorna "ok" ou "CODIGO: detalhe" com a exceção real
     * (classe + mensagem), para o Dart exibir em diálogo com copiar.
     * Códigos: "denied" (Android bloqueou), "null_service" (serviço não
     * existe = Termux ausente/incompatível), "error" (outra falha).
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
            } catch (e: Exception) {
                return "denied: ${e.javaClass.simpleName}: ${e.message}"
            }
        }
        // 2) caminho legado / fallback
        return try {
            @Suppress("DEPRECATION")
            val component = startService(intent)
            if (component == null) {
                openStore()
                "null_service: startService retornou null (serviço com.termux.app.RunCommandService não existe)"
            } else {
                "ok"
            }
        } catch (e: Exception) {
            "error: ${e.javaClass.simpleName}: ${e.message}"
        }
    }

    /** Termux atual está no F-Droid (a versão da Play Store é antiga/descontinuada). */
    private fun openStore() {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://f-droid.org/packages/com.termux/")))
        } catch (_: Exception) {}
    }

    /**
     * Plano B sem permissão: abre o app Termux na tela inicial (launch intent).
     * Não precisa de RUN_COMMAND — sempre funciona com o Termux instalado.
     * Retorna "ok" ou "missing: ...".
     */
    private fun launchTermux(): String {
        return try {
            val launch = packageManager.getLaunchIntentForPackage("com.termux")
            if (launch == null) {
                openStore()
                "missing: Termux não encontrado pelo PackageManager"
            } else {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launch)
                "ok"
            }
        } catch (e: Exception) {
            "error: ${e.javaClass.simpleName}: ${e.message}"
        }
    }
}
