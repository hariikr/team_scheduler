# Team Scheduler

A Flutter application for team scheduling and availability management with automatic slot finding capabilities. Built with Flutter, Supabase, and BLoC pattern for state management.

## Features

- **User Authentication**: Secure login and registration using Supabase authentication
- **Availability Management**: Users can set and manage their availability schedules
- **Task Management**: Create and assign tasks to team members
- **Auto Slot Finder**: Automatically finds optimal meeting times based on team availability
- **Real-time Updates**: Leverages Supabase for real-time data synchronization
- **Cross-platform**: Runs on Android, iOS, Web, Windows, macOS, and Linux

## Tech Stack

- **Framework**: Flutter
- **State Management**: BLoC (flutter_bloc)
- **Backend**: Supabase
- **Authentication**: Supabase Auth
- **Database**: Supabase (PostgreSQL)
- **Additional Libraries**:
  - `equatable` - Value equality for state management
  - `shared_preferences` - Local data persistence
  - `image_picker` - Image selection functionality
  - `intl` - Internationalization and date formatting
  - `uuid` - Unique identifier generation

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── data/                     # Data layer
│   ├── models/              # Data models
│   └── services/            # API and service implementations
├── logic/                    # Business logic layer (BLoC)
│   ├── auth/                # Authentication logic
│   ├── availability/        # Availability management logic
│   ├── task/                # Task management logic
│   └── user/                # User management logic
└── presentation/             # UI layer
    ├── auth/                # Authentication screens
    ├── availability/        # Availability screens
    └── task/                # Task management screens
```

## Getting Started

### Prerequisites

- Flutter SDK (>= 2.18.0)
- Dart SDK
- A Supabase account and project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hariikr/team_scheduler.git
   cd team_scheduler
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Update the Supabase URL and anon key in `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

- **Android**: `flutter build apk` or `flutter build appbundle`
- **iOS**: `flutter build ios`
- **Web**: `flutter build web`
- **Windows**: `flutter build windows`
- **macOS**: `flutter build macos`
- **Linux**: `flutter build linux`

## Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Format Code

```bash
flutter format .
```

## Architecture

This project follows the **BLoC (Business Logic Component)** pattern for clean architecture:

- **Presentation Layer**: UI components and screens
- **Logic Layer**: BLoC cubits for state management
- **Data Layer**: Models, repositories, and service implementations

The separation of concerns ensures maintainability, testability, and scalability.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is available under the MIT License.

## Contact

Project Link: [https://github.com/hariikr/team_scheduler](https://github.com/hariikr/team_scheduler)

## Resources

For help getting started with Flutter:

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Supabase Documentation](https://supabase.com/docs)
- [BLoC Library](https://bloclibrary.dev/)
