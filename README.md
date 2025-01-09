# Drive X - Web Application

Drive X is a Flutter-based web application that enables users to upload Excel files and interact with the content using Google's Gemini AI API. Users can ask any questions related to the data in the uploaded Excel sheets and receive AI-generated answers.

## Features

- **Upload Excel Files**: Users can upload `.xlsx` files directly from their device or provide a Google Drive link to fetch the file.
- **View File Content**: Display the content of the uploaded Excel file in a tabular format with horizontal scrolling for better accessibility.
- **AI-Powered Q&A**: Using Google's Gemini AI API, users can ask questions about the uploaded Excel data and receive accurate answers.
- **Responsive Design**: The web app is built with a responsive layout, ensuring seamless user experience across devices.

## Hosted Application

This web application is hosted on Firebase. [Access the Web App Here](https://anishdrivex.web.app/)

## Getting Started

### Prerequisites

- Flutter installed on your system.
- Firebase CLI installed and configured.
- Google Gemini AI API Key.

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-repository/drive-x.git
   cd drive-x
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the project:
   - Replace `apiKey` in the `GenerativeModel` initialization with your Google Gemini AI API key.

4. Run the application locally:
   ```bash
   flutter run -d chrome
   ```

### Deploying to Firebase

1. Build the Flutter web app:
   ```bash
   flutter build web
   ```

2. Deploy to Firebase:
   ```bash
   firebase deploy
   ```

## Usage

1. Open the web application in your browser.
2. Choose an input method:
   - Upload an Excel file directly.
   - Paste a Google Drive link.
3. View the uploaded file's content in a scrollable table.
4. Enter a question related to the Excel content and get an AI-generated answer.

## Technologies Used

- **Flutter**: Framework for building the web application.
- **Firebase Hosting**: Platform for deploying and hosting the web app.
- **Google Gemini AI**: API for AI-powered Q&A functionality.
- **Dart**: Programming language for Flutter development.

## Screenshots

_Add screenshots of the application interface here._

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter documentation
- Firebase documentation
- Google Gemini AI API

---
Feel free to reach out for any issues or feature requests!
