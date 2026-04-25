# PhysioPal Architecture Guide

This architecture is optimized for a hackathon build where the team needs fast parallel progress, clear ownership, and a stable demo path.[cite:2][cite:57]

## Core design principle

The product should have a **strict separation between core on-device intelligence and optional cloud-connected escalation features** because ZETIC judges explicitly care about that boundary.[cite:75][cite:2]

## Recommended architecture layers

### App layer

Use SwiftUI for navigation and screen composition.[cite:57]

Suggested top-level flow:

1. Home / Start.[cite:2]
2. Readiness / Doctor’s Note.[cite:2]
3. Exercise intro.[cite:2]
4. Live supervision session.[cite:75]
5. Summary / reward.[cite:75]
6. Escalation if needed.[cite:2]

### Service layer

Keep services thin and isolated:[cite:57]

- `HealthKitManager` for sleep and energy reads.[cite:2]
- `PoseEstimationService` for Melange model interaction.[cite:57]
- `ExerciseEvaluator` for threshold checks and rep logic.[cite:2]
- `TwilioService` and `ZoomService` for secondary escalation flows.[cite:2]

### View model layer

View models should translate service outputs into UI state and should not own low-level integration logic.[cite:57]

Recommended view models:

- `ContextEngineViewModel`.[cite:2]
- `SupervisionViewModel`.[cite:2]
- `RewardViewModel`.[cite:2]
- `EscalationViewModel`.[cite:2]

## On-device vs cloud boundary

The project should explicitly enforce this table:

| Responsibility | Layer | Execution location |
|---|---|---|
| Health read and readiness logic | HealthKitManager + ContextEngineViewModel | On-device[cite:75] |
| Pose estimation inference | PoseEstimationService | On-device[cite:75][cite:57] |
| Rule-based form checks | ExerciseEvaluator | On-device[cite:75] |
| Rep counting | SupervisionViewModel | On-device[cite:75] |
| Reward / summary generation | RewardViewModel | On-device[cite:75] |
| PT call / Zoom handoff | Escalation services | Secondary cloud action[cite:75] |

## Independence-friendly development strategy

To let two people work independently, the supervision flow should first be built with a **mock pose stream** instead of waiting for final model integration.[cite:57][cite:2]

This means:

- UI development can proceed immediately.[cite:2]
- Rep counting and feedback can be tested with deterministic values.[cite:2]
- The final Melange integration becomes a swap of the pose provider, not a rewrite of the exercise UI.[cite:57]

## Recommended interface contracts

### Pose provider contract

Create a small abstraction like `PoseProviderProtocol` so the app can switch between:

- `MockPoseProvider` for local UI development, and[cite:2]
- `MelangePoseProvider` for the real model path.[cite:57]

### Escalation contract

Create a simple protocol for escalation actions so the UI can trigger:

- `callPhysiotherapist()`, and[cite:2]
- `startVideoConsultation()`.[cite:2]

This allows a mocked implementation during development and a real Twilio / Zoom-backed implementation later.[cite:2][cite:53]

## Demo reliability rules

For hackathon reliability:

- Seed one low-readiness state and one normal-readiness state.[cite:2]
- Seed one “bad squat” pose sequence and one “good squat” sequence.[cite:2]
- Keep at least one complete end-to-end path working even if Twilio or final model wiring fails.[cite:2][cite:53]
