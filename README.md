# GuideSched Mobile App (Flutter)

Standalone green-themed **Flutter** mobile & web companion app for the **Cagasat High School Guidance Office (GuideSched)** portal.

This folder (`C:\xampp\htdocs\GuideSched-App`) contains **only** the Flutter application code and is completely separated from the PHP website (`c:\xampp\htdocs\APPOINTMENT IN GUIDANCE`). It communicates with the website's MySQL database (`guidesched`) over HTTP via `api/v2/`.

---

## Features & Full Role Parity

- **Public / Auth**:
  - Sign In (`student`, `counselor`, `principal`)
  - Student Registration (Grades 7–12 dynamic Cagasat High School section & strand selector, LRN, Parent/Guardian emergency contact, Data Privacy Act consent)
  - Forgot Password
  - Anonymous Session Feedback by Token
  - Server IP / Host switcher
- **Student Portal**:
  - Home Dashboard & quick actions
  - Appointments (Upcoming, Book New Session with weekday calendar & live slot availability, Cancel & Reschedule up to 2 times, Past History)
  - My Insights (personal session analytics & charts)
  - Feedback (portal feedback + anonymous session token feedback + counselor replies)
  - Notifications & Profile
- **Counselor Portal**:
  - Counselor Dashboard (KPIs, Urgent alerts, Today's schedule, Pending requests)
  - Appointments, Case Detail, Session Notes, Category Confirmation & Counselor-Initiated Entries (Walk-in, Referred, Summoned, Follow-up)
  - My Schedule (single & bulk weekday availability slot management)
  - Student Directory & Cumulative Student Records
  - School Sections & Strands Management
  - Analytics (2026 & multi-year interactive KPIs and chart drill-downs)
  - Reports (**Appointment Summary Report — Cagasat High School Guidance Office** with clickable rows opening the Full Data Modal + CSV share/export)
  - Student Feedback Management & Responses
  - Counselors, Add Counselor, Tenure History & Role Handover
  - Principals Management (Add, Edit, Delete)
  - Notifications & Profile
- **Principal Portal (View-Only with Audit Logging)**:
  - Principal Oversight Dashboard
  - Master Appointments & Audit-Logged Case Detail Inspection
  - Student Directory & Audit-Logged Student Counseling History
  - Analytics & Clickable Full-Data Reports
  - Notifications & Profile

---

## Running on Your Phone (Android or iPhone)

### Option A — Instant Mobile Web App over Wi-Fi (Works on both Android & iPhone, no cables needed)
1. Make sure **XAMPP Apache** and **MySQL** are running on your PC.
2. Connect your phone to the **same Wi-Fi network** as your PC.
3. Find your PC's Wi-Fi IPv4 address (run `ipconfig` in PowerShell, e.g. `192.168.106.124`).
4. Open Chrome (Android) or Safari (iPhone) on your phone and visit:
   ```
   http://<YOUR-PC-IP>/GuideSched-App/build/web/
   ```
5. Tap **Share -> Add to Home Screen** (iPhone) or **Menu -> Add to Home screen / Install app** (Android) to launch **GuideSched** full-screen with its green icon.
6. On the Login screen, tap **Server** in the top-right corner and make sure it is set to your PC's IP address (e.g. `192.168.106.124`).

### Option B — Native Android APK
1. Install **Android Studio** with the Android SDK.
2. Run:
   ```powershell
   cd C:\xampp\htdocs\GuideSched-App
   C:\flutter\bin\flutter.bat build apk --release
   ```
3. Copy `build\app\outputs\flutter-apk\app-release.apk` to your Android phone and install it.
4. On the Login screen, tap **Server** in the top-right and enter your PC's Wi-Fi IP address.
