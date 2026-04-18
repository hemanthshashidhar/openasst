# ORB — Setup & Run Guide

## What is ORB?
**On-screen Reasoning Brain** — a floating AI assistant that lives on your Android screen across all apps. Powered by your own API key (Claude, GPT, or Gemini).

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter | 3.19+ | https://docs.flutter.dev/get-started/install |
| Android Studio | Latest | For emulator / SDK |
| Android Device | Android 8.0+ (API 23+) | Physical device recommended for overlay |
| Python | 3.10+ | For Telegram bridge only |

---

## Step 1 — Get the fonts

ORB uses SpaceMono. Download the font files and place them at:

```
assets/fonts/SpaceMono-Regular.ttf
assets/fonts/SpaceMono-Bold.ttf
```

Download from Google Fonts: https://fonts.google.com/specimen/Space+Mono

Or run this from inside the project folder:
```bash
mkdir -p assets/fonts
curl -L "https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Regular.ttf" -o assets/fonts/SpaceMono-Regular.ttf
curl -L "https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Bold.ttf" -o assets/fonts/SpaceMono-Bold.ttf
```

Also create a placeholder character asset:
```bash
mkdir -p assets/character
touch assets/character/.gitkeep
```

---

## Step 2 — Install Flutter dependencies

```bash
cd orb_assistant
flutter pub get
```

---

## Step 3 — Connect your Android device

Enable Developer Options on your phone:
- Settings → About Phone → tap Build Number 7 times
- Settings → Developer Options → enable USB Debugging

Connect via USB, then:
```bash
flutter devices
# Should show your device
```

---

## Step 4 — Run the app

```bash
flutter run
```

For a release build (faster, no debug banner):
```bash
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

Install the APK on your phone:
```bash
flutter install
```

---

## Step 5 — Grant overlay permission

When the app opens:
1. Tap the **◉ ORB orb** on the home screen
2. Android will prompt you to grant "Display over other apps" permission
3. Enable it for ORB
4. Tap the orb again — it will now float over all your apps

---

## Step 6 — Add your API key

1. Open ORB → tap **Settings** (gear icon)
2. Go to **API Keys** tab
3. Enter your key for Claude / OpenAI / Gemini
4. Go to **Model** tab and select your preferred provider
5. Tap **Save**

**Where to get API keys:**
- Claude: https://console.anthropic.com
- OpenAI: https://platform.openai.com/api-keys
- Gemini: https://aistudio.google.com/app/apikey

---

## Step 7 — Using ORB

**Launch:** Tap the floating ◉ bubble on your screen

**Chat:** Type or speak your question in the overlay

**Documents:** Settings → Documents → Load a PDF or TXT file → Ask ORB questions about it

**Alarms:** Say "Set alarm for 7am" or "Wake me at 8:30" — ORB will create the alarm

**Notes:** Say "Save note: Remember to check emails"

---

## Telegram Bridge (Optional)

Run ORB from Telegram even when your phone is locked.

### Setup:
```bash
cd telegram_bridge
pip install -r requirements.txt
```

### Run:
```bash
# With Claude
python bot.py --token YOUR_TELEGRAM_BOT_TOKEN --provider claude --apikey YOUR_CLAUDE_KEY

# With OpenAI
python bot.py --token YOUR_TELEGRAM_BOT_TOKEN --provider openai --apikey YOUR_OPENAI_KEY

# With Gemini
python bot.py --token YOUR_TELEGRAM_BOT_TOKEN --provider gemini --apikey YOUR_GEMINI_KEY

# With a specific model
python bot.py --token TOKEN --provider claude --apikey KEY --model claude-opus-4-5
```

### Get a bot token:
1. Open Telegram → search @BotFather
2. Send `/newbot`
3. Follow the steps → copy the token

---

## Troubleshooting

### "Overlay not showing"
- Make sure "Display over other apps" permission is granted in Android settings
- Go to Settings → Apps → ORB → Special app access → Display over other apps → Allow

### "API key not working"
- Claude keys start with `sk-ant-`
- OpenAI keys start with `sk-`
- Gemini keys start with `AIza`
- Make sure you have credits/quota on your account

### "App crashes on launch"
```bash
flutter clean
flutter pub get
flutter run
```

### "flutter_secure_storage error on Android"
This is usually a minSdk issue. Make sure your `android/app/build.gradle` has `minSdkVersion 23`.

### Build errors with Syncfusion PDF
Syncfusion is free for personal use but requires registration for commercial use. The package works without a license key for development.

### "Speech to text not working"
- Go to phone Settings → Apps → ORB → Permissions → Microphone → Allow

---

## Project Structure

```
orb_assistant/
├── lib/
│   ├── main.dart                    ← App entry point
│   ├── overlay/
│   │   ├── bubble_entry.dart        ← Floating bubble widget
│   │   └── chat_overlay.dart        ← Chat UI
│   ├── ai/
│   │   ├── ai_router.dart           ← Routes to correct provider
│   │   ├── claude_provider.dart     ← Anthropic Claude
│   │   ├── openai_provider.dart     ← OpenAI GPT
│   │   └── gemini_provider.dart     ← Google Gemini
│   ├── actions/
│   │   └── action_detector.dart     ← Phone actions (alarms, notes)
│   ├── document/
│   │   └── pdf_reader.dart          ← PDF/TXT extraction
│   ├── memory/
│   │   ├── database.dart            ← SQLite setup
│   │   └── memory_manager.dart      ← History + context
│   ├── settings/
│   │   ├── settings_screen.dart     ← Main settings
│   │   ├── history_screen.dart      ← Chat history
│   │   ├── document_screen.dart     ← Document manager
│   │   └── telegram_screen.dart     ← Telegram bridge info
│   └── utils/
│       ├── app_theme.dart           ← Colors + styles
│       └── constants.dart           ← App constants
├── android/                         ← Android native config
├── telegram_bridge/
│   ├── bot.py                       ← Telegram Python bot
│   └── requirements.txt
├── assets/
│   ├── fonts/                       ← SpaceMono font files
│   └── character/                   ← Avatar assets (future)
└── pubspec.yaml                     ← Dependencies
```

---

## v2 Features (Coming Next)

- [ ] Screenshot + Vision mode (capture screen → analyze with GPT-4o Vision)
- [ ] Context stacking across app switches
- [ ] Morning briefing routine
- [ ] Notification summarization
- [ ] Custom avatar / character
- [ ] Cloud sync option
- [ ] iOS support

---

Built with ❤️ by Hemanth | ORB — On-screen Reasoning Brain
