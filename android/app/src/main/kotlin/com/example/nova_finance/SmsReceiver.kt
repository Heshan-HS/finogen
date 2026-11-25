package com.example.nova_finance

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONObject

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return

            for (sms in messages) {
                val sender = sms.displayOriginatingAddress ?: ""
                val body = sms.displayMessageBody ?: ""
                val timestamp = sms.timestampMillis

                val upperSender = sender.uppercase()
                val upperBody = body.uppercase()
                val isTarget = upperSender.contains("NATIONS") ||
                               (upperSender.contains("EZ") && upperSender.contains("CASH")) ||
                               upperSender.contains("NTB") ||
                               upperBody.contains("NATIONSSMS") ||
                               upperBody.contains("EZ CASH") ||
                               sender.contains("769169810") || body.contains("769169810") || sender.contains("9010")

                if (isTarget) {
                    MainActivity.notifySmsReceived(sender, body, timestamp)
                    savePendingSms(context, sender, body, timestamp)
                }
            }
        }
    }

    private fun savePendingSms(context: Context, sender: String, body: String, timestamp: Long) {
        try {
            val prefs = context.getSharedPreferences("finogen_sms_prefs", Context.MODE_PRIVATE)
            val existingJson = prefs.getString("pending_sms", "[]") ?: "[]"
            val array = JSONArray(existingJson)
            val item = JSONObject()
            item.put("sender", sender)
            item.put("body", body)
            item.put("timestamp", timestamp)
            array.put(item)
            prefs.edit().putString("pending_sms", array.toString()).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}