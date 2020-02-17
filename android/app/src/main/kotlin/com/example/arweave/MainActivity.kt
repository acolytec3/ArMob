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

class MainActivity: FlutterActivity() {
    private val CHANNEL = "armob.dev/signer"

    fun signTransaction(rawTransaction: ByteArray? , n : String?, d : String?): ByteArray? {
        val fact = KeyFactory.getInstance("RSA")
        val spec = RSAPrivateKeySpec(BigInteger(n),BigInteger(d))
        val priv = fact.generatePrivate(spec)
        val s = Signature.getInstance("SHA256withRSA/PSS")
                .apply {
                    initSign(priv)
                    update(rawTransaction)
                }
        return s.sign()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "signTransaction") {
                val rawTransaction = call.argument<ByteArray>("rawTransaction")
                val n = call.argument<String>("n")
                val d = call.argument<String>("d")
                val signature = signTransaction(rawTransaction, n, d)
                result.success(signature)
            }
            else {
                result.notImplemented()
            }
        }
    }
}
