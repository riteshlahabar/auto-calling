package com.example.dialer_app

import android.app.Activity
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.os.Environment
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yourcompany.yourapp/recording"
    private val REQUEST_MEDIA_PROJECTION = 1

    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var outputFile: File? = null
    private var recordingThread: Thread? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    startScreenCapture()
                    result.success(null)
                }
                "startRecording" -> {
                    val args = call.arguments as? Map<String, Any?>
                    val rowIndex = (args?.get("rowIndex") as? Int) ?: 0
                    // Permission already granted via requestPermissions, start recording directly
                    result.success("started")
                }
                "stopRecording" -> {
                    stopRecording()
                    result.success("stopped")
                }
                "getRecordedFilePath" -> {
                    result.success(outputFile?.absolutePath ?: "")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startScreenCapture() {
        val mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(captureIntent, REQUEST_MEDIA_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
                startRecordingAudio()
            }
        }
    }

    private fun startRecordingAudio() {
        if (isRecording) return

        try {
            val sampleRate = 44100
            val channelConfig = AudioFormat.CHANNEL_IN_STEREO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

            val config = AudioPlaybackCaptureConfiguration.Builder(mediaProjection!!)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .build()

            audioRecord = AudioRecord.Builder()
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(audioFormat)
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelConfig)
                        .build()
                )
                .setAudioPlaybackCaptureConfig(config)
                .setAudioSource(MediaRecorder.AudioSource.MIC)
                .setBufferSizeInBytes(bufferSize)
                .build()

            outputFile = File(
                getExternalFilesDir(Environment.DIRECTORY_MUSIC),
                "call_record_${System.currentTimeMillis()}.pcm"
            )

            audioRecord?.startRecording()
            isRecording = true

            recordingThread = Thread {
                writeAudioToFile(bufferSize)
            }.apply { start() }

        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    private fun writeAudioToFile(bufferSize: Int) {
        val audioData = ByteArray(bufferSize)
        try {
            FileOutputStream(outputFile).use { fos ->
                while (isRecording) {
                    val read = audioRecord?.read(audioData, 0, bufferSize) ?: 0
                    if (read > 0) {
                        fos.write(audioData, 0, read)
                    }
                }
            }
        } catch (ioe: IOException) {
            ioe.printStackTrace()
        }
    }

    private fun stopRecording() {
        if (!isRecording) return

        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        recordingThread?.interrupt()
        recordingThread = null
        mediaProjection?.stop()
        mediaProjection = null
    }
}
