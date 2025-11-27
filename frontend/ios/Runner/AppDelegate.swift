import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
//     GMSServices.provideAPIKey("AIzaSyDEsHOhCudunjvxMIXRQi79gVDCIL_5sPA")
    GMSServices.provideAPIKey("AIzaSyBHhl_m1kcU02O4Ghyg_pRQ9OGk7t0d-Ec")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
