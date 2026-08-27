package com.fallhub.fallhub

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.temporal.ChronoUnit

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.fallhub.fallhub/health_connect"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NotificationChannels.register(this, flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHealthConnectSettings" -> {
                        result.success(openHealthConnectSettings())
                    }
                    "openSamsungHealth" -> {
                        result.success(openPackage("com.sec.android.app.shealth"))
                    }
                    "diagnoseSleep" -> {
                        val days = call.argument<Int>("days") ?: 730
                        diagnoseSleep(days, result)
                    }
                    "readSleepSessions" -> {
                        val days = call.argument<Int>("days") ?: 730
                        readSleepSessions(days, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun diagnoseSleep(days: Int, result: MethodChannel.Result) {
        scope.launch {
            try {
                val status = HealthConnectClient.getSdkStatus(this@MainActivity)
                if (status != HealthConnectClient.SDK_AVAILABLE) {
                    postSuccess(
                        result,
                        mapOf(
                            "sdkAvailable" to false,
                            "sdkStatus" to status,
                            "hasSleepReadPermission" to false,
                            "hasHistoryPermission" to false,
                            "effectiveDays" to 0,
                            "sleepCount" to 0,
                            "stepsCount" to 0,
                            "oldestStart" to null,
                            "newestEnd" to null,
                            "origins" to emptyList<String>(),
                            "message" to "Health Connect SDK indisponível (status=$status)",
                        ),
                    )
                    return@launch
                }

                val client = HealthConnectClient.getOrCreate(this@MainActivity)
                val granted = client.permissionController.getGrantedPermissions()
                val sleepRead =
                    HealthPermission.getReadPermission(SleepSessionRecord::class)
                val stepsRead =
                    HealthPermission.getReadPermission(StepsRecord::class)
                val hasSleep = granted.contains(sleepRead)
                val hasSteps = granted.contains(stepsRead)
                val hasHistory =
                    granted.contains(HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY)
                // Without history, HC only exposes ~30 days before first grant.
                val effectiveDays = if (hasHistory) days.coerceAtMost(730) else 30

                val end = Instant.now()
                val start = end.minus(effectiveDays.toLong(), ChronoUnit.DAYS)

                var sleepCount = 0
                var stepsCount = 0
                var oldestStart: Long? = null
                var newestEnd: Long? = null
                val origins = mutableSetOf<String>()
                val samples = mutableListOf<Map<String, Any?>>()

                if (hasSleep) {
                    val sleep = readAllSleepSessions(client, start, end)
                    sleepCount = sleep.size
                    for (rec in sleep) {
                        origins.add(rec.metadata.dataOrigin.packageName)
                        val s = rec.startTime.toEpochMilli()
                        val e = rec.endTime.toEpochMilli()
                        if (oldestStart == null || s < oldestStart!!) oldestStart = s
                        if (newestEnd == null || e > newestEnd!!) newestEnd = e
                        if (samples.size < 5) {
                            samples.add(
                                mapOf(
                                    "start" to s,
                                    "end" to e,
                                    "origin" to rec.metadata.dataOrigin.packageName,
                                    "stages" to rec.stages.size,
                                ),
                            )
                        }
                    }
                }

                if (hasSteps) {
                    stepsCount = readRecordCount(
                        client,
                        StepsRecord::class,
                        start,
                        end,
                    )
                }

                val message = when {
                    !hasSleep ->
                        "Colônia sem permissão de LEITURA de Sono no Health Connect."
                    !hasHistory && sleepCount > 0 ->
                        "Histórico HC NÃO concedido ao Colônia — só ~30 dias. " +
                            "Há $sleepCount sessão(ões) nessa janela. " +
                            "Ative “Acessar dados anteriores” para o app Colônia e sincronize de novo."
                    !hasHistory ->
                        "Sem permissão de histórico do Colônia (limite ~30 dias). " +
                            "Em Health Connect → App permissions → Colônia, ative “Acessar dados anteriores”."
                    sleepCount == 0 && stepsCount > 0 ->
                        "HC responde (passos=$stepsCount), mas 0 sono em $effectiveDays dias. " +
                            "O Samsung pode não ter enviado noites antigas ao HC — confira Browse data → Sleep."
                    sleepCount == 0 ->
                        "0 sessões de sono nos últimos $effectiveDays dias no Health Connect."
                    else ->
                        "OK: $sleepCount sessão(ões) em $effectiveDays dias. " +
                            "Histórico=${if (hasHistory) "sim" else "não"}. " +
                            "Origens: ${origins.joinToString()}"
                }

                postSuccess(
                    result,
                    mapOf(
                        "sdkAvailable" to true,
                        "sdkStatus" to status,
                        "hasSleepReadPermission" to hasSleep,
                        "hasStepsReadPermission" to hasSteps,
                        "hasHistoryPermission" to hasHistory,
                        "effectiveDays" to effectiveDays,
                        "sleepCount" to sleepCount,
                        "stepsCount" to stepsCount,
                        "oldestStart" to oldestStart,
                        "newestEnd" to newestEnd,
                        "origins" to origins.toList(),
                        "samples" to samples,
                        "message" to message,
                    ),
                )
            } catch (e: Exception) {
                Log.e("ColonyHC", "diagnoseSleep failed", e)
                postError(result, "diagnose_failed", e.message ?: e.toString())
            }
        }
    }

    private fun readSleepSessions(days: Int, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (HealthConnectClient.getSdkStatus(this@MainActivity)
                    != HealthConnectClient.SDK_AVAILABLE
                ) {
                    postSuccess(result, emptyList<Map<String, Any?>>())
                    return@launch
                }
                val client = HealthConnectClient.getOrCreate(this@MainActivity)
                val granted = client.permissionController.getGrantedPermissions()
                val sleepRead =
                    HealthPermission.getReadPermission(SleepSessionRecord::class)
                if (!granted.contains(sleepRead)) {
                    postSuccess(result, emptyList<Map<String, Any?>>())
                    return@launch
                }

                val hasHistory =
                    granted.contains(HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY)
                val effectiveDays = if (hasHistory) days.coerceAtMost(730) else 30

                val end = Instant.now()
                val start = end.minus(effectiveDays.toLong(), ChronoUnit.DAYS)
                val records = readAllSleepSessions(client, start, end)

                val payload = records.map { rec ->
                    mapOf(
                        "start" to rec.startTime.toEpochMilli(),
                        "end" to rec.endTime.toEpochMilli(),
                        "origin" to rec.metadata.dataOrigin.packageName,
                        "stages" to rec.stages.size,
                    )
                }
                Log.i(
                    "ColonyHC",
                    "readSleepSessions count=${payload.size} history=$hasHistory days=$effectiveDays",
                )
                postSuccess(result, payload)
            } catch (e: Exception) {
                Log.e("ColonyHC", "readSleepSessions failed", e)
                postError(result, "read_failed", e.message ?: e.toString())
            }
        }
    }

    /**
     * Reads sleep in 30-day chunks with pagination. Large single-range queries
     * can silently truncate; history permission is required beyond ~30 days.
     */
    private suspend fun readAllSleepSessions(
        client: HealthConnectClient,
        rangeStart: Instant,
        rangeEnd: Instant,
    ): List<SleepSessionRecord> {
        val all = LinkedHashMap<String, SleepSessionRecord>()
        var chunkEnd = rangeEnd
        while (chunkEnd.isAfter(rangeStart)) {
            var chunkStart = chunkEnd.minus(30, ChronoUnit.DAYS)
            if (chunkStart.isBefore(rangeStart)) chunkStart = rangeStart

            var request = ReadRecordsRequest(
                recordType = SleepSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(chunkStart, chunkEnd),
            )
            var response = client.readRecords(request)
            for (rec in response.records) {
                all[rec.metadata.id] = rec
            }
            var pageToken = response.pageToken
            while (!pageToken.isNullOrEmpty()) {
                request = ReadRecordsRequest(
                    recordType = SleepSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(chunkStart, chunkEnd),
                    pageToken = pageToken,
                )
                response = client.readRecords(request)
                for (rec in response.records) {
                    all[rec.metadata.id] = rec
                }
                pageToken = response.pageToken
            }

            if (!chunkStart.isAfter(rangeStart)) break
            chunkEnd = chunkStart
        }
        return all.values.sortedBy { it.startTime }
    }

    private suspend fun <T : androidx.health.connect.client.records.Record> readRecordCount(
        client: HealthConnectClient,
        type: kotlin.reflect.KClass<T>,
        start: Instant,
        end: Instant,
    ): Int {
        var count = 0
        var request = ReadRecordsRequest(
            recordType = type,
            timeRangeFilter = TimeRangeFilter.between(start, end),
        )
        var response = client.readRecords(request)
        count += response.records.size
        var pageToken = response.pageToken
        while (!pageToken.isNullOrEmpty()) {
            request = ReadRecordsRequest(
                recordType = type,
                timeRangeFilter = TimeRangeFilter.between(start, end),
                pageToken = pageToken,
            )
            response = client.readRecords(request)
            count += response.records.size
            pageToken = response.pageToken
        }
        return count
    }

    private fun postSuccess(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    private fun postError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        mainHandler.post { result.error(code, message, null) }
    }

    private fun openHealthConnectSettings(): Boolean {
        val intents = listOf(
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"),
            packageManager.getLaunchIntentForPackage("com.google.android.apps.healthdata"),
        )
        for (intent in intents) {
            if (intent == null) continue
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
            } catch (_: Exception) {
            }
        }
        try {
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=com.google.android.apps.healthdata"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            return true
        } catch (_: Exception) {
            return false
        }
    }

    private fun openPackage(packageName: String): Boolean {
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launch)
            return true
        }
        try {
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=$packageName"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            return true
        } catch (_: Exception) {
            return false
        }
    }
}
