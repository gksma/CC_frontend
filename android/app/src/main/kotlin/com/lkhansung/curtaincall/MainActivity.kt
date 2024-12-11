package com.lkhansung.curtaincall

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchFlutterActivity()
    }

    private fun launchFlutterActivity() {
        val intent = FlutterActivity.createDefaultIntent(this)
        startActivity(intent)
        finish()
    }
}
