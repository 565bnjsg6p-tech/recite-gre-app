# Local Setup

This project currently contains the Flutter application code and the Android/iOS
platform folders copied from the UI template.

Install Flutter and make sure `flutter` is available in PATH, then run:

```powershell
cd D:\c\APPing\recite_gre_app
flutter pub get
flutter create --platforms=ios,macos,windows .
flutter run
```

The `flutter create` command fills in any missing desktop platform folders while
keeping the existing `lib`, `assets`, and `pubspec.yaml` files.
