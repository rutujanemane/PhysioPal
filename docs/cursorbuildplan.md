# Cursor Build Plan for PhysioPal

This plan is designed to maximize the odds of a working submission under hackathon time pressure.[cite:2][cite:57]

## Priority tiers

### P0 — must work

These features define the product and should be finished first:[cite:2][cite:75]

- SwiftUI app shell and navigation.[cite:2]
- Health readiness screen with live or mocked HealthKit input.[cite:2]
- Exercise session screen.[cite:2]
- Pose-based correction loop using mocked or real pose data.[cite:2][cite:57]
- Rep counter and summary screen.[cite:2]
- Clear statement that the camera feed never leaves the device.[cite:75]

### P1 — strong differentiators

These improve competitiveness for ZETIC and healthcare judging:[cite:75][cite:2]

- Real Melange-powered inference wired into the session flow.[cite:57]
- Real readiness-based routine adjustment.[cite:2]
- Escalation trigger after repeated failure.[cite:2]
- Reward animation and strong success state.[cite:2]

### P2 — optional polish

These are useful only if time remains:[cite:2]

- Twilio outbound call integration.[cite:53]
- Zoom launch flow.[cite:2]
- Devpost screenshots and advanced visual polish.[cite:2]

## Recommended implementation order

1. Scaffold project and navigation.[cite:2]
2. Add Melange package and verify SDK setup in isolation.[cite:57][cite:60]
3. Build the readiness screen with mocked health data.[cite:2]
4. Build the session UI with mocked pose data.[cite:2]
5. Implement exercise evaluation logic and rep counting against the mock stream.[cite:2]
6. Build summary and reward screens.[cite:2]
7. Swap in real Melange outputs if ready.[cite:57]
8. Add escalation flow as a secondary path.[cite:2][cite:53]

## Cursor prompting advice

Use Cursor in short, explicit chunks rather than one giant prompt.[cite:57]

Good task sequence:

- “Create SwiftUI file structure and navigation for the PhysioPal flow.”[cite:2]
- “Add a mock HealthKit manager that returns low-readiness and normal-readiness demo states.”[cite:2]
- “Implement a mock pose provider that emits good and bad squat frames for the session screen.”[cite:2]
- “Create an exercise evaluator that turns pose landmarks into one feedback string and rep counts.”[cite:2]
- “Integrate ZETIC Melange package setup into the Xcode project and add a verification service.”[cite:57][cite:60]

## Build traps to avoid

- Do not block the UI on final model integration.[cite:57]
- Do not make cloud services necessary for the main exercise flow.[cite:75]
- Do not attempt too many exercises; two strong demo exercises are enough.[cite:2]
- Do not leave first-run model download untested before judging.[cite:57][cite:60]
- Do not hide the on-device story; it should be visible in both UI copy and verbal demo.[cite:75]
