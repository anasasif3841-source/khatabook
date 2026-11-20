# KhataBook – Digital Credit Ledger

KhataBook is an offline-first Flutter application designed for shopkeepers in Pakistan to manage customer accounts, record credit transactions, track balances, and share payment reminders.

The application provides a digital alternative to traditional paper-based khata registers. Customer and transaction data is stored locally using SQLite, allowing users to manage their records without an internet connection.

## Features

- **Customer Management:** Add and manage customers with their names and phone numbers.
- **Transaction Management:** Record money given (`You Gave`) and money received (`You Got`).
- **Transaction Dates and Notes:** Select transaction dates, including past dates, and add descriptions.
- **Customer Details:** View transaction history and running balances.
- **Dashboard:** View total receivable, total payable, top debtors, and recent transactions.
- **Monthly Charts:** Visualize monthly money given and received.
- **Customer Search:** Search customers by name or phone number.
- **WhatsApp Reminders:** Prepare payment reminders with the current customer balance.
- **SMS Reminders:** Open the SMS application with a pre-filled payment reminder.
- **PDF Statements:** Generate, preview, print, and share customer statements.
- **JPG Statements:** Export customer statements as images.
- **Backup and Restore:** Export and restore application data using JSON backup files.
- **Offline Support:** Store and manage customer and transaction data locally.
- **Dark Theme:** Supports system-based light and dark themes.

## Technology Stack

| Technology | Version / Constraint | Purpose |
|---|---|---|
| Flutter | SDK compatible with Dart 3.14 | Application framework |
| Dart | ^3.14.0 | Programming language |
| flutter_riverpod | ^3.5.0 | State management |
| sqflite | ^2.4.6 | Local SQLite database |
| fl_chart | ^1.3.1 | Monthly charts |
| pdf | ^3.13.1 | PDF generation |
| printing | ^5.15.1 | PDF preview and printing |
| url_launcher | ^6.3.3 | WhatsApp and SMS launching |
| share_plus | ^13.3.1 | File sharing |
| path_provider | ^2.1.6 | File storage |
| intl | ^0.20.3 | Date formatting |
| image | ^4.13.1 | Image processing |
| sqflite_common_ffi_web | ^1.2.2 | SQLite support for web |

*Package constraints are based on the project's pubspec.yaml file. Run `flutter --version` to check your installed Flutter and Dart SDK versions.*

## Project Architecture

KhataBook follows the Repository Pattern with Riverpod state management. This architecture separates the user interface, application state, data operations, and database functionality.

### Data Flow

```text
UI Screens
    |
    v
Riverpod Providers
    |
    v
Repository Layer
    |
    v
Database Service
    |
    v
SQLite Database
```

### Folder Structure

```text
lib/
|
|-- main.dart
|
|-- providers/
|   |-- repository_providers.dart
|   |-- dashboard_providers.dart
|   |-- customer_providers.dart
|   |-- transaction_providers.dart
|
|-- repositories/
|   |-- customer_repository.dart
|   |-- transaction_repository.dart
|   |-- dashboard_repository.dart
|
|-- screens/
|   |-- customer_screen.dart
|   |-- customer_detail_screen.dart
|   |-- add_transaction_screen.dart
|
|-- services/
|   |-- database_service.dart
|   |-- statement_service.dart
|   |-- backup_service.dart
|
|-- widgets/
|   |-- monthly_chart.dart
```

### State Management

Riverpod manages application state and data loading.

The application uses providers such as:

- `dashboardSummaryProvider`
- `topDebtorsProvider`
- `monthlyTotalsProvider`
- `customerTransactionsProvider`
- `customerBalanceProvider`

Screens use `AsyncValue.when()` to handle loading, error, and data states. Providers are invalidated after relevant data changes so that updated information is displayed automatically.

## Database Design

KhataBook uses SQLite for local data persistence.

### Main Tables

**Customers**

Stores customer information, including:

- Customer ID
- Customer name
- Phone number
- Creation date

**Transactions**

Stores transaction records, including:

- Transaction ID
- Customer ID
- Transaction type
- Amount
- Transaction date
- Note

### Database Features

- Database versioning and migration using `onUpgrade`.
- Foreign key relationship between customers and transactions.
- Foreign key enforcement using `PRAGMA foreign_keys=ON`.
- Database indexes for customer IDs and transaction dates.
- Transaction amount and type validation.
- Customer balances are calculated from transaction records rather than stored manually.
- Running balances are calculated from transaction history.
- Database transactions are used for safe backup restoration.

## Screenshots

Add actual screenshots captured from the application in the following locations.

### Light Theme

![KhataBook Light Theme](screenshots/lightmood.png)

### Dark Theme

![KhataBook Dark Theme](screenshots/darkmood.png)

## Installation and Setup

### Requirements

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android emulator or physical Android device

### 1. Clone the Repository

```bash
git clone https://github.com/anasasif3841-source/khatabook.git
```

### 2. Open the Project

```bash
cd khatabook
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the Application

```bash
flutter run
```

### 5. Build Release APK

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## APK Download

**GitHub Release v1.0.0**

[Download KhataBook APK from GitHub Releases](https://github.com/anasasif3841-source/khatabook/releases/tag/v1.0.0)

The release page should contain the latest tested `app-release.apk` file.

## Live Demo

[Open KhataBook Web Demo](https://cheery-lolly-779dff.netlify.app)

*Note: The web demo is provided for demonstration purposes. The Android release APK is the primary mobile application build.*

## Demo Video
(https://drive.google.com/file/d/14rY2fJhTeJCzPC_w9aOVzGqt__d8_qR3/view?usp=sharing).

## GitHub Repository

[View KhataBook Source Code](https://github.com/anasasif3841-source/khatabook)

## Project Objective

The objective of KhataBook is to provide shopkeepers with a simple and reliable digital alternative to traditional paper-based credit registers.

This project demonstrates practical implementation of Flutter development, SQLite database management, Riverpod state management, repository architecture, transaction calculations, charts, PDF statements, payment reminders, and data backup and restoration.

## Developer

**Muhammad Anas**

Flutter Application Development – Internship Project
