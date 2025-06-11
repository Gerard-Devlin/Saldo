# 💰 Saldo

**Personal Finance + AI Assistant.**
*Track your money, get insights from AI.*


------

## ✨ Features

- 📆 Add, edit, and delete income or expense transactions
- 📊 Instantly calculate and visualize total income & spending
- 💾 Offline-first: all data stored locally (no login required)
- 💴 Currency support for Chinese Yuan (￥)
- 🤖 **AI Assistant**: Ask your finances anything – powered by Kimi/GPT
    - Summarize monthly spending habits
    - Get budgeting suggestions based on your real data
    - Talk to your financial history like a chatbot!

------

## 🧠 Powered by LLM: Your AI Financial Analyst

Saldo integrates a cutting-edge large language model (LLM) via Kimi or OpenAI's API to offer **real-time insights** from your transaction history.

💡 Ask questions like:

> *"What categories did I overspend on last month?"*
>
> *"Summarize my income trend over the past 3 months."*
>
> *"Do I have a food delivery problem?"*

📦 Your data never leaves your device without your permission. All analysis is done securely
through encrypted API requests.

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

  intl: ^0.18.1
  sqflite: ^2.3.0
  flutter_math_fork: ^0.7.4
  speech_to_text: ^7.0.0
  path: ^1.9.0
  percent_indicator: ^4.2.2
  flutter_launcher_icons: ^0.13.1
  http: ^0.13.6
  fl_chart: ^0.64.0
  font_awesome_flutter: ^10.7.0
  flutter_markdown: ^0.6.18
  shared_preferences: ^2.2.2
```

------

## 📈 Planned Features

- ⏳ Dark/Light mode support
- ✅ Monthly expense/income charts and summaries
- ⏳ Export transactions as CSV
- ⏳ Budget tracking and alerts
- ⏳ Multi-currency support

------

## 🤝 Acknowledgements

Developed with 💖 using Flutter and open-source packages.
Special thanks to the Flutter community for documentation, tools, and inspiration.

------

