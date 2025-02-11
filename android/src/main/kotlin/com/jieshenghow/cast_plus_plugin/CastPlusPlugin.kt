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
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData

class CastPlusPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var castContext: CastContext? = null
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "cast_plus_plugin")
        channel.setMethodCallHandler(this)
        castContext = CastContext.getSharedInstance(binding.applicationContext)

        binding.platformViewRegistry.registerViewFactory(
            "cast_button_platform_view",
            CastButtonPlatformViewFactory()
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        castContext = null
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

            "getAvailableCastDevices" -> {
                val devices = getAvailableCastDevice()
                result.success(devices)
            }

            "castToDevice" -> {
                val deviceId = call.argument<String>("deviceId")
                val url = call.argument<String>("url")
                val videoTitle = call.argument<String>("videoTitle")
                if (deviceId != null && url != null && videoTitle != null) {
                    castToDevice(deviceId, url, videoTitle, result)
                } else {
                    result.error("INVALID_ARGUMENT", "deviceId and url are required", null)
                }
            }

            "stopDeviceCasting" -> {
                stopDeviceCasting()
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    //region ActivityAware implementations
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
        activity?.let { showCustomRoutePicker(it) }
    }

    private fun castUrlInternal(url: String) {
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
        val media = MediaInfo.Builder(url)
            .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
            .setContentType("video/mp4")
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
        val castContext = CastContext.getSharedInstance() ?: return
        val selector = androidx.mediarouter.media.MediaRouteSelector.Builder()
            .addControlCategory(
                com.google.android.gms.cast.CastMediaControlIntent.categoryForCast(
                    castContext.castOptions.receiverApplicationId
                )
            )
            .build()
        mediaRouter.addCallback(
            selector,
            object : androidx.mediarouter.media.MediaRouter.Callback() {
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
            },
            androidx.mediarouter.media.MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY
        )
        val allRoutes = mediaRouter.routes
        val castRoutes = allRoutes.filter { route ->
            // Filtering routes based on connection state; adjust as needed.
            route.connectionState == 0 || route.connectionState == 2
        }
        if (castRoutes.isEmpty()) {
            // Optionally, show a toast or dialog indicating no devices were found.
            return
        }
        val routeNames = castRoutes.map { it.name }.toTypedArray()
        android.app.AlertDialog.Builder(context)
            .setTitle("Select a Cast Device")
            .setItems(routeNames) { _, which ->
                val chosen = castRoutes[which]
                mediaRouter.selectRoute(chosen)
            }
            .show()
    }

    private fun getAvailableCastDevice(): List<Map<String, String>> {
        val context = activity ?: applicationContext
        val mediaRouter = androidx.mediarouter.media.MediaRouter.getInstance(context)
        val receiverAppId = castContext?.castOptions?.receiverApplicationId
            ?: com.google.android.gms.cast.CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
        val selector = androidx.mediarouter.media.MediaRouteSelector.Builder()
            .addControlCategory(
                com.google.android.gms.cast.CastMediaControlIntent.categoryForCast(receiverAppId)
            )
            .build()
        val routes = mediaRouter.routes.filter { routeInfo -> routeInfo.matchesSelector(selector) }
        return routes.map { routeInfo ->
            // Note: Using hashCode() as an ID is not ideal but is kept here to revert to your original behavior.
            mapOf(
                "deviceId" to routeInfo.hashCode().toString(),
                "deviceName" to routeInfo.name,
                "deviceUniqueId" to routeInfo.id
            )
        }
    }

    private fun stopDeviceCasting() {
        castContext?.sessionManager?.endCurrentSession(true)
    }

    // Revised castToDevice method using a SessionManagerListener
    private fun castToDevice(
        deviceId: String,
        url: String,
        videoTitle: String,
        result: MethodChannel.Result
    ) {
        val context = activity ?: applicationContext
        val mediaRouter = androidx.mediarouter.media.MediaRouter.getInstance(context)
        val receiverAppId = castContext?.castOptions?.receiverApplicationId
            ?: com.google.android.gms.cast.CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
        val selector = androidx.mediarouter.media.MediaRouteSelector.Builder()
            .addControlCategory(
                com.google.android.gms.cast.CastMediaControlIntent.categoryForCast(receiverAppId)
            )
            .build()
        val routes = mediaRouter.routes.filter { routeInfo -> routeInfo.matchesSelector(selector) }
        // Use the same method of ID generation as in getAvailableCastDevice()
        val selectedRoute = routes.firstOrNull { routeInfo ->
            routeInfo.hashCode().toString() == deviceId
        }

        if (selectedRoute != null) {
            mediaRouter.selectRoute(selectedRoute)
            val sessionManager = castContext?.sessionManager
            if (sessionManager == null) {
                result.error("CAST_ERROR", "CastContext session manager is null", null)
                return
            }
            sessionManager.addSessionManagerListener(object : SessionManagerListener<CastSession> {
                override fun onSessionStarted(session: CastSession, sessionId: String) {
                    loadMedia(session, url,videoTitle ,result)
                    sessionManager.removeSessionManagerListener(this, CastSession::class.java)
                }

                override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
                    loadMedia(session, url,videoTitle, result)
                    sessionManager.removeSessionManagerListener(this, CastSession::class.java)
                }

                override fun onSessionStarting(session: CastSession) {}
                override fun onSessionStartFailed(session: CastSession, error: Int) {
                    result.error("CAST_ERROR", "Unable to start session", null)
                    sessionManager.removeSessionManagerListener(this, CastSession::class.java)
                }

                override fun onSessionEnding(session: CastSession) {}
                override fun onSessionEnded(session: CastSession, error: Int) {}
                override fun onSessionResuming(session: CastSession, sessionId: String) {}
                override fun onSessionResumeFailed(session: CastSession, error: Int) {
                    result.error("CAST_ERROR", "Unable to resume session", null)
                    sessionManager.removeSessionManagerListener(this, CastSession::class.java)
                }

                override fun onSessionSuspended(p0: CastSession, p1: Int) {
                    TODO("Not yet implemented")
                }
            }, CastSession::class.java)
        } else {
            result.error("DEVICE_NOT_FOUND", "No device found with the given id", null)
        }
    }

    private fun loadMedia(
        session: CastSession,
        url: String,
        videoTitle: String,
        result: MethodChannel.Result
    ) {
        val remoteMediaClient = session.remoteMediaClient
        if (remoteMediaClient == null) {
            result.error("CAST_ERROR", "Remote media client is null", null)
            return
        }
        val metadata =
            com.google.android.gms.cast.MediaMetadata(com.google.android.gms.cast.MediaMetadata.MEDIA_TYPE_MOVIE)
        metadata.putString(com.google.android.gms.cast.MediaMetadata.KEY_TITLE, videoTitle)
        val mediaInfo = MediaInfo.Builder(url)
            .setContentType("video/mp4")
            .setMetadata(metadata)
            .build()
        val requestData = MediaLoadRequestData.Builder()
            .setMediaInfo(mediaInfo)
            .build()
        remoteMediaClient.load(requestData)
        result.success(null)
    }

    private fun showCastPicker() {
        activity?.runOnUiThread {
            try {
                // Custom implementation to show a cast picker if needed.
            } catch (e: Exception) {
                Log.e("CastPlusPlugin", "Error showing cast picker", e)
            }
        }
    }
}