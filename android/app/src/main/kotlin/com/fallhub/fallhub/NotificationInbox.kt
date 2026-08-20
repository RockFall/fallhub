package com.fallhub.fallhub

import android.content.Context
import org.json.JSONObject
import java.io.File

internal object NotificationInbox {
    private const val FILE_NAME = "colony_notification_inbox.jsonl"
    private val lock = Any()

    fun append(context: Context, payload: Map<String, Any?>) {
        synchronized(lock) {
            val json = JSONObject()
            for ((key, value) in payload) {
                json.put(key, value ?: JSONObject.NULL)
            }
            val file = file(context)
            file.appendText(json.toString() + "\n")
            trimIfNeeded(file)
        }
    }

    fun drain(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val file = file(context)
            if (!file.exists()) return emptyList()
            val lines = file.readLines().filter { it.isNotBlank() }
            file.writeText("")
            return lines.mapNotNull { parseLine(it) }
        }
    }

    private fun file(context: Context): File = File(context.filesDir, FILE_NAME)

    private fun parseLine(line: String): Map<String, Any?>? {
        return try {
            val json = JSONObject(line)
            val map = HashMap<String, Any?>()
            val keys = json.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                map[key] = if (json.isNull(key)) null else json.get(key)
            }
            map
        } catch (_: Exception) {
            null
        }
    }

    private fun trimIfNeeded(file: File) {
        val lines = file.readLines()
        if (lines.size <= 800) return
        file.writeText(lines.takeLast(500).joinToString("\n") + "\n")
    }
}
