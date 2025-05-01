# VROOOM - Luxury Car Rental Admin Dashboard

A beautiful Flutter admin dashboard for the VROOOM luxury car rental service.

![VROOOM Admin Dashboard](https://raw.githubusercontent.com/sfeirc/VROOOM_FLUTTER/main/screenshots/dashboard.jpg)

## Features

- 🚗 Complete vehicle management
- 👥 User management system
- 📊 Reservation handling and tracking
- 🎨 Modern UI with beautiful animations
- 🔒 Secure authentication
- 🌐 Node.js backend with MySQL database

## Tech Stack

### Frontend (Flutter)
- Flutter & Dart
- Google Fonts
- Flutter Animate (for beautiful animations)
- Provider (for state management)
- HTTP package (for API communication)

### Backend (Node.js)
- Express.js
- MySQL database
- JWT authentication
- RESTful API design
- CORS support

## Getting Started

### Requirements
- Flutter 3.0+
- Node.js 14+
- MySQL 8.0+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/sfeirc/VROOOM_FLUTTER.git
cd VROOOM_FLUTTER
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Set up the server:
```bash
cd server
npm install
```

4. Create a MySQL database using the schema provided in `server/schema.sql`

5. Create a `.env` file in the server directory with the following variables:
```
DB_HOST=localhost
DB_USER=your_username
DB_PASSWORD=your_password
DB_NAME=vroom_prestige
SESSION_SECRET=your_session_secret
PORT=3000
```

### Running the Application

1. Start the backend server:
```bash
cd server
node server.js
```

2. Run the Flutter application:
```bash
flutter run -d chrome
```

## Project Structure

- `/lib` - Flutter application code
  - `/providers` - State management
  - `/screens` - UI screens
  - `/services` - API service layer
  - `/models` - Data models
- `/server` - Node.js backend
  - `server.js` - Main Express server
  - `/routes` - API endpoints
  - `/models` - Database models

## Screenshots

![Vehicle Management](https://raw.githubusercontent.com/sfeirc/VROOOM_FLUTTER/main/screenshots/vehicles.jpg)
![User Management](https://raw.githubusercontent.com/sfeirc/VROOOM_FLUTTER/main/screenshots/users.jpg)
![Reservation System](https://raw.githubusercontent.com/sfeirc/VROOOM_FLUTTER/main/screenshots/reservations.jpg)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Created by [Your Name]
- Special thanks to all contributors
