# PhysioPal Integration Notes

## Current Pose Architecture

- `VisionPoseProvider` is now the default realtime landmark source in `SupervisionViewModel`.
- Apple Vision (`VNDetectHumanBodyPoseRequest`) drives body joints for rep counting and form checks.
- `ExerciseSessionView` renders camera preview from the provider-owned `AVCaptureSession` when available.
- Existing `MelangePoseProvider` and Melange verification/config files remain in the project for parallel AI work and future model integrations.

## Why This Split

- The currently deployed Melange pose model in this repo outputs detector tensors, not directly usable 33-body-landmark frames for form-angle rules.
- Apple Vision provides stable body landmarks on-device today, which is the fastest demo-safe path.
- Keeping Melange integrated preserves hackathon scope for additional on-device AI features (coach/assistant features, future model swaps).

## Replacement / Merge Guidance

- If Puneet merges a shared pose provider abstraction, keep these contracts:
  - `PoseProviderProtocol.start(onFrame:)`
  - `PoseProviderProtocol.stop()`
  - Optional `PoseProviderProtocol.previewSession`
- If a Melange landmark model becomes available later:
  - Keep `VisionPoseProvider` as fallback.
  - Switch default provider in `SupervisionViewModel` only after validating joint mapping and confidence behavior against `Exercise.formRules`.

## Device Notes

- Camera permission is requested by `VisionPoseProvider` at runtime.
- Real pose tracking requires a physical iPhone.
