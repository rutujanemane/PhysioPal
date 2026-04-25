# PRD: PhysioPal — The Digital Physiotherapist

> **Context:** This is a hackathon project for **LA Hacks 2026**. Two teammates are building it: **Puneet** (Context Engine + Escalation) and **Rutuja** (Supervision Engine + Rewards). The app is iOS only (SwiftUI, iPhone 12+). See `CLAUDE.md` for the full UI/UX design system and judging checklist. See `physiopal.md` for the project overview and current implementation state.

## 1. Introduction / Overview

PhysioPal is a fully on-device iOS app that bridges the **"Supervision Gap"** in physical therapy. Patients prescribed exercises by their physiotherapist often perform them at home unsupervised, with incorrect form, risking further injury. PhysioPal solves this by combining **Apple Health data** for adaptive routine selection and **on-device pose estimation** for real-time form correction — all without sending any video data to the cloud.

This is a **hackathon proof-of-concept** (1–2 day build) demonstrating the end-to-end flow: health-aware exercise adaptation, real-time supervision, gamified rewards, and escalation to a human physiotherapist.

**Target audience:** Elderly patients (60–80+) doing physiotherapy at home. The UI is designed for large text, generous touch targets, simple linear navigation, and warm encouraging language. We are competing for the **Best UI/UX** prize.

---

## 2. Goals

1. Demonstrate a working end-to-end flow from health data ingestion → exercise supervision → reward/escalation in a single iPhone app.
2. Prove that on-device pose estimation can detect incorrect form and provide real-time corrective feedback with zero cloud dependency.
3. Show adaptive exercise selection driven by Apple Health data (sleep, energy).
4. Deliver a polished, demo-ready experience suitable for a hackathon presentation.

---

## 3. User Stories

1. **As a patient**, I want the app to check my sleep and energy levels before I start exercising, so that my routine is adjusted to my current physical readiness and I don't risk injury.

2. **As a patient**, I want to see real-time feedback on my exercise form through my iPhone camera, so that I can correct my posture without needing my physiotherapist present.

3. **As a patient**, I want to be rewarded with a fun animation when I complete my routine with proper form, so that I feel motivated to continue my recovery.

4. **As a patient**, if I'm repeatedly struggling with an exercise, I want the app to connect me with my physiotherapist via a call or video, so that I can get immediate human help.

5. **As a physiotherapist**, I want my patient to have supervised exercise sessions between appointments, so that their recovery stays on track.

---

## 4. Functional Requirements

### 4.1 Context Engine (Apple Health Integration)

1. The app **must** request and read HealthKit data for `sleepAnalysis` (previous night) and `activeEnergyBurned` (current day) on launch.
2. The app **must** evaluate the user's physical readiness based on sleep duration and energy levels.
3. The app **must** adjust the exercise routine based on readiness:
   - **Low readiness** (e.g., < 5 hours sleep or low energy): reduce reps, substitute easier exercise variants (e.g., deep squats → assisted chair-squats).
   - **Normal readiness**: present the standard routine.
4. The app **must** display the adjusted recommendation in a handwritten-style font, resembling a doctor's note.
5. The app **must** show the user *why* the routine was adjusted (e.g., "You only got 4 hours of sleep last night — let's take it easy today").

### 4.2 Supervision Engine (On-Device Pose Estimation)

6. The app **must** access the iPhone's camera and run pose estimation entirely on-device using ZeticAI's Melange SDK with Google MediaPipe Pose Estimation.
7. The app **must** never transmit camera/video data off the device.
8. The app **must** track skeletal joint positions in real-time during exercise.
9. The app **must** detect incorrect posture (e.g., knees caving inward during squats, excessive forward lean) by comparing joint angles against acceptable thresholds for each exercise.
10. The app **must** provide immediate on-screen corrective feedback when incorrect form is detected (e.g., "Straighten your back", "Keep knees over toes").
11. The app **must** count completed reps with correct form.

### 4.3 Exercise Library

12. The app **must** include a pre-defined set of exercises for the demo (minimum: squats, chair-squats, standing leg raises, wall push-ups).
13. Each exercise **must** have defined correct-form parameters (joint angle thresholds) and at least one easier variant.
14. The app **must** select exercises and difficulty based on the health data assessment from the Context Engine.

### 4.4 Reward System (Gamification)

