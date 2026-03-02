# PillCare 💊

PillCare is a modern, futuristic medication management and adherence tracking application built with Flutter. Designed with a premium glassmorphic aesthetic, it provides intuitive tools for patients to track their medications and for caregivers to monitor and support them.

---

## 🚀 Basic Intro & Current State

Currently, PillCare functions as a highly-polished frontend prototype. It features complex UI components, fluid animations, and a centralized local State Management system (`MedicationStore`). 

**Note on Completeness:**
The project is currently **incomplete** regarding production deployment. While the UI and local logic are fully functional, the application relies on an upcoming **Deployment Agent** to wire up the persistent backend (Firebase) and publish the app to the web or app stores.

---

## ⚙️ Deployment & Running Locally

To run the current iteration of the application locally, ensure you have the Flutter SDK installed on your machine.

1. **Clone/Download** the repository.
2. Navigate to the project root directory.
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application on Chrome (recommended for current web-focused iteration):
   ```bash
   flutter run -d chrome
   ```

---

## 🔑 Environment Variables

To fully utilize the API integrations in the app, the following environment variables need to be configured. *Note: In a pure Flutter web setup, these are currently mocked or handled via `ai_service.dart` directly, but for production, they belong in a `.env` file.*

- `GROQ_API_KEY`: Required to power the AI Health Assistant features. Handled in `lib/services/ai_service.dart`.
- `STITCH_API_KEY` & `STITCH_URL`: Needed for the MCP Stitch server integration.
- `FIREBASE_OPTIONS`: Configuration details (API Key, App ID, Project ID) required once the Deployment Agent attaches the database.

---

## 📁 Project Structure & File Explanations

The core application logic lives within the `lib/` directory.

### Screens (`lib/screens/`)
* **`home_screen.dart` & `home_content.dart`**: The main dashboard. Features the Daily Adherence progress ring, today's medication list, and the nested `AiHealthInsightsCard`.
* **`schedule_screen.dart`**: A futuristic vertical timeline of the user's medication schedule, coupled with a dynamic Refill Counter with caregiver request features.
* **`alerts_screen.dart`**: A notification center displaying missed doses, refill warnings, and caregiver messages.
* **`profile_screen.dart`**: The user settings dashboard. Includes editable Caregiver Contact Cards, a dynamic BMI Calculator, and links to deeper preferences.
* **`ai_chat_screen.dart`**: The conversational interface communicating with the Groq API to provide health insights.
* **`login_screen.dart` & `signup_screen.dart`**: Authentication flows featuring smooth transitions and form validation.
* **`all_medications_screen.dart`**: A master list of all medications for the user.
* **`add_medication_sheet.dart`**: A complex, scrollable bottom sheet used to input new medication details (dosage, schedule, shapes, colors).

### Architectural Components
* **`ai_health_insights_card.dart`**: The tabbed UI card displaying AI summaries and mock caregiver approval actions.
* **`daily_adherence_card.dart`**: The animated circular progress indicator on the home screen.
* **`patient_chat_screen.dart`**: The interface representing direct communication between the Patient and their Caregiver.

### Models & Services
* **`lib/models/medication.dart`**: The defining data structure for a pill (Name, Dosage, Color, Icon, Refill Count, Time).
* **`lib/services/medication_store.dart`**: A `ChangeNotifier` singleton that acts as the temporary local database, broadcasting state changes across the app.
* **`lib/services/ai_service.dart`**: The API client configured to stream SSE responses from Groq's language models.

---

## 🏗️ System Architecture & Workflows

### 1. Presentation Layer
Built purely with Flutter widgets, heavy emphasis is placed on `BackdropFilter` for glassmorphism, `AnimationController` for pulsating glows/sparks, and `TweenAnimationBuilder` for smooth entry transitions.

### 2. State Management (Current)
Instead of passing data down the widget tree, PillCare uses the `Provider` pattern minimally, relying on a unified `MedicationStore` singleton wrapped in `ListenableBuilder`. When a user taps "Mark as Taken", the store updates the medication and notifies all listeners to redraw the UI instantly.

### 3. API Workflows (AI Chat)
When a user asks a question in the AI Chat:
1. The UI appends a user message.
2. `AiService.streamGroqResponse()` opens a `Client` request to Groq's OpenAI-compatible endpoint.
3. It parses the Server-Sent Events (SSE) chunk by chunk.
4. The UI yields these chunks into the active Assistant message bubble, creating a typewriter effect.

---

## 🤖 The Future: Deployment Agent

The project is currently architected to be "Backend Ready", but the backend does not yet exist. The future **Deployment Agent** will be responsible for the following critical tasks to make the app production-ready:

1. **Firebase Integration**: 
   - Replace the mock data inside `MedicationStore` with `cloud_firestore` streams.
   - Wire up `firebase_auth` to the existing Login and Signup screens.
2. **Push Notifications**:
   - Integrate Firebase Cloud Messaging (FCM) so the "Request Refill" or "Caregiver Alerts" trigger real push notifications on the recipient's phone.
3. **CI/CD Pipeline**:
   - Set up GitHub Actions or a Vercel/Firebase Hosting pipeline to automatically build and deploy `flutter build web` upon code merges.
4. **Environment Security**:
   - Move hardcoded API keys into secure Secret Managers and inject them as Dart environment flags (`--dart-define`).
