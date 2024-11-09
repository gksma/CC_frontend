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
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 저장된 전화번호가 있는지 확인
        val phoneNumber = getPhoneNumberFromFile()

        if (phoneNumber != null) {
            // 저장된 전화번호가 있으면 FlutterActivity로 전환
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
            launchFlutterActivity()
        }
    }

    // 전화번호 가져오기
    private fun getPhoneNumber() {
        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null && ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                val phoneNumber = telephonyManager.line1Number
                if (phoneNumber.isNullOrEmpty()) {
                    Toast.makeText(this, "Unable to retrieve phone number", Toast.LENGTH_LONG).show()
                } else {
                    Toast.makeText(this, "Retrieved phone number: $phoneNumber", Toast.LENGTH_LONG).show()
                    // 전화번호를 파일에 저장
                    savePhoneNumberToFile(phoneNumber)
                }
            } else {
                Toast.makeText(this, "TelephonyManager is not available", Toast.LENGTH_LONG).show()
            }
        } catch (e: Exception) {
            Toast.makeText(this, "Failed to retrieve phone number: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    // 전화번호를 파일에 저장 (app_flutter 디렉토리 사용)
    private fun savePhoneNumberToFile(phoneNumber: String) {
        try {
            // Flutter의 app_flutter 디렉토리 경로 지정
            val directory = File(filesDir.parent, "app_flutter")
            if (!directory.exists()) {
                directory.mkdirs()
            }
            val file = File(directory, "phone_number.txt")
            file.writeText(phoneNumber)
            Toast.makeText(this, "Phone number saved to file in app_flutter", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Toast.makeText(this, "Failed to save phone number: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    // 파일에서 전화번호 가져오기
    private fun getPhoneNumberFromFile(): String? {
        return try {
            val directory = File(filesDir.parent, "app_flutter")
            val file = File(directory, "phone_number.txt")
            if (file.exists()) {
                file.readText()
            } else {
                null
            }
        } catch (e: Exception) {
            null // 파일이 없거나 읽기에 실패한 경우 null 반환
        }
    }

    // 권한 요청 결과 처리
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            getPhoneNumber()
            launchFlutterActivity()
        } else {
            Toast.makeText(this, "Permission Denied", Toast.LENGTH_LONG).show()
            launchFlutterActivity()
        }
    }

    // FlutterActivity로 전환
    private fun launchFlutterActivity() {
        val intent = FlutterActivity.createDefaultIntent(this)
        startActivity(intent)
        finish()
    }
}
