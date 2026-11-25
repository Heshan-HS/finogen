package com.example.nova_finance

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.example.nova_finance/sms"
    private val THEME_CHANNEL = "com.example.nova_finance/theme"
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        var methodChannel: MethodChannel? = null

        fun notifySmsReceived(sender: String, body: String, timestamp: Long) {
            methodChannel?.invokeMethod("onSmsReceived", mapOf(
                "sender" to sender,
                "body" to body,
                "timestamp" to timestamp
            ))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Theme channel to update Android OS Application Night Mode in real time
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, THEME_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setTheme") {
                val mode = call.arguments as? String ?: "dark"
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? android.app.UiModeManager
                    val targetMode = if (mode == "light") {
                        android.app.UiModeManager.MODE_NIGHT_NO
                    } else {
                        android.app.UiModeManager.MODE_NIGHT_YES
                    }
                    uiModeManager?.setApplicationNightMode(targetMode)
                }
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val readSms = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    val receiveSms = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
                    result.success(readSms && receiveSms)
                }
                "requestPermission" -> {
                    val readSms = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    val receiveSms = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
                    if (readSms && receiveSms) {
                        result.success(true)
                    } else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
                            1001
                        )
                    }
                }
                "getPendingSms" -> {
                    val prefs = getSharedPreferences("finogen_sms_prefs", Context.MODE_PRIVATE)
                    val pendingJson = prefs.getString("pending_sms", "[]") ?: "[]"
                    prefs.edit().putString("pending_sms", "[]").apply()

                    val list = mutableListOf<Map<String, Any>>()
                    try {
                        val array = JSONArray(pendingJson)
                        for (i in 0 until array.length()) {
                            val obj = array.getJSONObject(i)
                            list.add(mapOf(
                                "sender" to obj.optString("sender"),
                                "body" to obj.optString("body"),
                                "timestamp" to obj.optLong("timestamp")
                            ))
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                    result.success(list)
                }
                "getInboxSms" -> {
                    val limit = call.argument<Int>("limit") ?: 500
                    val days = call.argument<Int>("days") ?: 180
                    val smsList = queryInboxSms(limit, days)
                    result.success(smsList)
                }

                "getDeviceInfo" -> {

                    val manufacturer = Build.MANUFACTURER ?: ""

                    val model = Build.MODEL ?: ""

                    val brand = Build.BRAND ?: ""

                    val product = Build.PRODUCT ?: ""

                    val device = Build.DEVICE ?: ""

                    var simOperatorName = ""

                    try {

                        val tm = getSystemService(Context.TELEPHONY_SERVICE) as? android.telephony.TelephonyManager

                        simOperatorName = tm?.simOperatorName ?: ""

                        if (simOperatorName.isEmpty()) {

                            simOperatorName = tm?.networkOperatorName ?: ""

                        }

                    } catch (e: Exception) {

                        e.printStackTrace()

                    }

                    result.success(mapOf(

                        "manufacturer" to manufacturer,

                        "model" to model,

                        "brand" to brand,

                        "product" to product,

                        "device" to device,

                        "simOperator" to simOperatorName

                    ))

                }
                else -> result.notImplemented()
            }
        }
    }

    private fun queryInboxSms(limit: Int, days: Int): List<Map<String, Any>> {
        val resultList = mutableListOf<Map<String, Any>>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            return resultList
        }

        val cutoffMillis = System.currentTimeMillis() - (days.toLong() * 24 * 60 * 60 * 1000)
        val uri: Uri = Telephony.Sms.Inbox.CONTENT_URI
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE
        )
        val selection = "${Telephony.Sms.DATE} >= ? AND (" +
                "${Telephony.Sms.ADDRESS} LIKE ? OR " +
                "${Telephony.Sms.ADDRESS} LIKE ? OR " +
                "${Telephony.Sms.ADDRESS} LIKE ? OR " +
                "${Telephony.Sms.ADDRESS} LIKE ? OR " +
                "${Telephony.Sms.ADDRESS} LIKE ? OR " +
                "${Telephony.Sms.BODY} LIKE ? OR " +
                "${Telephony.Sms.BODY} LIKE ? OR " +
                "${Telephony.Sms.BODY} LIKE ?" +
                ")"
        val selectionArgs = arrayOf(
            cutoffMillis.toString(),
            "%Nation%",
            "%eZ Cash%",
            "%NTB%",
            "%769169810%",
            "%9010%",
            "%CEFTS%",
            "%recharge kara etha%",
            "%769169810%"
        )
        val sortOrder = "${Telephony.Sms.DATE} DESC LIMIT $limit"

        try {
            contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
                val idIdx = cursor.getColumnIndex(Telephony.Sms._ID)
                val addressIdx = cursor.getColumnIndex(Telephony.Sms.ADDRESS)
                val bodyIdx = cursor.getColumnIndex(Telephony.Sms.BODY)
                val dateIdx = cursor.getColumnIndex(Telephony.Sms.DATE)

                while (cursor.moveToNext()) {
                    val id = if (idIdx >= 0) cursor.getString(idIdx) else ""
                    val address = if (addressIdx >= 0) cursor.getString(addressIdx) else ""
                    val body = if (bodyIdx >= 0) cursor.getString(bodyIdx) else ""
                    val date = if (dateIdx >= 0) cursor.getLong(dateIdx) else 0L

                    resultList.add(mapOf(
                        "id" to id,
                        "sender" to address,
                        "body" to body,
                        "timestamp" to date
                    ))
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return resultList
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1001) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}
