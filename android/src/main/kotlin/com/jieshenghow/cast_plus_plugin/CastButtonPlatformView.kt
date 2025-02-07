package com.jieshenghow.cast_plus_plugin

import android.content.Context
import android.view.ContextThemeWrapper
import android.widget.FrameLayout
import androidx.mediarouter.app.MediaRouteButton
import com.google.android.gms.cast.framework.CastButtonFactory
import io.flutter.plugin.platform.PlatformView

class CastButtonPlatformView(context: Context) : PlatformView {
    private val container: FrameLayout = FrameLayout(context)
    private val mediaRouteButton: MediaRouteButton

    init {
        // 1) Wrap the original context with our custom non-translucent theme
        val themedContext = ContextThemeWrapper(context, R.style.MyNonTranslucentTheme)

        // 2) Create the MediaRouteButton with that guaranteed non-translucent context
        mediaRouteButton = MediaRouteButton(themedContext)

        // 3) Add it to the container
        container.addView(mediaRouteButton)

        // 4) Link the button with Cast
        CastButtonFactory.setUpMediaRouteButton(themedContext, mediaRouteButton)
    }

    override fun getView() = container
    override fun dispose() {}
}