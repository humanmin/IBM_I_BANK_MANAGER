package com.ibm.money.ibm_money_app

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class TossNotificationListener : NotificationListenerService() {
    companion object {
        private const val CAPTURE_PREFERENCES = "toss_notification_capture"
        private const val MAX_SAVED_TRANSACTIONS = 1000

        private val expensePatterns = listOf(
            Regex("(?:출금|결제|사용|승인)\\s*([0-9][0-9,]*)\\s*원"),
            Regex("([0-9][0-9,]*)\\s*원\\s*(?:출금|결제|사용|승인)"),
        )
        private val balancePattern =
            Regex("(?:잔액|남은 금액)\\s*[:：]?\\s*([0-9][0-9,]*)\\s*원")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null || !sbn.packageName.startsWith("viva.republica")) return
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()
        val combined = listOf(title, text, bigText)
            .filter { it.isNotBlank() }
            .distinct()
            .joinToString("\n")

        if (combined.contains("입금") ||
            combined.contains("환불") ||
            combined.contains("취소")
        ) {
            saveBalanceIfPresent(combined)
            return
        }

        val amount = expensePatterns.firstNotNullOfOrNull { pattern ->
            pattern.find(combined)?.groupValues?.getOrNull(1)
                ?.replace(",", "")
                ?.toIntOrNull()
        }
        saveBalanceIfPresent(combined)
        if (amount == null || amount <= 0) return

        val merchant = extractMerchant(title, text, bigText, amount)
        val preferences = getSharedPreferences(CAPTURE_PREFERENCES, MODE_PRIVATE)
        val array = try {
            JSONArray(preferences.getString("transactions", "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        val id = "toss-${sbn.postTime}-${sbn.key.hashCode()}"
        for (index in 0 until array.length()) {
            if (array.optJSONObject(index)?.optString("id") == id) return
        }
        array.put(
            JSONObject()
                .put("id", id)
                .put("merchant", merchant)
                .put("amount", amount)
                .put("timestamp", sbn.postTime),
        )
        while (array.length() > MAX_SAVED_TRANSACTIONS) array.remove(0)
        preferences.edit().putString("transactions", array.toString()).apply()
    }

    private fun saveBalanceIfPresent(content: String) {
        val balance = balancePattern.find(content)?.groupValues?.getOrNull(1)
            ?.replace(",", "")
            ?.toIntOrNull() ?: return
        getSharedPreferences(CAPTURE_PREFERENCES, MODE_PRIVATE)
            .edit()
            .putInt("balance", balance)
            .apply()
    }

    private fun extractMerchant(
        title: String,
        text: String,
        bigText: String,
        amount: Int,
    ): String {
        val candidates = listOf(bigText, text, title)
            .flatMap { it.lines() }
            .map { line ->
                line
                    .replace("${String.format("%,d", amount)}원", " ")
                    .replace("${amount}원", " ")
                    .replace(Regex("(?:출금|결제|사용|승인|완료|토스뱅크)"), " ")
                    .replace(Regex("\\d{1,2}:\\d{2}"), " ")
                    .replace(Regex("\\s+"), " ")
                    .trim(' ', '·', '-', ':')
            }
            .filter { it.isNotBlank() && it.any(Char::isLetter) }
        return candidates.maxByOrNull { it.length }?.take(60) ?: "토스뱅크 거래"
    }
}
