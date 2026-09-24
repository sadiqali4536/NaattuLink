package com.example.swift_clean

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

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.naattulink.upi/payment"
    private val UPI_PAYMENT_REQUEST_CODE = 123
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("NaattuLinkUPI", "MethodChannel registered")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("NaattuLinkUPI", "Method received: ${call.method}")
            when (call.method) {
                "initiatePayment" -> {
                    println("========== NATIVE UPI DEBUG ==========")
                    println("Native UPI: initiatePayment received")
                    pendingResult = result

                    val pa = call.argument<String>("pa") ?: ""
                    val pn = call.argument<String>("pn") ?: ""
                    val tr = call.argument<String>("tr") ?: ""
                    val tn = call.argument<String>("tn") ?: ""
                    val am = call.argument<String>("am") ?: ""
                    val cu = call.argument<String>("cu") ?: "INR"

                    var uriString = "upi://pay?pa=$pa&pn=$pn&am=$am&cu=$cu"
                    if (tr.isNotEmpty()) uriString += "&tr=$tr"
                    if (tn.isNotEmpty()) uriString += "&tn=$tn"
                    val uri = Uri.parse(uriString)
                    val intent = Intent(Intent.ACTION_VIEW, uri)

                    println("Native UPI: launching chooser")
                    val chooser = Intent.createChooser(intent, "Pay with...")
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivityForResult(chooser, UPI_PAYMENT_REQUEST_CODE)
                    } else {
                        val errorMap = mapOf(
                            "status" to "NO_UPI_APP",
                            "rawResponse" to "No UPI app found on device"
                        )
                        pendingResult?.success(errorMap)
                        pendingResult = null
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
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == UPI_PAYMENT_REQUEST_CODE) {
            println("========== NATIVE UPI RESULT ==========")
            println("resultCode = $resultCode")
            println("data = ${data?.dataString}")
            println("extras = ${data?.extras?.keySet()?.associateWith { data.extras?.get(it) }}")

            if (data != null) {
                val response = data.getStringExtra("response") ?: ""
                println("rawResponse = $response")
                val resMap = parseUpiResponse(response)
                
                println("Status = ${resMap["status"]}")
                println("responseCode = ${resMap["responseCode"]}")
                println("txnId = ${resMap["txnId"]}")
                println("txnRef = ${resMap["txnRef"]}")
                println("ApprovalRefNo = ${resMap["ApprovalRefNo"]}")
                println("========================================")
                
                println("Native UPI: returning result to Flutter")
                pendingResult?.success(resMap)
            } else {
                println("========================================")
                println("Native UPI: returning result to Flutter (CANCELLED/NULL DATA)")
                val resMap = mapOf(
                    "status" to "CANCELLED",
                    "rawResponse" to "User cancelled or no data returned"
                )
                pendingResult?.success(resMap)
            }
            pendingResult = null
        }
    }

    private fun parseUpiResponse(response: String): Map<String, String> {
        val map = mutableMapOf<String, String>()
        val parts = response.split("&")
        for (part in parts) {
            val keyValue = part.split("=")
            if (keyValue.size == 2) {
                map[keyValue[0].lowercase()] = keyValue[1]
            }
        }

        val statusStr = map["status"]?.uppercase() ?: "UNKNOWN"
        val status = when {
            statusStr.contains("SUCCESS") || statusStr.contains("SUBMITTED") -> "SUCCESS"
            statusStr.contains("FAILURE") -> "FAILURE"
            else -> "UNKNOWN"
        }

        return mapOf(
            "status" to status,
            "txnId" to (map["txnid"] ?: ""),
            "responseCode" to (map["responsecode"] ?: ""),
            "txnRef" to (map["txnref"] ?: ""),
            "ApprovalRefNo" to (map["approvalrefno"] ?: ""),
            "rawResponse" to response
        )
    }
}
