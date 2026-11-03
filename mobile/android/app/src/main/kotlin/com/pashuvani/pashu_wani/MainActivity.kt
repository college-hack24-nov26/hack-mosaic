package com.pashuvani.pashu_wani

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.SystemClock
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.pashuvani.pashu_wani/tflite"
    private val executor = Executors.newSingleThreadExecutor()
    private val interpreters = mutableMapOf<String, Interpreter>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "classifyImage" -> {
                        val imagePath = call.argument<String>("imagePath")
                        val species = call.argument<String>("species") ?: "bovine"
                        if (imagePath.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "imagePath is required", null)
                            return@setMethodCallHandler
                        }
                        executor.execute {
                            try {
                                val output = runTfliteInference(imagePath, species)
                                runOnUiThread { result.success(output) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("TFLITE_ERROR", e.message ?: "Inference failed", null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getOrLoadInterpreter(assetPath: String): Interpreter {
        return synchronized(interpreters) {
            interpreters.getOrPut(assetPath) {
                val loader = FlutterInjector.instance().flutterLoader()
                val lookupKey = loader.getLookupKeyForAsset(assetPath)
                val bytes = applicationContext.assets.open(lookupKey).use { it.readBytes() }
                val modelBuffer = ByteBuffer.allocateDirect(bytes.size)
                    .order(ByteOrder.nativeOrder())
                modelBuffer.put(bytes)
                modelBuffer.rewind()
                val options = Interpreter.Options().apply { setNumThreads(2) }
                Interpreter(modelBuffer, options)
            }
        }
    }

    private fun runTfliteInference(imagePath: String, species: String): Map<String, Any> {
        val startMs = SystemClock.elapsedRealtime()
        val imgFile = File(imagePath)
        if (!imgFile.exists()) {
            throw IllegalArgumentException("Image file does not exist: $imagePath")
        }

        val isAvian = species.lowercase() in listOf("avian", "poultry", "chicken")
        val primaryAsset = if (isAvian) {
            "assets/ml/livestock_disease_classifier.tflite"
        } else {
            "assets/ml/bovine_disease_classifier.tflite"
        }

        // Fallback to bovine model if avian model uses newer ops not supported by runtime
        val (interpreter, usedBovineModel) = try {
            Pair(getOrLoadInterpreter(primaryAsset), !isAvian)
        } catch (_: Exception) {
            Pair(getOrLoadInterpreter("assets/ml/bovine_disease_classifier.tflite"), true)
        }

        val rawBitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalArgumentException("Could not decode image: $imagePath")
        val resized = Bitmap.createScaledBitmap(rawBitmap, 224, 224, true)

        // Exact preprocessing per ML_INTEGRATION.md §1.2:
        // (1, 224, 224, 3) float32 scaled to [-1.0, 1.0]: (pixel / 127.5f) - 1.0f
        val inputBuffer = ByteBuffer.allocateDirect(1 * 224 * 224 * 3 * 4)
            .order(ByteOrder.nativeOrder())
        val pixels = IntArray(224 * 224)
        resized.getPixels(pixels, 0, 224, 0, 0, 224, 224)

        for (pixel in pixels) {
            val r = (pixel shr 16) and 0xFF
            val g = (pixel shr 8) and 0xFF
            val b = pixel and 0xFF
            inputBuffer.putFloat((r / 127.5f) - 1.0f)
            inputBuffer.putFloat((g / 127.5f) - 1.0f)
            inputBuffer.putFloat((b / 127.5f) - 1.0f)
        }
        inputBuffer.rewind()

        val outputBuffer = Array(1) { FloatArray(2) }
        interpreter.run(inputBuffer, outputBuffer)
        val elapsedMs = (SystemClock.elapsedRealtime() - startMs).toInt()

        val prob0 = outputBuffer[0][0].toDouble()
        val prob1 = outputBuffer[0][1].toDouble()

        val class0Code = if (usedBovineModel) "healthy_cattle" else "coccidiosis"
        val class1Code = if (usedBovineModel) "suspected_bovine_disease" else "healthy_poultry"
        val class0Raw = if (usedBovineModel) "0 Healthy Cow" else "Coccidiosis"
        val class1Raw = if (usedBovineModel) "1 Sick Cow" else "Healthy"

        val topIsClass1 = prob1 >= prob0
        val topLabel = if (topIsClass1) class1Code else class0Code
        val topRawLabel = if (topIsClass1) class1Raw else class0Raw
        val topConfidence = if (topIsClass1) prob1 else prob0
        val isHealthy = (usedBovineModel && !topIsClass1) || (!usedBovineModel && topIsClass1)

        return mapOf(
            "model_version" to if (usedBovineModel) "bovine_tflite_v1.0.0" else "mobilenetv3_small_v1.0.0",
            "top_label" to topLabel,
            "top_raw_label" to topRawLabel,
            "top_confidence" to topConfidence,
            "is_healthy" to isHealthy,
            "inconclusive" to (topConfidence < 0.65),
            "inference_ms" to elapsedMs,
            "scores" to listOf(
                mapOf("label" to class0Code, "raw_label" to class0Raw, "score" to prob0),
                mapOf("label" to class1Code, "raw_label" to class1Raw, "score" to prob1)
            ),
            "disclaimer" to "preliminary_screening_not_a_diagnosis"
        )
    }

    override fun onDestroy() {
        synchronized(interpreters) {
            interpreters.values.forEach { it.close() }
            interpreters.clear()
        }
        executor.shutdown()
        super.onDestroy()
    }
}