15. Upon successful completion of a routine with proper form, the app **must** display a reward animation: 5 translucent alien hacker characters performing a fist bump.
16. The characters **must** be semi-transparent so the exercise summary beneath remains readable.
17. The app **must** show an exercise summary after completion (reps completed, form accuracy percentage, routine duration).

### 4.5 Escalation (Handoff to Real PT)

18. If the user fails posture checks on the same exercise **3 or more consecutive times**, the app **must** trigger the escalation flow.
19. The escalation flow **must** initiate a phone call to a physiotherapist number via Twilio API.
20. The app **must** offer a follow-up option to join a Zoom video call with the physiotherapist (via Zoom API integration).
21. The escalation screen **must** clearly communicate: "Let's get your physiotherapist on the line to help."

---

## 5. Non-Goals (Out of Scope)

- **User authentication / account system** — not needed for the hackathon demo.
- **Physiotherapist-facing dashboard** — the PT does not interact with the app directly in this version.
- **Custom exercise creation by PTs** — exercises are pre-defined for the demo.
- **Persistent data storage / workout history** — session data lives only for the current session.
- **Android support** — iPhone only.
- **iPad / Apple Watch support** — iPhone only.
- **Cloud-based AI or model training** — everything runs on-device.
- **App Store readiness** — this is a proof of concept, not a production release.
- **Multi-language support.**

---

## 6. Design Considerations

- **Doctor's Note UI**: The health recommendation screen should use a handwritten/script-style font (e.g., a custom font resembling a doctor's prescription) to create a warm, human feel rather than a clinical machine output.
- **Camera View**: The supervision screen should show the live camera feed with a skeletal overlay. Corrective feedback should appear as large, readable text overlays that don't obstruct the user's view of themselves.
- **Reward Animation**: The alien hacker fist-bump animation should feel playful and celebratory. Use transparency (alpha ~0.6) so the summary below is still legible.
- **Escalation Screen**: Should feel calm and reassuring, not alarming. Use supportive language and clear CTAs for "Call PT" and "Start Video Call."
- **Overall Tone**: Friendly, supportive, and encouraging — like a knowledgeable friend, not a clinical tool.

---

## 7. Technical Considerations

- **Platform**: iOS (iPhone only), Swift / SwiftUI.
- **HealthKit**: Requires `NSHealthShareUsageDescription` in Info.plist. Request read permissions for `HKCategoryTypeIdentifier.sleepAnalysis` and `HKQuantityTypeIdentifier.activeEnergyBurned`.
- **Pose Estimation**: ZeticAI Melange SDK + Google MediaPipe Pose Estimation. Runs on Apple Neural Engine for performance. All inference is on-device.
- **Camera**: Requires `NSCameraUsageDescription`. Use `AVCaptureSession` to feed frames to the pose model.
- **Twilio**: Use Twilio Voice SDK or REST API to initiate a call. For the demo, this can call a hardcoded number.
- **Zoom**: Use Zoom Meeting SDK for iOS to launch a video call. For the demo, a pre-created meeting link is acceptable.
- **Privacy**: Zero network transmission of video data. Health data stays in HealthKit. This is a core differentiator and must be preserved.
- **Device**: Target iPhone 12+ (A14 Bionic or later) for Neural Engine performance.

---

## 8. Success Metrics

Since this is a hackathon demo, success is measured by:

1. **End-to-end demo completion**: All 3 steps (Context → Supervision → Reward/Escalation) work in a single uninterrupted flow.
2. **Real-time pose feedback**: Corrective feedback appears within 1 second of incorrect form.
3. **Health data adaptation**: The app visibly adjusts the routine when health data indicates low readiness.
4. **Audience reaction**: The demo clearly communicates the privacy-first value proposition ("This camera feed never hits the internet").
5. **Escalation trigger**: The Twilio call / Zoom handoff fires successfully when form checks fail repeatedly.

---

## 9. Open Questions

1. **Twilio / Zoom credentials**: Do we have API keys ready, or do we need to set up free-tier accounts for the demo?
2. **Exercise form thresholds**: What joint angle thresholds define "incorrect form" for each exercise? Do we need a physiotherapist to validate these, or are approximate values acceptable for the hackathon?
3. **ZeticAI Melange SDK access**: Do we have the SDK and license ready for integration, or is there a setup step required?
4. **Demo device**: Which specific iPhone model will be used for the live demo? (Affects Neural Engine performance tuning.)
5. **Hardcoded PT number**: Whose phone number should the Twilio escalation call for the demo?

