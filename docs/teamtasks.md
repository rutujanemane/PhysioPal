# Team Task Split for PhysioPal

This task split is designed for **independent parallel work** with minimal blocking between teammates.[cite:2][cite:57]

## Shared rules

- Use separate feature branches and merge into a common integration branch.[cite:2]
- Keep mocked data paths available until the real integrations are stable.[cite:2][cite:57]
- Update checklist state as each subtask is completed.[cite:2]

## Puneet — app shell, health, escalation

Puneet owns the branch that can still produce a coherent demo even if the supervision engine is only partially integrated.[cite:2]

### Tasks

- [ ] Create project scaffolding, shared models, and navigation shell.[cite:2]
- [ ] Implement `HealthKitManager` with mocked fallback values for demo stability.[cite:2]
- [ ] Implement `HealthReadiness` logic and routine adjustment rules.[cite:2]
- [ ] Build `HealthRecommendationView` and `DoctorsNoteCard`.[cite:2]
- [ ] Build `EscalationView` and `EscalationViewModel`.[cite:2]
- [ ] Add a Zoom deep-link fallback path first.[cite:2]
- [ ] Add Twilio integration only after the primary app flow is stable.[cite:53]
- [ ] Wire navigation across Home → Recommendation → Session → Summary / Escalation.[cite:2]

## Rutuja — session loop, feedback, reward

Rutuja owns the branch that can still demo a complete exercise session using mocked pose streams before final Melange wiring is done.[cite:57][cite:2]

### Tasks

- [ ] Implement exercise definitions, variants, and thresholds.[cite:2]
- [ ] Build `ExerciseSessionView` shell.[cite:2]
- [ ] Build `CameraPreviewView` and `PoseOverlayView` UI layers.[cite:2]
- [ ] Build `FeedbackOverlayView` for live corrective messages.[cite:2]
- [ ] Implement a `MockPoseProvider` for deterministic session testing.[cite:2]
- [ ] Build `ExerciseEvaluator` and rep counting logic.[cite:2]
- [ ] Build `RewardAnimationView` and `ExerciseSummaryView`.[cite:2]
- [ ] After UI flow is stable, swap mock pose data for real Melange outputs.[cite:57]

## Shared integration tasks

- [ ] Replace mocked readiness with live HealthKit if permissions are available.[cite:2]
- [ ] Replace mocked pose provider with Melange-backed provider.[cite:57]
- [ ] Connect repeated failure detection to escalation trigger.[cite:2]
- [ ] Test on physical iPhone and pre-warm the model cache before demo.[cite:57][cite:60]
- [ ] Prepare one strong end-to-end demo script with low-readiness and success/failure paths.[cite:2]
