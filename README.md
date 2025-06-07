# 💰 Saldo

**Saldo** is a minimalist and modern expense tracking app built with Flutter. It enables users to manage personal finances by adding, editing, and reviewing income and expense transactions. Featuring offline-first functionality, Material 3 theming, and Chinese Yuan currency display, Saldo is designed for mobile users who prefer simplicity and privacy.

------

## ✨ Features

- 📆 Add, edit, and delete income or expense transactions
- 📊 Automatically calculate and display total income and expenses
- 💾 Offline-first: all data stored locally with `sqflite`
- 💴 Currency display in Chinese Yuan (￥)

------

## 📱 Built With

- **Flutter 3.x** – Cross-platform mobile development framework
- **sqflite** – Lightweight local SQLite database plugin
- **path_provider** – File system access for local storage paths

------

## 🚀 Getting Started

### Clone and Run Locally

```bash
git clone https://github.com/your_username/saldo.git
cd saldo
flutter pub get
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

------

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.0.14
  intl: ^0.18.1
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

------

## 📈 Planned Features

- ✅ Dark/Light mode support
- ⏳ Monthly expense/income charts and summaries
- ⏳ Export transactions as CSV
- ⏳ Budget tracking and alerts
- ⏳ Multi-currency support


------

## 🤝 Acknowledgements

Developed with 💖 using Flutter and open-source packages.
 Special thanks to the Flutter community for documentation, tools, and inspiration.

------