---

## 10. Implementation State

### What's Already Built (Puneet)

The following is implemented and functional in the `PhysioPal/` source directory:

| Component | Files | Status |
|-----------|-------|--------|
| Shared models | `Models/Exercise.swift`, `ExerciseRoutine.swift`, `HealthReadiness.swift`, `PoseData.swift` | Done |
| Design system | `Utilities/Constants.swift` — all colors, fonts, layout values, thresholds, animation configs | Done |
| Angle calculator | `Utilities/AngleCalculator.swift` — computes joint angles from 3 CGPoints | Done |
| HealthKit service | `Services/HealthKitManager.swift` — sleep + energy queries, readiness assessment | Done |
| Context Engine VM | `ViewModels/ContextEngineViewModel.swift` — loads health data, builds adaptive routine | Done |
| Doctor's Note UI | `Views/ContextEngine/DoctorsNoteCard.swift`, `HealthRecommendationView.swift` | Done |
| Twilio service | `Services/TwilioService.swift` — REST API voice call to PT | Done |
| Zoom service | `Services/ZoomService.swift` — opens Zoom app/web link | Done |
| Escalation VM + UI | `ViewModels/EscalationViewModel.swift`, `Views/Escalation/EscalationView.swift` | Done |
| Home screen | `Views/Home/HomeView.swift` — feature cards, privacy badge, begin session CTA | Done |
| App navigation | `Views/AppFlowView.swift` — coordinates Health Check → Exercise → Reward/Escalation | Done |
| App entry point | `App/PhysioPalApp.swift` — NavigationStack root | Done |
| Config files | `Info.plist` (permissions), `PhysioPal.entitlements` (HealthKit) | Done |

### What Needs to Be Built (Rutuja)

| Component | Files to Create | Description |
|-----------|----------------|-------------|
| Camera + Pose | `Views/Supervision/CameraPreviewView.swift`, `Services/PoseEstimationService.swift` | AVCaptureSession + ZeticAI Melange SDK on-device pose estimation |
| Exercise Evaluator | `Services/ExerciseEvaluator.swift` | Compare PoseFrame joint angles against Exercise.formRules, return FormEvaluation |
| Supervision VM | `ViewModels/SupervisionViewModel.swift` | Process frames, count reps, track streaks, detect failures |
| Supervision UI | `Views/Supervision/ExerciseSessionView.swift`, `PoseOverlayView.swift`, `FeedbackOverlayView.swift` | Camera feed (top 60%), skeleton overlay, feedback pills, rep counter |
| Reward VM | `ViewModels/RewardViewModel.swift` | Session summary data, milestone detection |
| Reward UI | `Views/Reward/RewardAnimationView.swift`, `ExerciseSummaryView.swift` | Alien hacker animation, summary card, milestone badges |

### How Rutuja's Code Connects to Existing Code

1. **Entry point:** `AppFlowView.swift` currently renders `ExerciseSessionPlaceholder` and `RewardPlaceholder`. Rutuja replaces these with her real views. The placeholder shows the exact callback signatures needed:
   - `onComplete: (SessionSummary) -> Void` — call this when the exercise session finishes
   - `onEscalate: () -> Void` — call this when `consecutiveFailures >= 3`

2. **Shared models to use:**
   - `Exercise` and `Exercise.FormRule` — contains per-exercise joint angle thresholds
   - `ExerciseRoutine` and `RoutineExercise` — the routine built by ContextEngineViewModel, passed to the exercise session
   - `PoseFrame` — fill this with landmark data from the pose SDK
   - `SessionSummary` — construct this when exercise completes, pass to `onComplete`
   - `FormEvaluation` and `FormViolation` — output of form checking

3. **Utilities to use:**
   - `AngleCalculator.angle(pointA:vertex:pointC:)` — computes angle between 3 points in degrees
   - `Constants.swift` — all colors (`AppColors`), fonts (`AppFonts`), layout (`AppLayout`), thresholds (`HealthThresholds`), animation durations (`AppAnimation`)

4. **Design system:** All UI must follow `CLAUDE.md` — warm teal/coral/gold palette, 18pt min text, 54pt touch targets, encouraging language (never "wrong"/"failed"), camera feed top 60% with skeleton overlay.
