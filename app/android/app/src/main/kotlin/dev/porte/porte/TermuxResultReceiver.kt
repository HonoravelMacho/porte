package dev.porte.porte

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * Recebe o veredito do Termux (RUN_COMMAND_PENDING_INTENT) e repassa ao Dart.
 * Chaves exatas de TermuxConstants (termux-shared): pacote "result" com
 * "stdout", "stderr", "exitCode" (int), "err" (int, -1 = sem erro interno)
 * e "errmsg".
 */
class TermuxResultReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        try {
            val b: Bundle? = intent.getBundleExtra(EXTRA_RESULT_BUNDLE)
            val map = HashMap<String, Any?>()
            map["hasResult"] = (b != null)
            map["stdout"] = b?.getString("stdout")?.take(2000)
            map["stderr"] = b?.getString("stderr")?.take(2000)
            map["exitCode"] = if (b != null && b.containsKey("exitCode")) b.getInt("exitCode") else null
            map["err"] = if (b != null && b.containsKey("err")) b.getInt("err") else null
            map["errmsg"] = b?.getString("errmsg")?.take(2000)
            MainActivity.deliverResult(map)
        } catch (e: Exception) {
            MainActivity.deliverResult(
                mapOf("hasResult" to false, "error" to "${e.javaClass.simpleName}: ${e.message}")
            )
        }
    }

    companion object {
        const val EXTRA_RESULT_BUNDLE = "result"
    }
}
