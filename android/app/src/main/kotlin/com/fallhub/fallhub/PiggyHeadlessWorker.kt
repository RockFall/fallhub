package com.fallhub.fallhub

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Boots a headless Flutter isolate so a bank notification can be booked by
 * the existing Dart extractor and the home widget can refresh with the app closed.
 */
class PiggyHeadlessWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {
    override fun doWork(): Result {
        val drained = NotificationInbox.drain(applicationContext)
        val outcome = AtomicReference(Result.retry())
        val latch = CountDownLatch(1)
        val engineRef = AtomicReference<FlutterEngine?>(null)
        Handler(Looper.getMainLooper()).post {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(applicationContext)
                loader.ensureInitializationComplete(applicationContext, null)
                val engine = FlutterEngine(applicationContext)
                engineRef.set(engine)
                GeneratedPluginRegistrant.registerWith(engine)
                val channel = MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    "colony/piggy_headless",
                )
                channel.setMethodCallHandler { call, result ->
                    if (call.method == "ready") {
                        result.success(null)
                        channel.invokeMethod(
                            "run",
                            mapOf("payloads" to drained),
                            object : MethodChannel.Result {
                                override fun success(value: Any?) {
                                    applyNativeSideEffects(value)
                                    outcome.set(Result.success())
                                    finish(engine, latch)
                                }

                                override fun error(code: String, message: String?, details: Any?) {
                                    NotificationInbox.appendAll(applicationContext, drained)
                                    outcome.set(Result.retry())
                                    finish(engine, latch)
                                }

                                override fun notImplemented() {
                                    NotificationInbox.appendAll(applicationContext, drained)
                                    outcome.set(Result.failure())
                                    finish(engine, latch)
                                }
                            },
                        )
                    } else {
                        result.notImplemented()
                    }
                }
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        loader.findAppBundlePath(),
                        "package:fallhub/piggy_headless.dart",
                        "piggyBankHeadless",
                    ),
                )
            } catch (_: Exception) {
                NotificationInbox.appendAll(applicationContext, drained)
                outcome.set(Result.retry())
                latch.countDown()
            }
        }
        val finished = latch.await(45, TimeUnit.SECONDS)
        if (!finished) {
            NotificationInbox.appendAll(applicationContext, drained)
            engineRef.get()?.destroy()
            return Result.retry()
        }
        return outcome.get()
    }

    private fun applyNativeSideEffects(value: Any?) {
        val map = value as? Map<*, *> ?: return
        if (map["alert"] == true) {
            val message = map["message"]?.toString().orEmpty()
            if (message.isNotBlank()) {
                PiggyAlerts.showRed(applicationContext, message)
            }
        }
        PiggyMidnight.schedule(applicationContext)
        val manager = AppWidgetManager.getInstance(applicationContext)
        val component = ComponentName(applicationContext, PiggyBankWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        for (id in ids) {
            PiggyBankWidgetProvider.render(applicationContext, manager, id)
        }
    }

    private fun finish(engine: FlutterEngine, latch: CountDownLatch) {
        engine.destroy()
        latch.countDown()
    }
}
