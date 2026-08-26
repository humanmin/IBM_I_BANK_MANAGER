package com.ibm.money.ibm_money_app

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.ibm.money.ibm_money_app/account_data"
        private const val PICK_TRANSACTION_FILE = 7401
        private const val CAPTURE_PREFERENCES = "toss_notification_capture"
    }

    private var pendingFileResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickTransactionFile" -> pickTransactionFile(result)
                    "decryptExcel" -> decryptExcel(call.arguments, result)
                    "isNotificationAccessGranted" ->
                        result.success(isNotificationAccessGranted())
                    "openNotificationAccessSettings" -> {
                        openNotificationAccessSettings()
                        result.success(null)
                    }
                    "getCapturedTransactions" ->
                        result.success(capturedTransactions())
                    else -> result.notImplemented()
                }
            }
    }

    private fun decryptExcel(arguments: Any?, result: MethodChannel.Result) {
        val values = arguments as? Map<*, *>
        val bytes = values?.get("bytes") as? ByteArray
        val password = values?.get("password") as? String
        if (bytes == null || password.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "파일과 비밀번호를 확인해 주세요.", null)
            return
        }

        Thread {
            try {
                val decrypted = ExcelDecryptor.decrypt(bytes, password)
                runOnUiThread { result.success(decrypted) }
            } catch (_: InvalidExcelPasswordException) {
                runOnUiThread {
                    result.error("BAD_PASSWORD", "엑셀 비밀번호가 맞지 않아요.", null)
                }
            } catch (error: Throwable) {
                Log.e(
                    "ExcelDecryptor",
                    "Excel decryption failed (${error.javaClass.name})",
                    error,
                )
                runOnUiThread {
                    result.error(
                        "DECRYPT_FAILED",
                        "암호화된 엑셀 파일을 열지 못했어요.",
                        error.javaClass.simpleName,
                    )
                }
            }
        }.start()
    }

    private fun pickTransactionFile(result: MethodChannel.Result) {
        if (pendingFileResult != null) {
            result.error("PICK_IN_PROGRESS", "이미 파일 선택 화면이 열려 있어요.", null)
            return
        }
        pendingFileResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "text/csv",
                    "text/comma-separated-values",
                    "text/plain",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    "application/vnd.ms-excel",
                ),
            )
        }
        startActivityForResult(intent, PICK_TRANSACTION_FILE)
    }

    @Deprecated("Deprecated in Android; retained for Flutter document picker compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_TRANSACTION_FILE) return
        val result = pendingFileResult ?: return
        pendingFileResult = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            val displayName = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            } ?: "거래내역"
            val bytes = contentResolver.openInputStream(uri)?.use { input ->
                input.readBytes()
            } ?: throw IllegalStateException("파일을 읽을 수 없습니다.")
            if (bytes.size > 20 * 1024 * 1024) {
                result.error("FILE_TOO_LARGE", "20MB 이하 파일만 가져올 수 있어요.", null)
                return
            }
            result.success(mapOf("name" to displayName, "bytes" to bytes))
        } catch (error: Exception) {
            result.error("FILE_READ_FAILED", "선택한 파일을 읽지 못했어요.", error.message)
        }
    }

    private fun isNotificationAccessGranted(): Boolean {
        val component = ComponentName(this, TossNotificationListener::class.java)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.isNotificationListenerAccessGranted(component)
        } else {
            val enabled = Settings.Secure.getString(
                contentResolver,
                "enabled_notification_listeners",
            ) ?: return false
            enabled.split(":").any {
                ComponentName.unflattenFromString(it) == component
            }
        }
    }

    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
        } else {
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }

    private fun capturedTransactions(): Map<String, Any?> {
        val preferences = getSharedPreferences(CAPTURE_PREFERENCES, MODE_PRIVATE)
        val array = JSONArray(preferences.getString("transactions", "[]"))
        val transactions = mutableListOf<Map<String, Any>>()
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            transactions.add(
                mapOf(
                    "id" to item.optString("id"),
                    "merchant" to item.optString("merchant"),
                    "amount" to item.optInt("amount"),
                    "timestamp" to item.optLong("timestamp"),
                ),
            )
        }
        val balance = if (preferences.contains("balance")) {
            preferences.getInt("balance", 0)
        } else {
            null
        }
        return mapOf("transactions" to transactions, "balance" to balance)
    }
}
