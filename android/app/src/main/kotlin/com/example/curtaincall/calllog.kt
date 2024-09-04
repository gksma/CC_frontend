import android.content.Context
import android.database.Cursor
import android.provider.CallLog

class CallLogHelper(private val context: Context) {

    fun getCallLogs(): List<Map<String, String>> {
        val callLogs = mutableListOf<Map<String, String>>()
        val cursor: Cursor? = context.contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            null, null, null, CallLog.Calls.DATE + " DESC"
        )

        cursor?.use {
            val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
            val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
            val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
            val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)

            while (it.moveToNext()) {
                val callLog = mapOf(
                    "number" to it.getString(numberIndex),
                    "type" to it.getString(typeIndex),
                    "date" to it.getString(dateIndex),
                    "duration" to it.getString(durationIndex)
                )
                callLogs.add(callLog)
            }
        }
        return callLogs
    }
}
