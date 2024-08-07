package com.example.curtaincall

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telecom.TelecomManager
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private val REQUEST_CODE_SET_DEFAULT_DIALER = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 기본 전화 앱으로 설정할 앱의 패키지 이름을 여기에 넣습니다
        val packageName = "com.example.curtaincall"  // 설정할 전화 앱의 패키지 이름

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!isDefaultDialer(packageName)) {
                val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
                startActivityForResult(intent, REQUEST_CODE_SET_DEFAULT_DIALER)
            } else {
                Toast.makeText(this, "이미 기본 전화 앱으로 설정되어 있습니다.", Toast.LENGTH_SHORT).show()
            }
        } else {
            Toast.makeText(this, "이 기능은 안드로이드 6.0 이상에서 지원됩니다.", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_SET_DEFAULT_DIALER) {
            if (resultCode == RESULT_OK) {
                Toast.makeText(this, "기본 전화 앱이 설정되었습니다.", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "기본 전화 앱으로 설정이 되어있지 않습니다. 기본 전화 앱으로 설정해주세요.", Toast.LENGTH_SHORT).show()
                openDefaultAppsSettings()
            }
        }
    }

    private fun isDefaultDialer(packageName: String): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            packageName == telecomManager.defaultDialerPackage
        } else {
            false
        }
    }

    private fun openDefaultAppsSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
            startActivity(intent)
        } else {
            val intent = Intent(Settings.ACTION_SETTINGS)
            startActivity(intent)
        }
    }
}
