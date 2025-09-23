# 🧾 BillExpert - Professional Invoice & Billing Management

<div align="center">

![BillExpert Logo](assets/logo/applogo.png)

**A modern, feature-rich invoice and billing management application built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Play Store](https://img.shields.io/badge/Play_Store-Ready-green.svg)](#)

</div>

## ✨ Features

### 📊 **Invoice Management**
- ✅ Create, edit, and manage professional invoices
- ✅ Multiple invoice statuses (Draft, Sent, Paid, Overdue, etc.)
- ✅ Custom invoice numbering and prefixes
- ✅ PDF generation and sharing
- ✅ Invoice templates with business branding

### 👥 **Client Management**
- ✅ Comprehensive client database
- ✅ Client contact information and history
- ✅ Quick client selection for invoices
- ✅ Client-specific settings and preferences

### 💰 **Financial Features**
- ✅ Multi-currency support (USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR)
- ✅ Real-time exchange rates
- ✅ Tax calculations and customizable tax rates
- ✅ Discount management (percentage and fixed amounts)
- ✅ Payment tracking and status updates

### 🎨 **User Experience**
- ✅ Modern, responsive design
- ✅ Dark and light theme support
- ✅ Smooth animations and transitions
- ✅ Intuitive navigation with bottom tabs
- ✅ 120Hz refresh rate support

### 🚀 **Performance & Optimization**
- ✅ Currency conversion caching for better performance
- ✅ Optimized list views with lazy loading
- ✅ Efficient state management with Riverpod
- ✅ Local data storage with Hive database
- ✅ Code obfuscation and tree-shaking

### 💼 **Business Features**
- ✅ Business profile management
- ✅ Customizable invoice preferences
- ✅ Professional PDF exports
- ✅ Data backup and export capabilities
- ✅ AdMob integration for monetization

## 📱 Screenshots

*Coming soon - Add screenshots of your app here*

## 🛠 Tech Stack

### **Frontend Framework**
- **Flutter 3.8.1+** - Cross-platform UI framework
- **Dart 3.0+** - Programming language

### **State Management**
- **Riverpod 3.0+** - Modern state management solution

### **Navigation**
- **GoRouter 16.2+** - Declarative routing

### **Local Storage**
- **Hive 2.2+** - Fast, lightweight local database
- **Shared Preferences** - Simple key-value storage

### **UI/UX**
- **Material Design 3** - Modern Material Design
- **Custom themes** - Dark/Light mode support
- **Responsive design** - Adaptive layouts for all screen sizes

### **External Services**
- **ExchangeRate API** - Live currency exchange rates
- **Google AdMob** - Monetization through ads
- **URL Launcher** - External link handling

### **Development Tools**
- **Flutter Lints** - Code analysis and quality
- **Build Runner** - Code generation
- **Flutter Launcher Icons** - App icon generation

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/HASHIM-HAMEEM/BillExpertApp.git
   cd billexpert
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate app icons** (optional)
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

#### iOS (macOS only)
```bash
flutter build ios --release
```

## 📂 Project Structure

```
lib/
├── app/                    # App-level configuration
│   ├── routes/            # Navigation and routing
│   └── themes/            # App themes and styling
├── core/                  # Core functionality
│   ├── config/            # App configuration
│   ├── models/            # Data models
│   ├── services/          # Business logic and services
│   ├── utils/             # Utility functions
│   └── widgets/           # Reusable widgets
├── features/              # Feature modules
│   ├── clients/          # Client management
│   ├── dashboard/        # Dashboard and overview
│   ├── invoice/          # Invoice management
│   ├── onboarding/       # First-time user setup
│   └── settings/         # App settings
├── shared/               # Shared components
│   └── widgets/          # Common widgets
└── main.dart            # App entry point
```

## 🔧 Configuration

### Environment Setup

1. **AdMob Configuration**
   - Update `android/app/src/main/AndroidManifest.xml` with your AdMob App ID
   - Configure ad unit IDs in `lib/core/config/app_config.dart`

2. **App Signing** (Production)
   - Generate a keystore for release builds
   - Update `android/app/build.gradle.kts` with signing configuration

3. **API Keys**
   - No additional API keys required for basic functionality
   - Exchange rates are fetched from a free public API

## 🤝 Contributing

We welcome contributions to BillExpert! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` to check for issues
- Run `flutter test` before submitting PRs

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Hashim Hameem**
- Email: scnz141@gmail.com
- GitHub: [@hashimhameem](https://github.com/hashimhameem)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All contributors and users of BillExpert
- Free Palestine 🇵🇸

## 📞 Support

If you have any questions or need support:

1. Check the [Issues](../../issues) section
2. Create a new issue with detailed information
3. Contact the developer at scnz141@gmail.com

## 🔄 Version History

### v1.0.0 (Initial Release)
- Complete invoice management system
- Client management functionality
- Multi-currency support
- PDF generation
- Dark/Light themes
- AdMob integration
- Professional UI/UX

---

<div align="center">

**Made with ❤️ using Flutter**

[⬆ Back to top](#-billexpert---professional-invoice--billing-management)

</div>