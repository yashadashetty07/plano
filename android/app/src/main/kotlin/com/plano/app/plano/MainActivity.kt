package com.plano.app.plano

import android.content.Intent
import android.os.Build
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZoneId

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.plano.app/health_connect"
    private var healthConnectClient: HealthConnectClient? = null

    private val PERMISSIONS = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class)
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> {
                    val status = HealthConnectClient.getSdkStatus(this)
                    when (status) {
                        HealthConnectClient.SDK_AVAILABLE -> result.success("AVAILABLE")
                        HealthConnectClient.SDK_UNAVAILABLE -> result.success("NOT_SUPPORTED")
                        HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> result.success("NOT_INSTALLED")
                        else -> result.success("NOT_SUPPORTED")
                    }
                }
                "getGrantedPermissions" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            if (!isClientAvailable()) {
                                withContext(Dispatchers.Main) { result.success(emptyList<String>()) }
                                return@launch
                            }
                            val granted = healthConnectClient!!.permissionController.getGrantedPermissions()
                            val list = granted.map { it.toString() }
                            withContext(Dispatchers.Main) { result.success(list) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.error("HEALTH_ERROR", e.localizedMessage, null) }
                        }
                    }
                }
                "openSettings" -> {
                    try {
                        val intent = Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                "getDailySummaries" -> {
                    val startEpoch = call.argument<Long>("startEpochMs") ?: 0L
                    val endEpoch = call.argument<Long>("endEpochMs") ?: System.currentTimeMillis()

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            if (!isClientAvailable()) {
                                withContext(Dispatchers.Main) { result.success(emptyMap<String, Any>()) }
                                return@launch
                            }

                            val startTime = Instant.ofEpochMilli(startEpoch)
                            val endTime = Instant.ofEpochMilli(endEpoch)
                            val timeRange = TimeRangeFilter.between(startTime, endTime)

                            // Read aggregate steps
                            val stepsAggregate = healthConnectClient!!.aggregate(
                                AggregateRequest(
                                    metrics = setOf(StepsRecord.COUNT_TOTAL),
                                    timeRangeFilter = timeRange
                                )
                            )
                            val totalSteps = stepsAggregate[StepsRecord.COUNT_TOTAL] ?: 0L

                            // Read exercise sessions count and total minutes
                            val exerciseAggregate = healthConnectClient!!.aggregate(
                                AggregateRequest(
                                    metrics = setOf(ExerciseSessionRecord.EXERCISE_DURATION_TOTAL),
                                    timeRangeFilter = timeRange
                                )
                            )
                            val exerciseDurationSeconds = exerciseAggregate[ExerciseSessionRecord.EXERCISE_DURATION_TOTAL]?.seconds ?: 0L
                            val exerciseMinutes = (exerciseDurationSeconds / 60).toInt()

                            val resultMap = mapOf(
                                "steps" to totalSteps,
                                "workoutMinutes" to exerciseMinutes,
                                "source" to "Health Connect"
                            )
                            withContext(Dispatchers.Main) { result.success(resultMap) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.error("QUERY_ERROR", e.localizedMessage, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isClientAvailable(): Boolean {
        if (HealthConnectClient.getSdkStatus(this) != HealthConnectClient.SDK_AVAILABLE) {
            return false
        }
        if (healthConnectClient == null) {
            healthConnectClient = HealthConnectClient.getOrCreate(this)
        }
        return healthConnectClient != null
    }
}
