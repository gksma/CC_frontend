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
import java.io.File
import java.io.FileOutputStream

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = DataBindingUtil.setContentView(this, R.layout.activity_main)

        // 저장된 전화번호가 있는지 확인
        val phoneNumber = getPhoneNumberFromFile()

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
                    Toast.makeText(this, "Retrieved phone number: $phoneNumber", Toast.LENGTH_LONG).show()
                    // 전화번호를 파일에 저장
                    savePhoneNumberToFile(phoneNumber)
                }
            } else {
                Toast.makeText(this, "TelephonyManager is not available", Toast.LENGTH_LONG).show()
            }
        } catch (e: Exception) {
            // 예외 처리
            Toast.makeText(this, "Failed to retrieve phone number: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    // 전화번호를 파일에 저장
    private fun savePhoneNumberToFile(phoneNumber: String) {
        try {
            val fileName = "phone_number.txt"
            val fileOutputStream: FileOutputStream = openFileOutput(fileName, Context.MODE_PRIVATE)
            fileOutputStream.write(phoneNumber.toByteArray())
            fileOutputStream.close()

            Toast.makeText(this, "Phone number saved to file", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Toast.makeText(this, "Failed to save phone number: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    // 파일에서 전화번호 가져오기
    private fun getPhoneNumberFromFile(): String? {
        return try {
            val fileName = "phone_number.txt"
            val file = File(filesDir, fileName)
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
