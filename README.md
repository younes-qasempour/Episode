# OtakuLog 🌸

**OtakuLog** is a modern Flutter application for tracking, searching, and managing anime and manga logs, custom watchlists, and user profiles.

---

## 🚀 Getting Started for Collaborators

Follow these instructions to clone, set up, and run the project locally.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- [Dart SDK](https://dart.dev/get-started/sdk)
- Android Studio / VS Code with Flutter extension
- Android Emulator, iOS Simulator, or Chrome browser

---

## 🛠️ Setup & Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/younes-qasempour/OtakuLog.git
   cd OtakuLog
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the Application**
   ```bash
   # Run on default connected device / emulator
   flutter run

   # Or run on Chrome for Web
   flutter run -d chrome
   ```

4. **Run Unit & Widget Tests**
   ```bash
   flutter test
   ```

---

## 📁 Project Architecture & Structure

```
d:/OtakuLog/
├── lib/
│   ├── main.dart                      # App Entry point & Root widget
│   ├── data/                          # Mock data & static data providers
│   ├── models/                        # Data models (MediaItem, UserProfile, etc.)
│   ├── repositories/                  # Local storage & search repositories
│   ├── screens/                       # UI Screens & Tabs (Home, Search, Profile, Detail)
│   ├── services/                      # API integration services (Jikan / AniList / REST)
│   ├── theme/                         # App color tokens, typography, and dark/light themes
│   └── widgets/                       # Reusable UI components (MediaCard, SearchBar, etc.)
├── test/                              # Unit & Widget tests
├── android/                           # Android native configuration
├── web/                               # Web app entry configuration
├── pubspec.yaml                       # Package dependencies & assets configuration
├── pubspec.lock                       # Locked package versions
└── DESIGN.md                          # Design system & visual specifications
```

---

## 🤝 Branching & Workflow Guidelines for Collaborators

1. **Pull Latest Changes**: Always run `git pull origin main` before starting new work.
2. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Commit & Push**:
   ```bash
   git add .
   git commit -m "feat: description of your feature"
   git push origin feature/your-feature-name
   ```
4. **Open a Pull Request**: Submit a PR on GitHub to merge into `main`.
