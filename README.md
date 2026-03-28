# OmniFit

A comprehensive health and fitness application developed as a hackathon team project. OmniFit goes beyond standard metric tracking by integrating AI-powered exercise form validation and an intelligent muscle recovery recommendation system.

## Key Features

* **AI Vision Rep Counter & Form Validation:** Integrates Google AI models to process real-time user movement. The system validates exercise form and automatically counts repetitions for exercises such as squats and push-ups.
* **Smart Recovery Engine:** Features a post-workout effort slider that captures perceived exertion. Based on this input, the system generates AI-driven recommendations on whether the user should target specific muscle groups in their next session or prioritize rest.
* **Comprehensive Tracking Modules:** Includes dedicated trackers for meditation, hydration, daily caloric intake, and complete workout histories to provide a holistic overview of the user's health.

## Technologies Used

* **Frontend:** Flutter
* **Backend** Dart
* **Database:** MySQL
* **AI / Machine Learning:** Google AI Vision

## Getting Started

To run this project locally, you will need to set up the Flutter environment and configure a local MySQL database.

### Prerequisites

* Flutter SDK
* A local MySQL server (DBngin is highly recommended for macOS users)
* A database client (e.g., TablePlus, DBeaver, or MySQL Workbench)

### Database Setup

1. **Install DBngin:** Download and install [DBngin](https://dbngin.com/).
2. **Start MySQL Server:** Open DBngin, create a new MySQL server instance, and start the service.
3. **Initialize Database:**
   * Open your preferred database client and connect to the local MySQL server instance created via DBngin.
   * Locate the SQL script provided in this repository (e.g., 'db.sql' or similar).
   * Execute the script to create the required database schema and initialize the tables.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Razvannb/OmniFit.git
2. Navigate to the project directory:
   ```bash
   cd OmniFit
3. Install the required Flutter dependencies:
   ```bash
   flutter pub get
4. Configure Database Connection: Ensure that the database connection strings in the application code point to your local MySQL instance (typically localhost or 127.0.0.1 on the port specified by DBngin, usually 3306).
5. Run the application:
   ```bash
   flutter run
