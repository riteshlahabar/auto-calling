package com.yourcompany.yourapp

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.MediaRecorder
import android.media.projection.MediaProjectionManager
import android.os.Environment
import android.util.Log
import java.io.File

class AudioRecorder(private val activity: Activity) {
    private val TAG = "AudioRecorder"
    private var mediaRecorder: MediaRecorder? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    var isRecording = false
        private set
    private var outputFilePath: String? = null
    private val REQUEST_CODE_CAPTURE_PERM = 1234

    fun requestPermissions() {
        mediaProjectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val permissionIntent = mediaProjectionManager?.createScreenCaptureIntent()
        activity.startActivityForResult(permissionIntent, REQUEST_CODE_CAPTURE_PERM)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_CAPTURE_PERM) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                startRecording(data)
                return true
            } else {
                Log.e(TAG, "Permission denied for screen capture")
                return false
            }
        }
        return false
    }

    private fun startRecording(data: Intent) {
        try {
            mediaRecorder = MediaRecorder()
            mediaRecorder?.apply {
                // Use MediaProjection AudioPlaybackCapture (API 29+) internally
                // Note: Currently, MediaRecorder can't record internal audio directly.
                // Workaround: record mic only or use AudioRecord + MediaCodec for internal audio capture (complex)
                // Below is example for mic recording to MP3

                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                outputFilePath = getOutputFilePath()
                setOutputFile(outputFilePath)

                prepare()
                start()
            }
            isRecording = true
            Log.i(TAG, "Recording started at: $outputFilePath")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting recording", e)
        }
    }

    fun stopRecording() {
        try {
            mediaRecorder?.apply {
                stop()
                reset()
                release()
            }
            isRecording = false
            Log.i(TAG, "Recording stopped. File saved at $outputFilePath")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording", e)
        }
    }

    fun getOutputFilePath(): String {
        val dir = activity.getExternalFilesDir(Environment.DIRECTORY_MUSIC)
        val file = File(dir, "recorded_call_${System.currentTimeMillis()}.mp4")
        return file.absolutePath
    }
}
