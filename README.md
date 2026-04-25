# PhysioPal — The Digital Physiotherapist

> Your recovery companion. Built for [LA Hacks 2026](https://lahacks.com).

PhysioPal is a fully on-device iOS app that bridges the **"Supervision Gap"** in physical therapy. It watches your exercise form in real-time using your iPhone camera, adapts your routine based on your health data, and connects you with your physiotherapist when you need human help — all while keeping your data completely private.

## Features

**Smart Health Check** — Reads your sleep and energy data from Apple Health and adjusts your exercise routine. Tired? PhysioPal automatically gives you easier exercises with fewer reps.

**Real-Time Form Correction** — On-device pose estimation tracks your body during exercises and gives gentle, immediate feedback when your form needs adjustment. No cloud, no latency, no privacy concerns.

**Adaptive Exercise Library** — Pre-defined exercises (squats, chair-squats, leg raises, wall push-ups) with automatic difficulty scaling based on your daily readiness.

**Gamified Rewards** — Celebratory animations, perfect-form badges, streak milestones, and rep achievements keep you motivated throughout recovery.

**Seamless Escalation** — If you're struggling with an exercise, PhysioPal connects you to your physiotherapist via phone call (Twilio) or video call (Zoom) with one tap.

**100% Private** — All pose estimation runs on Apple's Neural Engine. Your camera feed never leaves your iPhone. Period.

## Target Audience

Elderly patients (60–80+) doing physiotherapy exercises at home, supervised remotely by a physiotherapist. Every UI decision is optimized for this audience: large text (18pt+), generous touch targets (54pt+), linear navigation, warm encouraging language, and no jargon.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Platform | iOS 16+, iPhone only |
| Language | Swift 6.2, SwiftUI |
| Architecture | MVVM |
| Health Data | Apple HealthKit (sleep, active energy) |
| Pose Estimation | ZeticAI Melange SDK + Google MediaPipe |
| AI Inference | Apple Neural Engine (fully on-device) |
| Voice Calls | Twilio REST API |
| Video Calls | Zoom Meeting SDK / deep link |
| Design System | SF Pro Rounded, warm teal/coral/gold palette |

## App Flow

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Home Screen │────▶│  Health Check     │────▶│  Exercise Session │────▶│ Reward Screen │
│              │     │  (Doctor's Note)  │     │  (Camera + Pose)  │     │ (Summary)    │
└─────────────┘     └──────────────────┘     └────────┬─────────┘     └──────────────┘
                                                       │ 3 failures
                                                       ▼
                                              ┌──────────────────┐
                                              │ Escalation Screen │
                                              │ (Call PT / Zoom)  │
                                              └──────────────────┘
```

## Project Structure

```
PhysioPal/
├── CLAUDE.md                          # UI/UX design system, coding guidelines, judging checklist
├── physiopal.md                       # Project overview and current state
├── tasks/
│   ├── prd-physiopal.md               # Product Requirements Document
│   └── tasks-physiopal.md             # Task list with sub-tasks and progress tracking
│
└── PhysioPal/                         # iOS app source code
    ├── App/
    │   └── PhysioPalApp.swift         # App entry point (NavigationStack)
    ├── Models/
    │   ├── Exercise.swift             # Exercise model + static library (4 exercises)
    │   ├── ExerciseRoutine.swift      # Routine, RoutineExercise, SessionSummary
    │   ├── HealthReadiness.swift      # Readiness assessment (normal/moderate/low)
    │   └── PoseData.swift             # PoseLandmark, PoseFrame, FormEvaluation
    ├── Views/
    │   ├── Home/
    │   │   └── HomeView.swift         # Landing screen with feature cards
    │   ├── AppFlowView.swift          # Navigation coordinator (health→exercise→reward/escalation)
    │   ├── ContextEngine/
    │   │   ├── HealthRecommendationView.swift  # Health check screen
    │   │   └── DoctorsNoteCard.swift           # Doctor's note card component
    │   ├── Supervision/               # ⬅ Rutuja's screens (to be built)
    │   ├── Reward/                    # ⬅ Rutuja's screens (to be built)
    │   └── Escalation/
    │       └── EscalationView.swift   # Call PT / Video call screen
    ├── ViewModels/
    │   ├── ContextEngineViewModel.swift    # Health data + routine building
    │   ├── EscalationViewModel.swift      # Twilio/Zoom call state
    │   ├── SupervisionViewModel.swift     # ⬅ Rutuja (to be built)
    │   └── RewardViewModel.swift          # ⬅ Rutuja (to be built)
    ├── Services/
    │   ├── HealthKitManager.swift         # HealthKit queries
    │   ├── TwilioService.swift            # Twilio voice call API
    │   ├── ZoomService.swift              # Zoom meeting link opener
    │   ├── PoseEstimationService.swift    # ⬅ Rutuja (to be built)
    │   └── ExerciseEvaluator.swift        # ⬅ Rutuja (to be built)
    ├── Utilities/
    │   ├── Constants.swift            # Design system (colors, fonts, layout, thresholds)
    │   └── AngleCalculator.swift      # Joint angle computation
    ├── Resources/
    │   ├── Assets.xcassets/
    │   ├── Fonts/
    │   └── Animations/
    ├── Info.plist                      # HealthKit + Camera permission descriptions
    └── PhysioPal.entitlements         # HealthKit capability
```

## Setup

### Prerequisites
- Xcode 16+ with iOS 16 SDK
- iPhone 12 or later (A14 Bionic+) for Neural Engine pose estimation
- Apple Developer account (for HealthKit entitlement)
- ZeticAI Melange SDK license

### Getting Started

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd PhysioPal
   git checkout feature/physiopal-app
   ```

2. Create the Xcode project:
   - Open Xcode → File → New Project → iOS App (SwiftUI, Swift)
   - Name it "PhysioPal"
   - Drag the `PhysioPal/` source folder into the project
   - In Signing & Capabilities, add **HealthKit**

3. Configure API credentials:
   - `PhysioPal/Services/TwilioService.swift` → Replace `TwilioConfig` placeholders with your Twilio account SID, auth token, and phone numbers
   - `PhysioPal/Services/ZoomService.swift` → Replace `ZoomConfig` placeholders with your Zoom meeting link

4. Build and run on a physical iPhone (HealthKit and camera require a real device).

## Team

| Person | Role | Owns |
|--------|------|------|
| **Puneet Bajaj** | Setup + Context Engine + Escalation | Shared models, HealthKit, Doctor's Note UI, Twilio/Zoom, navigation |
| **Rutuja** | Supervision Engine + Rewards | Camera, pose estimation, form evaluation, feedback UI, reward animations |

## Design System

See [`CLAUDE.md`](CLAUDE.md) for the complete UI/UX design system including:
- Color palette (warm teal/coral/gold)
- Typography (SF Pro Rounded, 18pt minimum)
- Layout rules (54pt touch targets, single-column, linear nav)
- Animation specifications (exercise feedback, reward celebrations, milestones)
- Accessibility requirements (VoiceOver, Dynamic Type, Reduce Motion)
- LA Hacks Best UI/UX judging checklist

## License

Hackathon project — LA Hacks 2026.
