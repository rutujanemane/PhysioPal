## Relevant Files

- `PhysioPal/App/PhysioPalApp.swift` - Main app entry point and navigation root
- `PhysioPal/Models/Exercise.swift` - Exercise data model with form parameters and variants
- `PhysioPal/Models/ExerciseRoutine.swift` - Routine model (collection of exercises with reps/sets)
- `PhysioPal/Models/HealthReadiness.swift` - Health readiness assessment model
- `PhysioPal/Models/PoseData.swift` - Pose landmark and joint angle data structures
- `PhysioPal/Views/Home/HomeView.swift` - Home screen / entry point UI
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
- `PhysioPal/Utilities/Constants.swift` - App-wide constants (thresholds, API keys, colors)
- `PhysioPal/Resources/Fonts/` - Custom handwritten-style font files
- `PhysioPal/Resources/Animations/` - Lottie/sprite assets for reward animation
- `PhysioPal/Resources/Assets.xcassets/` - App icons, colors, and image assets

### Notes

- This is a SwiftUI iOS app targeting iPhone 12+ (iOS 16+).
- Use Xcode's built-in test target for unit tests. Run with `Cmd+U` in Xcode or `xcodebuild test` from CLI.
- The two teammates should work on separate feature branches and merge into the main feature branch to avoid conflicts.

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

- [ ] 0.0 Create feature branch
- [ ] 1.0 Project setup & scaffolding (shared models, folder structure, Xcode project)

### Puneet

- [ ] 2.0 Context Engine — HealthKit integration & readiness evaluation
- [ ] 3.0 Context Engine — Health recommendation UI (Doctor's Note screen)
- [ ] 4.0 Escalation — Twilio voice call integration
- [ ] 5.0 Escalation — Zoom video call integration
- [ ] 6.0 Escalation — Escalation UI screen

### Rutuja

- [ ] 7.0 Supervision Engine — Camera setup & pose estimation integration
- [ ] 8.0 Exercise Library — Exercise definitions & form thresholds
- [ ] 9.0 Supervision Engine — Real-time form evaluation & feedback UI
- [ ] 10.0 Reward System — Reward animation & exercise summary screen

### Shared (Integration)

- [ ] 11.0 App navigation flow & end-to-end integration
- [ ] 12.0 Polish, demo prep & testing on device
