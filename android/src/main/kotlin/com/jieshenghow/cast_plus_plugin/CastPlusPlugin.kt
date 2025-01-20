package com.jieshenghow.cast_plus_plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

// Google Cast imports
import android.app.Activity
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastButtonFactory

class CastPlusPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel : MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "cast_plus_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                initializeCast()
                result.success(null)
            }
            "showCastPicker" -> {
                showCastPickerInternal()
                result.success(null)
            }
            "castUrl" -> {
                val url = call.argument<String>("url") ?: ""
                castUrlInternal(url)
                result.success(null)
            }
            "stopCasting" -> {
                stopCastingInternal()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun initializeCast() {
        activity?.let {
            // Initialize the CastContext
            CastContext.getSharedInstance(it.applicationContext)
        }
    }

    private fun showCastPickerInternal() {
        // On Android, there's no direct "showCastPicker()" method by default.
        // Typically you have a Cast button in your toolbar that triggers a route chooser dialog.
        // If you want to handle it programmatically, you'd need to embed the button in your layout or do custom route logic.
        // This method is basically a placeholder.
        activity?.let {
            // Example: If you have a MediaRouteButton, you'd do something like:
            // CastButtonFactory.setUpMediaRouteButton(it, mediaRouteButton)
            // Then let the user tap it.
        }
    }

    private fun castUrlInternal(url: String) {
        val castContext = CastContext.getSharedInstance()
        val session = castContext.sessionManager.currentCastSession
        val remoteMediaClient = session?.remoteMediaClient ?: return

        val media = com.google.android.gms.cast.MediaInfo.Builder(url)
            .setStreamType(com.google.android.gms.cast.MediaInfo.STREAM_TYPE_BUFFERED)
            .setContentType("video/mp4") // or "application/x-mpegURL" for HLS
            .build()

        val mediaLoadRequestData = com.google.android.gms.cast.MediaLoadRequestData.Builder()
            .setMediaInfo(media)
            .build()

        remoteMediaClient.load(mediaLoadRequestData)
    }

    private fun stopCastingInternal() {
        val castContext = CastContext.getSharedInstance()
        castContext.sessionManager.endCurrentSession(true)
    }
}