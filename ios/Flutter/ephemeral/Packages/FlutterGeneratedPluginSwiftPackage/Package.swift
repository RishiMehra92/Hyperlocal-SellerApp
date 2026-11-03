// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "app_settings", path: "../.packages/app_settings-9.0.1"),
        .package(name: "audio_session", path: "../.packages/audio_session-0.2.4"),
        .package(name: "audioplayers_darwin", path: "../.packages/audioplayers_darwin-6.5.0"),
        .package(name: "connectivity_plus", path: "../.packages/connectivity_plus-7.3.1"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.7.1"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.15.2"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-16.7.1"),
        .package(name: "flutter_image_compress_common", path: "../.packages/flutter_image_compress_common-1.1.1"),
        .package(name: "flutter_keyboard_visibility_temp_fork", path: "../.packages/flutter_keyboard_visibility_temp_fork-0.1.6"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.3"),
        .package(name: "geocoding_darwin", path: "../.packages/geocoding_darwin-1.0.3"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.4.3"),
        .package(name: "image_picker_ios", path: "../.packages/image_picker_ios-0.8.13+14"),
        .package(name: "is_ios_simulator", path: "../.packages/is_ios_simulator-1.0.1"),
        .package(name: "just_audio", path: "../.packages/just_audio-0.10.6"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-10.2.2"),
        .package(name: "quill_native_bridge_ios", path: "../.packages/quill_native_bridge_ios-0.0.3"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.6.1"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.4+1"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.2"),
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation-2.12.3"),
        .package(name: "wakelock_plus", path: "../.packages/wakelock_plus-1.8.0"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.27.2"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "app-settings", package: "app_settings"),
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "audioplayers-darwin", package: "audioplayers_darwin"),
                .product(name: "connectivity-plus", package: "connectivity_plus"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "flutter-image-compress-common", package: "flutter_image_compress_common"),
                .product(name: "flutter-keyboard-visibility-temp-fork", package: "flutter_keyboard_visibility_temp_fork"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "geocoding-darwin", package: "geocoding_darwin"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "is-ios-simulator", package: "is_ios_simulator"),
                .product(name: "just-audio", package: "just_audio"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "quill-native-bridge-ios", package: "quill_native_bridge_ios"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "wakelock-plus", package: "wakelock_plus"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
