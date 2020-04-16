package com.example.arweave

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import java.security.Signature
import java.security.KeyFactory
import java.security.spec.RSAPrivateKeySpec
import java.math.BigInteger
import java.util.Base64
import signer.Signer
import android.util.Log
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "armob.dev/signer"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "sign") {
                val rawTransaction = call.argument<ByteArray>("rawTransaction")
                val n = call.argument<String>("n")
                val d = call.argument<String>("d")
                val dp = call.argument<String>("dp")
                val dq = call.argument<String>("dq")
                Log.d("D",d)
                result.success(Signer.sign(rawTransaction, n, d, dp, dq))
            }
            else {
                result.notImplemented()
            }
        }
    }
}
