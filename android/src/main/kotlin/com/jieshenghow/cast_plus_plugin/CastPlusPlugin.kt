package com.jieshenghow.cast_plus_plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.app.Activity
import android.content.Context
import android.util.Log

// Google Cast imports
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData

class CastPlusPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "cast_plus_plugin")
        channel.setMethodCallHandler(this)

        binding
            .platformViewRegistry
            .registerViewFactory("cast_button_platform_view", CastButtonPlatformViewFactory())
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

    //region ActivityAware
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
    //endregion

    private fun initializeCast() {
        activity?.let {
            try {
                CastContext.getSharedInstance(it.applicationContext)
            } catch (e: Exception) {
                Log.e("CastPlusPlugin", "Error initializing CastContext", e)
            }
        }
    }

    private fun showCastPickerInternal() {
        // Typically you place a Cast button in your activity layout,
        // then the user taps it to see the device picker.
        activity?.let { showCustomRoutePicker(it) }
    }

    private fun castUrlInternal(url: String) {
        // Ensure we have a valid CastContext
        val castContext = CastContext.getSharedInstance() ?: run {
            Log.w("CastPlusPlugin", "CastContext is null. Can't cast URL.")
            return
        }

        val session = castContext.sessionManager.currentCastSession
        val remoteMediaClient = session?.remoteMediaClient
        if (remoteMediaClient == null) {
            Log.w("CastPlusPlugin", "No active cast session or remoteMediaClient is null.")
            return
        }

        // Build the media info
        val media = MediaInfo.Builder(url)
            .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
            .setContentType("video/mp4") // or "application/x-mpegURL" for HLS
            .build()

        val mediaLoadRequestData = MediaLoadRequestData.Builder()
            .setMediaInfo(media)
            .build()

        remoteMediaClient.load(mediaLoadRequestData)
    }

    private fun stopCastingInternal() {
        val castContext = CastContext.getSharedInstance() ?: run {
            Log.w("CastPlusPlugin", "CastContext is null. Can't stop casting.")
            return
        }
        castContext.sessionManager.endCurrentSession(true)
    }

    private fun showCustomRoutePicker(context: Context) {
        val mediaRouter = androidx.mediarouter.media.MediaRouter.getInstance(context)

        // Build a route selector that matches your receiver app ID (e.g., default media receiver)
        val castContext = com.google.android.gms.cast.framework.CastContext.getSharedInstance() ?: return
        val selector = androidx.mediarouter.media.MediaRouteSelector.Builder()
            .addControlCategory(
                com.google.android.gms.cast.CastMediaControlIntent.categoryForCast(
                    castContext.castOptions.receiverApplicationId
                )
            )
            .build()

        // Add a callback that listens for route discovery
        // (You might do this in 'initializeCast()' or on plugin startup instead of here)
        mediaRouter.addCallback(selector, object : androidx.mediarouter.media.MediaRouter.Callback() {
            override fun onRouteAdded(
                router: androidx.mediarouter.media.MediaRouter,
                route: androidx.mediarouter.media.MediaRouter.RouteInfo
            ) {
                // route discovered
            }

            override fun onRouteRemoved(
                router: androidx.mediarouter.media.MediaRouter,
                route: androidx.mediarouter.media.MediaRouter.RouteInfo
            ) {
                // route removed
            }
        }, androidx.mediarouter.media.MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY)

        // Collect current routes
        val allRoutes = mediaRouter.routes
        val castRoutes = allRoutes.filter { route ->
            // Exclude phone route, etc.
            // Check route.supportsControlCategory(...) if you want more fine-grained filtering
            route.connectionState == 0 || route.connectionState == 2
        }

        if (castRoutes.isEmpty()) {
            // Show some "No devices found" toast or dialog
            return
        }

        // Build a simple AlertDialog with the route names
        val routeNames = castRoutes.map { it.name }.toTypedArray()

        android.app.AlertDialog.Builder(context)
            .setTitle("Select a Cast Device")
            .setItems(routeNames) { _, which ->
                val chosen = castRoutes[which]
                // Select the route
                mediaRouter.selectRoute(chosen)
            }
            .show()
    }
}