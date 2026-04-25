## Project Context

**PhysioPal** is a hackathon project (LA Hacks 2026) — a fully on-device iOS physiotherapy app. It supervises patients doing exercises at home using iPhone camera pose estimation, adapts routines based on Apple Health data, and escalates to a human physiotherapist when needed. The target audience is **elderly patients (60–80+)**, so all UI uses large text, generous touch targets, and warm encouraging language. We are competing for **Best UI/UX**.

**Tech stack:** iOS 16+, iPhone only, Swift 6.2, SwiftUI, MVVM architecture.

**Two teammates are building this:**
- **Puneet** — Project setup, shared models, Context Engine (HealthKit + Doctor's Note UI), Escalation (Twilio + Zoom + UI), app navigation. **His work is done.**
- **Rutuja** — Supervision Engine (camera + pose estimation), Exercise Library (form thresholds + evaluation), Reward System (animations + summary). **Her work is pending.**

### App Flow
```
Home → Health Check (reads Apple Health, builds adaptive routine) → Exercise Session (camera + pose estimation + real-time feedback) → Reward Screen (animation + summary)
                                                                           ↓ (3 consecutive form failures)
                                                                      Escalation Screen (call PT via Twilio / Zoom video call)
```

### What's Already Built (Puneet's code — do not modify these files)
- **Shared Models** (`Models/`): `Exercise.swift` (exercise definitions + form rules with joint angle thresholds), `ExerciseRoutine.swift` (routine + session summary), `HealthReadiness.swift` (readiness levels), `PoseData.swift` (pose landmarks + form evaluation structs)
- **Design System** (`Utilities/Constants.swift`): All colors (`AppColors`), fonts (`AppFonts`), layout (`AppLayout`), shadow (`AppShadow`), health thresholds (`HealthThresholds`), animation durations (`AppAnimation`), `Color(hex:)` extension
- **Utilities** (`Utilities/AngleCalculator.swift`): `AngleCalculator.angle(pointA:vertex:pointC:) -> Double` — computes angle in degrees between 3 CGPoints
- **HealthKit** (`Services/HealthKitManager.swift`): Queries sleep + energy, returns `HealthReadiness`
- **Context Engine** (`ViewModels/ContextEngineViewModel.swift`, `Views/ContextEngine/`): Doctor's Note UI with health stats and adaptive routine
- **Escalation** (`Services/TwilioService.swift`, `Services/ZoomService.swift`, `ViewModels/EscalationViewModel.swift`, `Views/Escalation/EscalationView.swift`): Twilio call + Zoom video + reassuring UI
- **Navigation** (`Views/AppFlowView.swift`): Coordinates the full app flow; currently uses `ExerciseSessionPlaceholder` and `RewardPlaceholder` which Rutuja will replace with real views
- **Home** (`Views/Home/HomeView.swift`): Landing screen with feature cards
- **App Entry** (`App/PhysioPalApp.swift`): NavigationStack root
- **Config** (`Info.plist`, `PhysioPal.entitlements`): HealthKit + Camera permissions

### How Rutuja's Code Connects (Integration Points)

1. **Replace placeholders in `AppFlowView.swift`:** The file contains `ExerciseSessionPlaceholder` and `RewardPlaceholder`. Rutuja creates real views (`ExerciseSessionView`, reward screen) with these exact callback signatures:
   - Exercise session receives: `routine: ExerciseRoutine`, `onComplete: (SessionSummary) -> Void`, `onEscalate: () -> Void`
   - Reward screen receives: `summary: SessionSummary`, `onDone: () -> Void`

2. **Use shared models:** `Exercise.formRules` contains per-exercise joint angle thresholds. `PoseFrame.angleBetween(_:_:_:)` computes angles. `SessionSummary` is what the reward screen needs. `FormEvaluation` / `FormViolation` are the output structs for form checking.

3. **Use design system:** Import nothing — `AppColors`, `AppFonts`, `AppLayout`, etc. are all in `Constants.swift`. Follow `CLAUDE.md` for all visual specs.

### Key Design Rules (from CLAUDE.md)
- Camera feed occupies **top 60%** of screen; controls below only
- Skeleton overlay: **4pt teal lines**, **12pt joint dots**
- Feedback pill: **24pt bold white text on black 70% pill**, top-center of camera
- Rep counter: **48pt bold**, bottom-right of camera area
- Never use words: "wrong", "bad", "fail", "error", "incorrect" in user-facing text
- Reward animations: delightful but restrained, **never obscure the results summary**
- All animations auto-dismiss in 2–3s or on tap

---

## Relevant Files

- `PhysioPal/App/PhysioPalApp.swift` - Main app entry point and navigation root
- `PhysioPal/Models/Exercise.swift` - Exercise data model with form parameters and variants
- `PhysioPal/Models/ExerciseRoutine.swift` - Routine model (collection of exercises with reps/sets)
- `PhysioPal/Models/HealthReadiness.swift` - Health readiness assessment model
- `PhysioPal/Models/PoseData.swift` - Pose landmark and joint angle data structures
- `PhysioPal/Views/Home/HomeView.swift` - Home screen / entry point UI
- `PhysioPal/Views/AppFlowView.swift` - Navigation coordinator for the app flow
- `PhysioPal/Views/ContextEngine/HealthRecommendationView.swift` - Health recommendation display screen
- `PhysioPal/Views/ContextEngine/DoctorsNoteCard.swift` - Doctor's note styled card component
- `PhysioPal/Views/Supervision/ExerciseSessionView.swift` - Main exercise session screen
- `PhysioPal/Views/Supervision/CameraPreviewView.swift` - UIViewRepresentable wrapper for AVCaptureSession
- `PhysioPal/Views/Supervision/PoseOverlayView.swift` - Skeletal overlay drawn on camera feed
- `PhysioPal/Views/Supervision/FeedbackOverlayView.swift` - Real-time corrective text overlays
- `PhysioPal/Views/Reward/RewardAnimationView.swift` - Alien hacker fist-bump reward animation
- `PhysioPal/Views/Reward/ExerciseSummaryView.swift` - Post-session summary (reps, accuracy, duration)
- `PhysioPal/Views/Escalation/EscalationView.swift` - Escalation screen with Call PT / Video Call CTAs
- `PhysioPal/ViewModels/ContextEngineViewModel.swift` - ViewModel for health data fetching and readiness logic
- `PhysioPal/ViewModels/SupervisionViewModel.swift` - ViewModel for pose tracking, rep counting, form evaluation
- `PhysioPal/ViewModels/RewardViewModel.swift` - ViewModel for session summary data
- `PhysioPal/ViewModels/EscalationViewModel.swift` - ViewModel for Twilio/Zoom escalation logic
- `PhysioPal/Services/HealthKitManager.swift` - HealthKit queries for sleep and energy data
- `PhysioPal/Services/PoseEstimationService.swift` - ZeticAI Melange SDK integration for on-device pose estimation
- `PhysioPal/Services/ExerciseEvaluator.swift` - Joint angle comparison against exercise thresholds
- `PhysioPal/Services/TwilioService.swift` - Twilio Voice API integration for PT calls
- `PhysioPal/Services/ZoomService.swift` - Zoom Meeting SDK integration for video calls
- `PhysioPal/Utilities/AngleCalculator.swift` - Geometric utility to compute angles between 3 joint points
- `PhysioPal/Utilities/Constants.swift` - App-wide constants (design system colors, fonts, layout, thresholds)
- `PhysioPal/Info.plist` - HealthKit and Camera permission descriptions
- `PhysioPal/PhysioPal.entitlements` - HealthKit capability entitlement
- `PhysioPal/Resources/Fonts/` - Custom handwritten-style font files
- `PhysioPal/Resources/Animations/` - Lottie/sprite assets for reward animation
- `PhysioPal/Resources/Assets.xcassets/` - App icons, colors, and image assets

### Notes

- This is a SwiftUI iOS app targeting iPhone 12+ (iOS 16+), Swift 6.2.
- Use Xcode's built-in test target for unit tests. Run with `Cmd+U` in Xcode or `xcodebuild test` from CLI.
- The two teammates should work on separate feature branches and merge into the main feature branch to avoid conflicts.
- Refer to `CLAUDE.md` for the full UI/UX design system, color palette, typography, and LA Hacks Best UI/UX checklist.

## Team Assignments

### Puneet — Project Setup, Context Engine, Escalation
Owns: Project scaffolding, shared models, HealthKit integration, health recommendation UI, Twilio/Zoom escalation, app navigation flow.

### Rutuja — Supervision Engine, Exercise Library, Rewards
Owns: Camera setup, pose estimation integration, exercise form evaluation, real-time feedback UI, rep counting, reward animation, exercise summary.

## Instructions for Completing Tasks

**IMPORTANT:** As you complete each task, you must check it off in this markdown file by changing `- [ ]` to `- [x]`. This helps track progress and ensures you don't skip any steps.

Example:
- `- [ ] 1.1 Read file` → `- [x] 1.1 Read file` (after completing)

Update the file after completing each sub-task, not just after completing an entire parent task.

## Tasks

### Shared

- [x] 0.0 Create feature branch
  - [x] 0.1 Create and checkout a new branch `feature/physiopal-app` from main

- [x] 1.0 Project setup & scaffolding (shared models, folder structure, Xcode project)
  - [x] 1.1 Create folder structure: `App/`, `Models/`, `Views/` (with sub-folders: Home, ContextEngine, Supervision, Reward, Escalation), `ViewModels/`, `Services/`, `Utilities/`, `Resources/` (Fonts, Animations, Assets.xcassets)
  - [x] 1.2 Create `Constants.swift` with full design system — colors (AppColors), fonts (AppFonts), layout values (AppLayout), shadow config (AppShadow), health thresholds (HealthThresholds), animation durations (AppAnimation), and `Color(hex:)` extension
  - [x] 1.3 Create `Exercise.swift` model — exercise ID, name, description, icon, standard/reduced reps, easier variant ID, form rules with joint triplets and angle ranges, and a static exercise library (deep squats, chair squats, standing leg raises, wall push-ups)
  - [x] 1.4 Create `ExerciseRoutine.swift` — routine with list of RoutineExercise items (target reps, completed reps, correct form reps, consecutive failures, form accuracy), and SessionSummary (total reps, accuracy, formatted duration, isPerfect flag)
  - [x] 1.5 Create `HealthReadiness.swift` — sleep hours, active energy, readiness level enum (normal/moderate/low), user-friendly explanation strings, display labels and icons per level
  - [x] 1.6 Create `PoseData.swift` — PoseLandmark (joint + position + confidence), PoseFrame (landmark lookup + angle calculation), FormEvaluation and FormViolation structs
  - [x] 1.7 Create `AngleCalculator.swift` — compute angle in degrees between three CGPoints using dot product formula
  - [x] 1.8 Create `Info.plist` with `NSHealthShareUsageDescription` and `NSCameraUsageDescription` with user-friendly privacy descriptions
  - [x] 1.9 Create `PhysioPal.entitlements` with HealthKit capability
  - [x] 1.10 Create `PhysioPalApp.swift` app entry point with NavigationStack and tint color
  - [ ] 1.11 Create Xcode project in Xcode GUI (File → New → iOS App, SwiftUI), add all source files, enable HealthKit in Signing & Capabilities

### Puneet

- [x] 2.0 Context Engine — HealthKit integration & readiness evaluation
  - [x] 2.1 Create `HealthKitManager` singleton with `HKHealthStore` instance
  - [x] 2.2 Define read types set: `sleepAnalysis` and `activeEnergyBurned`
  - [x] 2.3 Implement `requestAuthorization()` using async/await — request read-only access for sleep and energy types
  - [x] 2.4 Implement `fetchSleepHours()` — query `HKCategorySample` for last 24 hours, filter for asleep states (unspecified, core, deep, REM), sum durations, return hours
  - [x] 2.5 Implement `fetchActiveEnergy()` — query `HKStatisticsQuery` with cumulative sum for today's `activeEnergyBurned`, return kcal
  - [x] 2.6 Implement `assessReadiness()` — call requestAuthorization, then fetch sleep and energy concurrently with `async let`, construct HealthReadiness, fall back to `.noHealthData` on error
  - [x] 2.7 Write warm, encouraging readiness explanation strings for each level — low ("let's take it easy"), moderate ("I've made a few adjustments"), normal ("you're looking well-rested")

  

- [x] 3.0 Context Engine — Health recommendation UI (Doctor's Note screen)
  - [x] 3.1 Create `ContextEngineViewModel` — `@Published` readiness, routine, isLoading, hasCompleted; `loadHealthAndBuildRoutine()` calls assessReadiness and builds routine
  - [x] 3.2 Implement routine builder — iterate exercise library, swap to easier variants and reduce reps when readiness is low/moderate, return ExerciseRoutine
  - [x] 3.3 Create `DoctorsNoteCard` — header with readiness icon (animated pulse) and "Today's Note" title, handwritten-font explanation text, exercise list with icons and rep counts, fade-in entrance animation
  - [x] 3.4 Create `HealthRecommendationView` — time-of-day greeting ("Good morning/afternoon/evening"), DoctorsNoteCard, optional sleep stat row, optional energy stat row, "Start My Routine" primary CTA
  - [x] 3.5 Add loading state with pulsing `heart.text.clipboard.fill` icon and "Checking how you're feeling today..." text
  - [x] 3.6 Add health stat rows — icon in colored rounded-rect background, label, value, colored by threshold (green if ok, coral if low)
  - [x] 3.7 Add haptic feedback (`.impact(.medium)`) on "Start My Routine" button tap

- [x] 4.0 Escalation — Twilio voice call integration
  - [x] 4.1 Create `TwilioService` singleton with account SID, auth token, from-number from config
  - [x] 4.2 Implement `callPhysiotherapist(ptPhoneNumber:)` — POST to Twilio REST API with Basic auth, TwiML voice message, URL-encoded form body
  - [x] 4.3 Parse response JSON for call SID, return `CallResult` with status
  - [x] 4.4 Create `TwilioError` enum (invalidURL, invalidResponse, apiError with status code and message) with user-friendly `errorDescription`
  - [x] 4.5 Create `TwilioConfig` enum with placeholder credentials (accountSID, authToken, fromNumber, ptPhoneNumber) — marked for replacement before demo

- [x] 5.0 Escalation — Zoom video call integration
  - [x] 5.1 Create `ZoomService` singleton with `openVideoCall()` method
  - [x] 5.2 Attempt to open Zoom app deep link first; fall back to web URL if Zoom not installed
  - [x] 5.3 Create `ZoomConfig` enum with placeholder meeting link and web fallback link — marked for replacement before demo

- [x] 6.0 Escalation — Escalation UI screen
  - [x] 6.1 Create `EscalationViewModel` — `@Published` callState (idle/calling/connected/failed), showError, errorMessage; `callPhysiotherapist()` async method with haptic feedback on success/failure
  - [x] 6.2 Implement `startVideoCall()` — calls ZoomService with haptic feedback
  - [x] 6.3 Create `EscalationView` hero section — large `person.2.fill` icon in coral circle with pulse animation
  - [x] 6.4 Create reassuring message section — "Let's get some help" title, warm body text ("It looks like you could use a hand... no worries at all")
  - [x] 6.5 Create "Call My Physiotherapist" primary button — coral filled, shows ProgressView when calling, updates label per state (Connecting.../Call Placed/Try Again)
  - [x] 6.6 Create "Start Video Call" secondary button — outlined in teal with video icon
  - [x] 6.7 Create "Go back to exercises" text-only dismiss button
  - [x] 6.8 Add connected confirmation banner — green checkmark + "Call placed — your physiotherapist should ring shortly" with scale+opacity transition
  - [x] 6.9 Add error alert with "Try Again" and "Go Back" options, reassuring copy: "Don't worry — you can also try the video call option"

### Rutuja

- [ ] 7.0 Supervision Engine — Camera setup & pose estimation integration
  - [ ] 7.1 Create `CameraPreviewView` as UIViewRepresentable wrapping `AVCaptureSession` with `AVCaptureVideoPreviewLayer`
  - [ ] 7.2 Configure `AVCaptureSession` with back camera input and `AVCaptureVideoDataOutput` at 30fps
  - [ ] 7.3 Implement camera permission request flow — handle `.authorized`, `.denied`, `.restricted` states with user-friendly messages
  - [ ] 7.4 Integrate ZeticAI Melange SDK — import framework, initialize on-device pose model
  - [ ] 7.5 Create `PoseEstimationService` — process each camera frame buffer, run inference, return `PoseFrame` with landmark positions and confidence scores
  - [ ] 7.6 Map MediaPipe pose landmarks to app's `JointID` enum (shoulders, elbows, wrists, hips, knees, ankles, nose)
  - [ ] 7.7 Verify zero network calls during inference — all processing on Apple Neural Engine

- [ ] 8.0 Exercise Library — Exercise definitions & form thresholds
  - [ ] 8.1 Validate and refine joint angle thresholds for deep squats (knee 70–110°, hip-to-knee 60–100°) using real pose data
  - [ ] 8.2 Validate thresholds for chair-assisted squats (knee 80–120°)
  - [ ] 8.3 Validate thresholds for standing leg raises (knee 150–180°, torso 140–180°)
  - [ ] 8.4 Validate thresholds for wall push-ups (elbow 70–120°, body line 160–180°)
  - [ ] 8.5 Create `ExerciseEvaluator` service — accept a `PoseFrame` and `Exercise`, compare detected joint angles against each FormRule, return `FormEvaluation` with list of violations
  - [ ] 8.6 Implement rep detection logic — detect transition from standing → squat → standing (or equivalent per exercise) using angle thresholds to count one completed rep

- [ ] 9.0 Supervision Engine — Real-time form evaluation & feedback UI
  - [ ] 9.1 Create `SupervisionViewModel` — `@Published` currentExercise, repCount, correctRepCount, consecutiveFailures, currentStreak, formFeedback; process each PoseFrame through ExerciseEvaluator
  - [ ] 9.2 Create `PoseOverlayView` — draw skeletal lines (4pt stroke, teal `#2A9D8F`) connecting joint pairs, filled joint dots (12pt diameter), laid over camera feed
  - [ ] 9.3 Highlight joints with violations in red (`#E63946`) on skeleton overlay, keep correct joints in teal
  - [ ] 9.4 Create `FeedbackOverlayView` — semi-transparent pill (`background: black 70%, white text, 24pt bold`) at top-center of camera feed, shows correction message only when form is incorrect
  - [ ] 9.5 Add rep counter display — 48pt bold numeral in bottom-right of camera area
  - [ ] 9.6 Add green pulse animation on rep counter + `.success` haptic when a correct rep completes
  - [ ] 9.7 Add subtle teal confetti burst (20–30 particles, fade in <1s) behind rep counter on 3+ correct rep streak
  - [ ] 9.8 Add exercise-complete transition — camera feed blurs, large checkmark scales up with bounce, transitions to reward screen
  - [ ] 9.9 Create `ExerciseSessionView` — compose CameraPreviewView (top 60%), PoseOverlayView, FeedbackOverlayView, rep counter; controls below camera feed only
  - [ ] 9.10 Wire escalation trigger — when `consecutiveFailures >= 3` on same exercise, call `onEscalate` callback

- [ ] 10.0 Reward System — Reward animation & exercise summary screen
  - [ ] 10.1 Create `RewardViewModel` — accept `SessionSummary`, compute display values (total reps, accuracy %, formatted duration, isPerfect, milestone checks)
  - [ ] 10.2 Create `ExerciseSummaryView` — white card with large text: reps completed, form accuracy %, session duration; styled per design system
  - [ ] 10.3 Create `RewardAnimationView` — display 5 translucent alien hacker characters (alpha 0.6) overlaying the summary; characters should not obscure the stats
  - [ ] 10.4 Implement fist bump animation for alien characters — use Lottie if asset available, else SwiftUI spring animation with scale + rotation
  - [ ] 10.5 Add "Perfect Form" gold shimmer badge — gold border shimmer on summary card + star icon when accuracy is 100%
  - [ ] 10.6 Add first-session milestone — "Welcome to your recovery journey" card with gentle scale-up animation
  - [ ] 10.7 Add streak milestone animation — flame/streak icon with count, scale + rotation animation
  - [ ] 10.8 Add rep milestone animation (50th, 100th lifetime rep) — rep counter burst scales 1.5x with radiating teal rings
  - [ ] 10.9 Ensure all celebration animations auto-dismiss after 2–3 seconds or on tap (whichever comes first)
  - [ ] 10.10 Add "Done" / "Back to Home" primary button at bottom of screen

### Shared (Integration)

- [x] 11.0 App navigation flow & end-to-end integration
  - [x] 11.1 Create `AppFlowView` with `AppFlowStep` enum: `.healthCheck`, `.exercise(routine)`, `.reward(summary)`, `.escalation`
  - [x] 11.2 Wire HealthRecommendationView → ExerciseSession transition on "Start My Routine" tap
  - [x] 11.3 Wire ExerciseSession → Reward transition on exercise completion
  - [x] 11.4 Wire ExerciseSession → Escalation transition on consecutive failures
  - [x] 11.5 Wire Escalation → back to exercise session on dismiss
  - [x] 11.6 Create `HomeView` — hero section (app icon + name), 3 feature cards (health check, real-time guidance, privacy), privacy badge, "Begin Today's Session" NavigationLink
  - [x] 11.7 Create `BackButton` component — chevron + "Back" text, teal color, haptic on tap
  - [x] 11.8 Create placeholder views for Rutuja's screens (ExerciseSessionPlaceholder with "Simulate Completion" and "Simulate Escalation" buttons, RewardPlaceholder with "Done" button)

- [ ] 12.0 Polish, demo prep & testing on device
  - [ ] 12.1 Create Xcode project and add all source files if not already done (see 1.11)
  - [ ] 12.2 Build and run on physical iPhone 12+ device — resolve any compile errors
  - [ ] 12.3 Test HealthKit permission prompt — verify it appears with friendly description, data reads correctly
  - [ ] 12.4 Test camera permission prompt — verify it appears with privacy-focused description
  - [ ] 12.5 Test full happy path: Home → Health Check → Exercise → Reward → Home
  - [ ] 12.6 Test escalation path: Exercise → Escalation → Call PT → back to exercise
  - [ ] 12.7 Replace placeholder Twilio credentials in `TwilioConfig` — test real call
  - [ ] 12.8 Replace placeholder Zoom meeting link in `ZoomConfig` — test video call launch
  - [ ] 12.9 Grep codebase for negative language ("wrong", "bad", "fail", "error", "incorrect") in user-facing strings — replace with encouraging alternatives
  - [ ] 12.10 Screenshot all screens side-by-side — verify visual consistency (same colors, spacing, fonts, icon style)
  - [ ] 12.11 Validate each screen against LA Hacks Best UI/UX checklist (see CLAUDE.md)
  - [ ] 12.12 Prepare demo script: happy path flow (normal readiness) + low readiness flow + escalation flow
