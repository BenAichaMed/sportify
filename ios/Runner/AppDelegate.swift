import Flutter
import UIKit
import google_maps_flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyAAimr91Qct58LdQJHMVHhnBF8P1USAu8s")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
