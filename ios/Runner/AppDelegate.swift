import CryptoKit
import Flutter
import UIKit
import UserNotifications
#if canImport(AlarmKit)
import ActivityKit
import AlarmKit
import SwiftUI
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nativeBridge: NativeBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications present reminders while the app is open.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    nativeBridge = NativeBridge(messenger: engineBridge.applicationRegistrar.messenger())
  }
}

/// iOS side of contracts/native-bridge-v1.md. UNTESTED: written without
/// Xcode; build and verify on a Mac. Expected states return typed values;
/// nothing here logs schedule titles, details or deep links.
final class NativeBridge {
  static let channelName = "com.manalogadiel.schediel/native"
  private static let storeKey = "schediel.alarmRequestKeys"

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: NativeBridge.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.handle(call, result)
    }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "getCapabilities":
      result(capabilities())
    case "requestAppAlarmAuthorization":
      requestAlarmAuthorization(result)
    case "openSystemSettings":
      let target = (call.arguments as? [String: Any])?["target"] as? String
      openSettings(target: target, result)
    case "scheduleAlarms":
      let raw = (call.arguments as? [String: Any])?["alarms"] as? [[String: Any]] ?? []
      scheduleAlarms(raw, result)
    case "cancelAllAlarms":
      result(cancelAllAlarms())
    case "stopAlarm":
      let key = (call.arguments as? [String: Any])?["requestKey"] as? String ?? ""
      result(stopAlarm(requestKey: key))
    case "getScheduledAlarms":
      result(Array(storedKeys().values))
    case "launchClockAlarm":
      // The Clock hand-off exists only on Android.
      result("unavailable")
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: Capabilities

  private func capabilities() -> [String: Any] {
    [
      "platform": "ios",
      "osVersion": UIDevice.current.systemVersion,
      "apiLevel": NSNull(),
      "exactAlarms": "unavailable",
      "appAlarms": alarmStatus(),
      "fullScreen": "unavailable",
      "externalClock": false,
    ]
  }

  private func alarmStatus() -> String {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      switch AlarmManager.shared.authorizationState {
      case .authorized: return "authorized"
      case .denied: return "denied"
      case .notDetermined: return "notDetermined"
      @unknown default: return "unavailable"
      }
    }
    #endif
    return "unavailable"
  }

  private func requestAlarmAuthorization(_ result: @escaping FlutterResult) {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      Task {
        _ = try? await AlarmManager.shared.requestAuthorization()
        let status = self.alarmStatus()
        await MainActor.run { result(status) }
      }
      return
    }
    #endif
    result(alarmStatus())
  }

  private func openSettings(target: String?, _ result: @escaping FlutterResult) {
    let text: String
    if target == "notifications", #available(iOS 16.0, *) {
      text = UIApplication.openNotificationSettingsURLString
    } else {
      text = UIApplication.openSettingsURLString
    }
    guard let url = URL(string: text) else {
      result(false)
      return
    }
    UIApplication.shared.open(url) { opened in result(opened) }
  }

  // MARK: App-owned alarms (AlarmKit, iOS 26+)

  /// Request key -> stable AlarmKit identifier.
  private func alarmID(for requestKey: String) -> UUID {
    var bytes = Array(SHA256.hash(data: Data(requestKey.utf8)).prefix(16))
    bytes[6] = (bytes[6] & 0x0F) | 0x50
    bytes[8] = (bytes[8] & 0x3F) | 0x80
    return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                       bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
  }

  /// UUID string -> request key for alarms this app scheduled.
  private func storedKeys() -> [String: String] {
    UserDefaults.standard.dictionary(forKey: NativeBridge.storeKey) as? [String: String] ?? [:]
  }

  private func saveKeys(_ keys: [String: String]) {
    UserDefaults.standard.set(keys, forKey: NativeBridge.storeKey)
  }

  /// Stops a ringing alarm or cancels it before it rings; schedule data is untouched.
  private func stopAlarm(requestKey: String) -> Bool {
    var held = storedKeys()
    guard let entry = held.first(where: { $0.value == requestKey }), let id = UUID(uuidString: entry.key) else {
      return false
    }
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      try? AlarmManager.shared.stop(id: id)
      try? AlarmManager.shared.cancel(id: id)
    }
    #endif
    held.removeValue(forKey: entry.key)
    saveKeys(held)
    return true
  }

  private func cancelAllAlarms() -> Int {
    let held = storedKeys()
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      for id in held.keys.compactMap(UUID.init(uuidString:)) {
        try? AlarmManager.shared.cancel(id: id)
      }
    }
    #endif
    saveKeys([:])
    return held.count
  }

  private func scheduleAlarms(_ raw: [[String: Any]], _ result: @escaping FlutterResult) {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      Task {
        let results = await self.replaceAll(raw)
        await MainActor.run { result(results) }
      }
      return
    }
    #endif
    // Below iOS 26 the Dart side keeps notification reminders.
    result(raw.map { ["requestKey": $0["requestKey"] as? String ?? "", "status": "failed", "errorCode": "unavailable"] })
  }

  #if canImport(AlarmKit)
  @available(iOS 26.0, *)
  struct ScheduleAlarmMetadata: AlarmMetadata {}

  /// Replace-all: afterwards AlarmKit holds exactly the accepted requests.
  @available(iOS 26.0, *)
  private func replaceAll(_ raw: [[String: Any]]) async -> [[String: Any]] {
    let manager = AlarmManager.shared
    _ = cancelAllAlarms()
    var kept: [String: String] = [:]
    var results: [[String: Any]] = []
    let now = Date()
    for request in raw {
      let key = request["requestKey"] as? String ?? ""
      guard !key.isEmpty, key.count <= 160,
            let triggerMs = (request["triggerAtEpochMs"] as? NSNumber)?.doubleValue
      else {
        results.append(["requestKey": key, "status": "failed", "errorCode": "invalidRequest"])
        continue
      }
      let trigger = Date(timeIntervalSince1970: triggerMs / 1000)
      if trigger <= now {
        results.append(["requestKey": key, "status": "pastTrigger", "errorCode": NSNull()])
        continue
      }
      if manager.authorizationState != .authorized {
        results.append(["requestKey": key, "status": "needsPermission", "errorCode": NSNull()])
        continue
      }
      let title = String((request["title"] as? String ?? "").prefix(120))
      let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: title),
        secondaryButton: nil,
        secondaryButtonBehavior: nil
      )
      let attributes = AlarmAttributes<ScheduleAlarmMetadata>(
        presentation: AlarmPresentation(alert: alert, countdown: nil, paused: nil),
        metadata: ScheduleAlarmMetadata(),
        tintColor: Color.accentColor
      )
      let configuration = AlarmManager.AlarmConfiguration<ScheduleAlarmMetadata>.alarm(
        schedule: .fixed(trigger),
        attributes: attributes,
        stopIntent: nil,
        secondaryIntent: nil,
        sound: .default
      )
      let id = alarmID(for: key)
      do {
        _ = try await manager.schedule(id: id, configuration: configuration)
        kept[id.uuidString] = key
        results.append(["requestKey": key, "status": "scheduled", "errorCode": NSNull()])
      } catch {
        results.append(["requestKey": key, "status": "failed", "errorCode": "scheduleFailed"])
      }
    }
    saveKeys(kept)
    return results
  }
  #endif
}
