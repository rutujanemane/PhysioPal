# PhysioPal — The Digital Physiotherapist

**Your recovery companion**

## What This Is

PhysioPal is an iOS app being built for **LA Hacks 2026** (hackathon, 1–2 day build). It is a fully on-device digital physiotherapist that supervises patients doing exercises at home, using their iPhone camera for real-time form correction — with **zero cloud dependency** for privacy.

## The Problem

Physical therapy fails because of the **"Supervision Gap."** A physiotherapist prescribes a routine, but the patient performs it at home unsupervised, often with incorrect form, risking further injury. Continuous live monitoring is too expensive. Cloud-based AI cameras raise serious privacy concerns, especially for elderly patients.

## The Solution

PhysioPal bridges this gap with three engines:

### 1. Context Engine (Apple Health Integration)
- Reads **sleep** and **active energy** from HealthKit on launch
- Evaluates patient's physical readiness (normal / moderate / low)
- Adjusts the exercise routine automatically — reduces reps, swaps in easier variants
- Displays the recommendation in a **handwritten "doctor's note" style** UI
- Example: Only 4 hours of sleep → deep squats become assisted chair-squats, 15 reps become 10

### 2. Supervision Engine (On-Device Pose Estimation)
- Uses iPhone camera + **ZeticAI Melange SDK** + **Google MediaPipe** for real-time pose estimation
- Runs entirely on-device via **Apple Neural Engine** — the camera feed **never leaves the phone**
- Tracks skeletal joint positions, computes joint angles, compares against per-exercise thresholds
- Provides immediate corrective feedback: "Let's adjust your back a little"
- Counts reps with correct form, tracks streaks
- Triggers escalation after 3 consecutive failed form checks

### 3. Handoff & Reward
- **Reward (success):** Celebratory animation (5 translucent alien hacker characters, fist bump), exercise summary (reps, accuracy %, duration), milestone badges (perfect form, streaks)
- **Escalation (repeated failure):** Calm, reassuring screen that connects the patient to their physiotherapist via **Twilio voice call** or **Zoom video call**

## Target Audience

**Elderly patients (60–80+)** recovering from injury, working with a physiotherapist. The physiotherapist prescribes exercises; PhysioPal supervises execution between appointments. The UI is designed for large text, generous touch targets, simple linear navigation, and warm encouraging language.

## Core Value Proposition

- Real-time supervised exercise at home
- Fully private — all AI runs on-device, no video data leaves the phone
- Adaptive routines based on daily health data
- Seamless escalation to a human physiotherapist when needed

## App Flow

```
Home Screen → Health Check (Context Engine) → Exercise Session (Supervision Engine) → Reward Screen
                                                        ↓ (3 consecutive failures)
                                                   Escalation Screen → Call PT / Video Call
```

## Team

| Person | Owns |
|--------|------|
| **Puneet** | Project setup, shared models, Context Engine (HealthKit + Doctor's Note UI), Escalation (Twilio + Zoom + UI), app navigation |
| **Rutuja** | Supervision Engine (camera + pose estimation), Exercise Library (form thresholds + evaluation), Reward System (animations + summary) |

## Key Technical Decisions

- **Platform:** iOS 16+, iPhone only, Swift/SwiftUI, MVVM architecture
- **Pose Estimation:** ZeticAI Melange SDK + Google MediaPipe, all on Apple Neural Engine
- **Privacy:** Zero network transmission of video or health data
- **Design System:** Warm teal/coral/gold palette, SF Pro Rounded, 18pt min text, 54pt touch targets — see `CLAUDE.md` for full spec
- **Judging Criteria:** LA Hacks 2026 "Best UI/UX" — see checklist in `CLAUDE.md`

## Repository Structure

```
PhysioPal/
├── CLAUDE.md                    ← UI/UX design system + coding guidelines
├── physiopal.md                 ← This file (project overview)
├── tasks/
│   ├── prd-physiopal.md         ← Full PRD with functional requirements
│   └── tasks-physiopal.md       ← Task list with sub-tasks + progress tracking
└── PhysioPal/                   ← iOS app source code
    ├── App/                     ← App entry point
    ├── Models/                  ← Shared data models
    ├── Views/                   ← SwiftUI views (by feature)
    ├── ViewModels/              ← MVVM ViewModels
    ├── Services/                ← HealthKit, Twilio, Zoom, Pose Estimation
    ├── Utilities/               ← AngleCalculator, Constants (design system)
    ├── Resources/               ← Fonts, animations, assets
    ├── Info.plist               ← Permission descriptions
    └── PhysioPal.entitlements   ← HealthKit capability
```

## Current State (as of April 2026)

**Puneet's work is complete.** The following is built and functional:
- All shared models (Exercise, ExerciseRoutine, HealthReadiness, PoseData)
- Full design system in Constants.swift (colors, fonts, layout, thresholds, animations)
- HealthKit integration (sleep + energy queries, readiness assessment)
- Context Engine UI (Doctor's Note card, health recommendation screen with greeting + stats)
- Twilio voice call service + Zoom video call service
- Escalation UI (reassuring messaging, call/video buttons with state management)
- Home screen, app navigation flow (AppFlowView), back button component
- Placeholder views for Rutuja's screens with simulate buttons for testing

**Rutuja's work is pending.** She needs to build:
- Camera setup + ZeticAI Melange SDK pose estimation integration
- Exercise form evaluation (ExerciseEvaluator service)
- Real-time supervision UI (skeleton overlay, feedback pills, rep counter)
- Reward system (alien hacker animation, exercise summary, milestone celebrations)

See `tasks/tasks-physiopal.md` for detailed sub-tasks.
