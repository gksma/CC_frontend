package com.example.curtaincall

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.telephony.TelephonyManager
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import com.example.curtaincall.R
import com.example.curtaincall.databinding.ActivityMainBinding
import io.flutter.embedding.android.FlutterActivity

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = DataBindingUtil.setContentView(this, R.layout.activity_main)

        // 권한을 확인하고 요청
        checkAndRequestPermissions()
    }

    private fun checkAndRequestPermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_PHONE_STATE), 1)
        } else {
            // 권한이 이미 허가된 경우
            getPhoneNumber()
            // FlutterActivity로 바로 전환
            launchFlutterActivity()
        }
    }

    private fun getPhoneNumber() {
        try {
            val telephonyManager = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null && ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                val phoneNumber = telephonyManager.line1Number
                if (phoneNumber.isNullOrEmpty()) {
                    Toast.makeText(this, "Unable to retrieve phone number", Toast.LENGTH_LONG).show()
                } else {
                    Toast.makeText(this, "Phone Number: $phoneNumber", Toast.LENGTH_LONG).show()
                    // 여기서 전화번호를 저장하거나 처리할 수 있습니다.
                }
            } else {
                Toast.makeText(this, "TelephonyManager is not available", Toast.LENGTH_LONG).show()
            }
        } catch (e: Exception) {
            // 예외 처리
            Toast.makeText(this, "Failed to retrieve phone number: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            // 권한이 허가된 경우 전화번호를 가져오고 FlutterActivity로 전환
            getPhoneNumber()
            launchFlutterActivity()
        } else {
            Toast.makeText(this, "Permission Denied", Toast.LENGTH_LONG).show()
            // 권한이 없으므로 FlutterActivity로만 전환
            launchFlutterActivity()
        }
    }

    private fun launchFlutterActivity() {
        // FlutterActivity로 전환
        val intent = FlutterActivity.createDefaultIntent(this)
        startActivity(intent)
        finish() // 현재 Activity 종료
    }
}
