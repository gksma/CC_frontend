package com.example.curtaincall

import android.Manifest
import android.content.Context
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

        // 저장된 전화번호가 있는지 확인
        val phoneNumber = getPhoneNumberFromSharedPreferences()

        if (phoneNumber != null) {
            // 저장된 전화번호가 있으면 바로 FlutterActivity로 전환
            launchFlutterActivity()
        } else {
            // 전화번호가 없으면 권한을 확인하고 요청
            checkAndRequestPermissions()
        }
    }

    // 권한 확인 및 요청
    private fun checkAndRequestPermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_PHONE_STATE), 1)
        } else {
            // 권한이 이미 허가된 경우 전화번호 가져오기
            getPhoneNumber()
            // FlutterActivity로 전환
            launchFlutterActivity()
        }
    }

    // 전화번호 가져오기
    private fun getPhoneNumber() {
        try {
            val telephonyManager = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null && ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                val phoneNumber = telephonyManager.line1Number
                if (phoneNumber.isNullOrEmpty()) {
                    Toast.makeText(this, "Unable to retrieve phone number", Toast.LENGTH_LONG).show()
                } else {
                    // 전화번호를 SharedPreferences에 저장
                    savePhoneNumberToSharedPreferences(phoneNumber)
                }
            } else {
                Toast.makeText(this, "TelephonyManager is not available", Toast.LENGTH_LONG).show()
            }
        } catch (e: Exception) {
            // 예외 처리
            Toast.makeText(this, "Failed to retrieve phone number: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    // SharedPreferences에 전화번호 저장
    private fun savePhoneNumberToSharedPreferences(phoneNumber: String) {
        val sharedPref = getSharedPreferences("MyAppPrefs", Context.MODE_PRIVATE)
        with(sharedPref.edit()) {
            putString("phone_number", phoneNumber)
            apply() // 저장
        }
        Toast.makeText(this, "Phone number saved to local storage", Toast.LENGTH_LONG).show()
    }

    // SharedPreferences에서 전화번호 가져오기
    private fun getPhoneNumberFromSharedPreferences(): String? {
        val sharedPref = getSharedPreferences("MyAppPrefs", Context.MODE_PRIVATE)
        return sharedPref.getString("phone_number", null)
    }

    // 권한 요청 결과 처리
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            // 권한이 허가된 경우 전화번호를 가져오고 FlutterActivity로 전환
            getPhoneNumber()
            launchFlutterActivity()
        } else {
            Toast.makeText(this, "Permission Denied", Toast.LENGTH_LONG).show()
            // 권한이 없을 경우에도 FlutterActivity로 전환
            launchFlutterActivity()
        }
    }

    // FlutterActivity로 전환
    private fun launchFlutterActivity() {
        val intent = FlutterActivity.createDefaultIntent(this)
        startActivity(intent)
        finish() // 현재 Activity 종료
    }
}
