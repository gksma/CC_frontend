package com.example.curtaincall

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import com.example.curtaincall.R
import com.example.curtaincall.databinding.ActivityMainBinding
import io.flutter.embedding.android.FlutterActivity

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView<ActivityMainBinding?>(this, R.layout.activity_main).apply {
            lifecycleOwner = this@MainActivity
        }

        // FlutterActivity로 바로 전환
        launchFlutterActivity()
    }

    private fun launchFlutterActivity() {
        // FlutterActivity로 전환
        val intent = FlutterActivity.createDefaultIntent(this)
        startActivity(intent)
        finish() // 현재 Activity 종료
    }
}
