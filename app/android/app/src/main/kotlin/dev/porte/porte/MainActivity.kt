package dev.porte.porte

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "dev.porte/terminal"
    private val reqRunCommand = 1001
    private val permRunCommand = "com.termux.permission.RUN_COMMAND"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingPath: String = ""

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            if (call.method == "openTerminal") {
                val path = call.argument<String>("path") ?: ""
                // A permissão do Termux é "dangerous": manifest sozinho não
                // basta no Android 6+ — é preciso pedir em runtime.
                if (ContextCompat.checkSelfPermission(this, permRunCommand) ==
                    PackageManager.PERMISSION_GRANTED
                ) {
                    result.success(openTermux(path))
                } else {
                    pendingResult = result
                    pendingPath = path
                    ActivityCompat.requestPermissions(this, arrayOf(permRunCommand), reqRunCommand)
                }
            } else if (call.method == "launchTermux") {
                result.success(launchTermux())
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == reqRunCommand) {
            val res = pendingResult
            pendingResult = null
            if (res == null) return
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                res.success(openTermux(pendingPath))
            } else {
                res.success("denied_perm: usuário negou a permissão $permRunCommand (libere em Configurações > Apps > PORTE > Permissões)")
            }
        }
    }

    /**
     * Abre o Termux na [path] via RUN_COMMAND.
     * Action oficial (wiki do Termux): "com.termux.RUN_COMMAND"
     * (a antiga "com.termux.action.RUN_COMMAND" é rejeitada com
     * "Invalid intent action" no Termux >= 0.118).
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
        val intent = Intent("com.termux.RUN_COMMAND").apply {
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
