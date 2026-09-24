package com.example.naattulink

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import java.io.OutputStream
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.naattulink.upi/payment"
    private val UPI_PAYMENT_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("NaattuLinkUPI", "MethodChannel registered")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("NaattuLinkUPI", "Method received: ${call.method}")
            when (call.method) {
                "initiatePayment" -> {
                    if (pendingResult != null) {
                        result.error("ALREADY_ACTIVE", "A UPI payment is already in progress", null)
                        return@setMethodCallHandler
                    }

                    val pa = call.argument<String>("pa")
                    val pn = call.argument<String>("pn")
                    val am = call.argument<String>("am")
                    val tr = call.argument<String>("tr")
                    val tn = call.argument<String>("tn")
                    val cu = call.argument<String>("cu") ?: "INR"

                    if (pa == null || am == null) {
                        result.error("INVALID_ARGS", "Missing pa or am", null)
                        return@setMethodCallHandler
                    }

                    val uriBuilder = Uri.Builder()
                        .scheme("upi")
                        .authority("pay")
                        .appendQueryParameter("pa", pa)
                        .appendQueryParameter("am", am)
                        .appendQueryParameter("cu", cu)

                    if (pn != null) uriBuilder.appendQueryParameter("pn", pn)
                    if (tr != null) uriBuilder.appendQueryParameter("tr", tr)
                    if (tn != null) uriBuilder.appendQueryParameter("tn", tn)

                    val uri = uriBuilder.build()
                    val upiIntent = Intent(Intent.ACTION_VIEW, uri)

                    // Force a chooser so the user can select their preferred app
                    val chooserIntent = Intent.createChooser(upiIntent, "Pay with...")
                    
                    // Verify there's an app that can handle the intent
                    if (upiIntent.resolveActivity(packageManager) != null) {
                        pendingResult = result
                        startActivityForResult(chooserIntent, UPI_PAYMENT_REQUEST_CODE)
                    } else {
                        result.error("NO_UPI_APP", "No compatible UPI application found", null)
                    }
                }
                "saveImageToDownloads" -> {
                    Log.d("NaattuLinkUPI", "saveImageToDownloads received")
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "NaattuLink_Payment_QR.png"

                    if (bytes == null) {
                        result.error("INVALID_ARGS", "Missing image bytes", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val resolver = context.contentResolver
                        val contentValues = ContentValues().apply {
                            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                put(MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS + "/NaattuLink")
                                put(MediaStore.MediaColumns.IS_PENDING, 1)
                            }
                        }

                        Log.d("NaattuLinkUPI", "Saving QR to Downloads/NaattuLink")
                        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                        } else {
                            resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                        }

                        if (uri != null) {
                            resolver.openOutputStream(uri)?.use { outputStream ->
                                outputStream.write(bytes)
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                contentValues.clear()
                                contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                                resolver.update(uri, contentValues, null, null)
                            }
                            Log.d("NaattuLinkUPI", "QR saved successfully")
                            result.success(true)
                        } else {
                            result.error("IO_ERROR", "Failed to create MediaStore entry", null)
                        }
                    } catch (e: Exception) {
                        result.error("IO_ERROR", e.localizedMessage ?: "Unknown IO Error", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == UPI_PAYMENT_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null

            if (result != null) {
                if (data != null) {
                    val responseStr = data.getStringExtra("response") ?: ""
                    
                    val responseMap = mutableMapOf<String, String>()
                    responseMap["rawResponse"] = responseStr

                    // Parse the query-parameter-style string that UPI apps return
                    // e.g., txnId=...&responseCode=00&Status=SUCCESS&txnRef=...
                    val pairs = responseStr.split("&")
                    for (pair in pairs) {
                        val parts = pair.split("=")
                        if (parts.size == 2) {
                            responseMap[parts[0]] = parts[1]
                        }
                    }
                    
                    val status = responseMap["Status"]?.uppercase() ?: "UNKNOWN"
                    responseMap["status"] = status
                    
                    result.success(responseMap)
                } else {
                    // Empty intent data usually means cancelled
                    val responseMap = mutableMapOf<String, String>()
                    responseMap["status"] = "CANCELLED"
                    responseMap["rawResponse"] = "Empty Intent Data"
                    result.success(responseMap)
                }
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
