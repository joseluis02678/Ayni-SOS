package pe.ayni.sos.citizen_app

import android.os.Handler
import android.os.Looper
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.SamplerConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Dart [LiteRtGemmaRuntime] → LiteRT-LM Engine (Gemma 4 E2B `.litertlm`).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "pe.ayni.sos/gemma"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var engine: Engine? = null
    private var conversation: Conversation? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadModel" -> {
                        val path = call.argument<String>("modelPath")
                        if (path.isNullOrBlank()) {
                            result.error("bad_args", "modelPath required", null)
                            return@setMethodCallHandler
                        }
                        executor.execute {
                            try {
                                val ok = synchronized(this) { loadModelInternal(path) }
                                mainHandler.post { result.success(ok) }
                            } catch (t: Throwable) {
                                mainHandler.post {
                                    result.error("load_failed", t.message, null)
                                }
                            }
                        }
                    }
                    "generate" -> {
                        val systemPrompt = call.argument<String>("systemPrompt") ?: ""
                        val userPrompt = call.argument<String>("userPrompt") ?: ""
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        val audioBytes = call.argument<ByteArray>("audioBytes")
                        executor.execute {
                            try {
                                val text = synchronized(this) {
                                    generateInternal(
                                        systemPrompt,
                                        userPrompt,
                                        imageBytes,
                                        audioBytes,
                                    )
                                }
                                mainHandler.post { result.success(text) }
                            } catch (t: Throwable) {
                                mainHandler.post {
                                    result.error("generate_failed", t.message, null)
                                }
                            }
                        }
                    }
                    "dispose" -> {
                        executor.execute {
                            synchronized(this) { disposeInternal() }
                            mainHandler.post { result.success(null) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun loadModelInternal(modelPath: String): Boolean {
        disposeInternal()
        val file = File(modelPath)
        if (!file.exists() || file.length() < 1_000_000L) {
            throw IllegalStateException("Model file missing or too small: $modelPath")
        }
        val config = EngineConfig(
            modelPath = modelPath,
            backend = Backend.CPU(),
            visionBackend = Backend.GPU(),
            audioBackend = Backend.CPU(),
            maxNumTokens = 4096,
            cacheDir = cacheDir.absolutePath,
        )
        val newEngine = Engine(config)
        newEngine.initialize()
        engine = newEngine
        conversation = null
        return true
    }

    private fun ensureConversation(systemPrompt: String): Conversation {
        val eng = engine ?: throw IllegalStateException("Engine not loaded")
        try {
            conversation?.close()
        } catch (_: Throwable) {
        }
        val sampler = SamplerConfig(
            topK = 64,
            topP = 0.95,
            temperature = 0.2,
        )
        val convo = eng.createConversation(
            ConversationConfig(
                samplerConfig = sampler,
                systemInstruction = Contents.of(listOf(Content.Text(systemPrompt))),
            ),
        )
        conversation = convo
        return convo
    }

    private fun generateInternal(
        systemPrompt: String,
        userPrompt: String,
        imageBytes: ByteArray?,
        audioBytes: ByteArray?,
    ): String {
        val convo = ensureConversation(systemPrompt)
        val parts = ArrayList<Content>()
        parts.add(Content.Text(userPrompt))
        if (imageBytes != null && imageBytes.isNotEmpty()) {
            parts.add(Content.ImageBytes(imageBytes))
        }
        if (audioBytes != null && audioBytes.isNotEmpty()) {
            parts.add(Content.AudioBytes(audioBytes))
        }
        val response = convo.sendMessage(Contents.of(parts))
        return extractJson(response.toString())
    }

    private fun extractJson(raw: String): String {
        val start = raw.indexOf('{')
        val end = raw.lastIndexOf('}')
        if (start >= 0 && end > start) {
            return raw.substring(start, end + 1)
        }
        return raw
    }

    private fun disposeInternal() {
        try {
            conversation?.close()
        } catch (_: Throwable) {
        }
        conversation = null
        try {
            engine?.close()
        } catch (_: Throwable) {
        }
        engine = null
    }

    override fun onDestroy() {
        executor.execute { synchronized(this) { disposeInternal() } }
        super.onDestroy()
    }
}
