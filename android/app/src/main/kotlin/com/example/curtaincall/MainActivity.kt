package com.example.curtaincall

import android.app.role.RoleManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telecom.TelecomManager
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import com.example.curtaincall.R
import com.example.curtaincall.databinding.ActivityMainBinding
import io.flutter.embedding.android.FlutterActivity

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    //RoleManager 방식은 api 29 부터 사용할 수 있음
    private val roleManager: RoleManager? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            getSystemService(ROLE_SERVICE) as RoleManager
        } else null
    }
    private val telecomManager: TelecomManager by lazy { getSystemService(TELECOM_SERVICE) as TelecomManager }

    private val isDefaultDialer get() = packageName.equals(telecomManager.defaultDialerPackage)

    private val changeDefaultDialerIntent
        get() = if (isDefaultDialer) {
            Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                roleManager!!.createRequestRoleIntent(RoleManager.ROLE_DIALER)
            } else {
                Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                    putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
                }
            }
        }

    private val changeDefaultDialerLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
            binding.isDefaultDialer = isDefaultDialer
            if (isDefaultDialer) {
                // 기본 전화 앱 설정이 완료되었으면 FlutterActivity로 전환
                launchFlutterActivity()
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = DataBindingUtil.setContentView<ActivityMainBinding?>(this, R.layout.activity_main).apply {
            lifecycleOwner = this@MainActivity
            isDefaultDialer = this@MainActivity.isDefaultDialer
        }

        if (isDefaultDialer) {
            // 이미 기본 전화 앱인 경우 FlutterActivity로 바로 전환
            launchFlutterActivity()
        } else {
            binding.changeDefaultDialer.setOnClickListener {
                changeDefaultDialerLauncher.launch(changeDefaultDialerIntent)
            }
        }
    }

    private fun launchFlutterActivity() {
        // FlutterActivity로 전환
        val intent = FlutterActivity.createDefaultIntent(this)
        startActivity(intent)
        finish() // 현재 Activity 종료
    }
}
