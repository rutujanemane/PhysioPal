# PhysioPal — Development Guide

## Project Overview

PhysioPal is an on-device iOS physiotherapy app (SwiftUI, iPhone only). See `physiopal.md` for the full concept and `tasks/prd-physiopal.md` for the PRD.

## UI/UX Design System

### Primary Audience: Elderly Users (60–80+)

Every design decision must pass this test: **"Can a 70-year-old with reading glasses use this without hesitation?"**

### Typography

- **Minimum body text size: 18pt.** No exceptions.
- **Primary headings: 28–34pt, bold.** Screen titles must be instantly scannable.
- **Button labels: 20pt, semibold.**
- Use **SF Pro Rounded** as the primary typeface — it's warmer and more approachable than SF Pro for elderly users.
- The Doctor's Note screen uses a **handwritten-style font** (e.g., Bradley Hand or a custom script font) at **22pt minimum**.
- Line spacing: **1.5x** minimum for all body text — cramped text causes eye strain.
- Never use light/thin font weights. **Regular is the minimum weight** for any text.

### Color Palette

Use a **warm, calming** palette — not clinical white, not overwhelming neon.

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Background | Warm Off-White | `#FAF8F5` | All screen backgrounds |
| Surface | Soft Cream | `#F5F0EB` | Cards, containers |
| Primary | Deep Teal | `#2A9D8F` | CTAs, active states, nav highlights |
| Primary Dark | Forest Teal | `#1A7A6F` | Pressed states |
| Secondary | Warm Coral | `#E76F51` | Alerts, escalation, important notices |
| Accent | Soft Gold | `#E9C46A` | Rewards, achievements, progress |
| Text Primary | Charcoal | `#2D3436` | Headings, body text |
| Text Secondary | Warm Gray | `#636E72` | Captions, secondary info |
| Success | Gentle Green | `#52B788` | Correct form feedback |
| Error | Soft Red | `#E63946` | Incorrect form feedback |

- **Contrast ratio must be 4.5:1 minimum** (WCAG AA) for all text. Aim for 7:1 (AAA) wherever possible.
- Never convey information through color alone — always pair with icons or text labels.

### Layout & Spacing

- **Generous whitespace everywhere.** When in doubt, add more padding.
- Minimum touch target: **54x54pt** (Apple HIG says 44pt — we go bigger for elderly hands).
- Spacing between interactive elements: **minimum 16pt** to prevent mis-taps.
- Screens should have **no more than 3 primary actions visible** at any time.
- Use **single-column layouts** — no side-by-side buttons or complex grids.
- Content padding from screen edges: **24pt** minimum.
- Card border radius: **16pt** for a soft, friendly feel.

### Navigation & Interaction

- **Linear flow only.** No tab bars, no hamburger menus, no hidden navigation. The app is a guided journey: Home → Health Check → Exercise → Reward/Escalation.
- Every screen has a **single, obvious primary action** — one big button at the bottom.
- Back navigation via a large, clearly labeled back button (not just a chevron — include "Back" text).
- **No swipe gestures as the only way to navigate.** Every action must be achievable with a simple tap.
- Use **smooth, subtle animations** (0.3–0.5s duration) for transitions — no jarring cuts, no flashy effects that could disorient.
- Loading states should use gentle pulsing animations, never spinners that cause anxiety.

### Buttons

- **Primary buttons**: Full-width, 56pt height minimum, 16pt corner radius, filled with Primary color, white text 20pt semibold.
- **Secondary buttons**: Full-width, 56pt height, outlined with 2pt border, transparent fill.
- **Destructive/Escalation buttons**: Warm Coral fill, white text, same sizing.
- Buttons must have visible **pressed states** (darken by 15%) — elderly users need confirmation their tap registered.
- Add subtle **haptic feedback** (`.impact(.medium)`) on all button taps.

### Iconography

- Use **SF Symbols** at **28pt minimum**.
- Always pair icons with text labels — never icon-only buttons.
- Use **filled** variants of SF Symbols (not outline) for better visibility.

### Cards & Containers

- White (`#FFFFFF`) cards on the off-white background for clear visual separation.
- **Soft shadow**: `color: black 8%, x: 0, y: 4, blur: 12` — enough to lift, not enough to distract.
- Inner padding: **20pt** minimum.
- Cards should have **clear visual hierarchy**: title (bold, large), supporting text (regular, smaller), action.

### Camera / Supervision Screen

- The camera feed should occupy the **top 60%** of the screen.
- Skeletal overlay: use **thick lines (4pt)** in bright Teal so they're visible against any background.
- Joint dots: **12pt diameter**, filled circles.
- Corrective feedback text: **24pt bold**, displayed in a semi-transparent pill (`background: black 70%, white text`) positioned at the top center of the camera feed. Must be readable against any scene.
- Rep counter: **large numeral (48pt bold)** in the bottom-right of the camera area.
- Keep controls below the camera feed — never overlay interactive elements on the video.
- **No clutter on the camera screen.** Only show: skeleton overlay, rep counter, and feedback pill. Nothing else competes for attention.
- Feedback appears **only at the right moment** — when form is wrong or a rep completes. Don't show persistent "you're doing great" text that becomes noise.
- The skeleton/pose overlay must be **intuitive at a glance** — a user who has never seen pose estimation should immediately understand "that's me, those are my joints."

#### Real-Time Exercise Animations & Feedback

- **Correct rep completed**: brief green pulse around the rep counter + gentle haptic (`.success`). The counter increments with a spring animation (`interpolatingSpring(stiffness: 200, damping: 15)`).
- **Form correction needed**: the specific body part highlights in Soft Red on the skeleton overlay. A directional arrow or guide line shows the correction direction (e.g., arrow pointing "straighten" along the spine). The feedback pill slides in from top with text like "Let's adjust your back a little."
- **Streak of 3+ correct reps**: subtle confetti-like particle burst (small, teal-colored dots that fade in 0.8s) behind the rep counter — rewarding but not distracting from the exercise.
- **Exercise complete**: smooth transition — camera feed fades to a blurred background, a large checkmark scales up with a bounce animation, then transitions to the summary/reward screen.

### Reward Screen & Milestone Celebrations

- The alien hacker animation should feel **celebratory but calm** — no rapid flashing or chaotic motion.
- Characters at **alpha 0.6** overlaying the summary.
- Summary card beneath: white card with large text showing reps, accuracy %, duration.
- A single "Done" or "Back to Home" button at the bottom.
- **Delightful but restrained** — the animation must never obscure the results summary. The user should be able to read their stats while the celebration plays.

#### Milestone & Achievement Animations

- **First session complete**: a special "Welcome to your recovery journey" card with a warm illustration, gentle scale-up animation.
- **Perfect form session (100% accuracy)**: gold shimmer effect on the summary card border, Soft Gold particles float upward gently (like golden dust). Display a badge: "Perfect Form" with a star icon.
- **Streak milestones (3 days, 7 days, etc.)**: a flame/streak icon animates in with a count. Use Lottie animation if available, or a custom SwiftUI animation with scaling + rotation.
- **Rep milestones (50th rep, 100th rep lifetime)**: the rep counter does a celebratory burst — scales up 1.5x, rings of teal radiate outward, then settles back. Short haptic pattern (`.success` followed by `.impact(.light)`).
- All achievement badges should be shown in a **horizontal scroll row** on the home screen after they're earned — gives a sense of progress over sessions.
- **Principle**: every milestone animation should make the user smile and feel proud, but never delay them from continuing. Animations auto-dismiss after 2–3s or on tap — whichever comes first.

### Escalation Screen

- Tone: **reassuring, not alarming.** This is help arriving, not a failure state.
- Large friendly icon (e.g., `person.2.fill` or a phone icon) at the top.
- Message: large, warm text — "Let's get your physiotherapist on the line to help."
- Two clear buttons stacked vertically: "Call My Physiotherapist" (primary), "Start Video Call" (secondary).
- No countdown timers or urgency cues — let the user proceed at their pace.

### Motion & Animation Principles

- **Ease-in-out** curves for all transitions.
- Duration: 0.3s for micro-interactions, 0.5s for screen transitions, 1.5–2s for reward/milestone celebrations.
- Avoid: parallax effects, auto-scrolling, anything that moves without user initiation.
- Reward and milestone animations are the exception where playful motion is encouraged — but still no strobing or rapid flashes.
- **Spring animations** for elements that "arrive" (counters, badges, cards appearing): `interpolatingSpring(stiffness: 170, damping: 15)` for a natural, physical feel.
- **Particle effects** should be lightweight (max 20–30 particles), short-lived (fade in <1s), and never cover interactive elements.
- Consider using **Lottie** for complex reward animations (alien hacker fist bump, streak fire) — prebuilt JSON animations are lightweight and look polished.

### Accessibility (Non-Negotiable)

- Full **VoiceOver** support on every screen — all images have accessibility labels, all buttons have clear descriptions.
- Support **Dynamic Type** — layouts must not break up to xxxLarge accessibility size.
- **Reduce Motion** preference must be respected — replace animations with crossfades when enabled.
- All text must be **selectable/readable by screen readers** in logical order.

### Emotional Design

The app should feel like a **kind, patient human companion** — not a clinical tool, not a gamified fitness app.

- Use **warm, encouraging language**: "Great job!", "Let's take it easy today", "You're doing well"
- Never use negative language: avoid "failed", "wrong", "error", "bad form"
- Instead: "Let's adjust that a little", "Try straightening your back", "Almost there!"
- The Doctor's Note screen is the emotional anchor — it should feel personal, like a handwritten note from someone who cares.
- Progress should feel **celebratory at every step**, not just at completion.

## Best UI/UX Quality Checklist (LA Hacks 2026)

Every screen must be validated against this checklist before it's considered done. This is our design quality gate.

| Area | What "good" looks like | How to verify |
|------|----------------------|---------------|
| **Onboarding / Readiness screen** | Extremely clear, minimal, friendly explanation of why today's routine changed, with strong typography and one obvious next action. | Show the screen to someone for 3 seconds — can they explain what the app wants them to do? |
| **Camera supervision screen** | Large readable overlays, no clutter, feedback appears at the right moment, skeleton/pose overlay is easy to understand. | During exercise, only 3 things should be on screen: skeleton overlay, rep counter, and correction pill (when needed). Nothing else. |
| **Information hierarchy** | The user should instantly know: what exercise to do, what mistake they made, what to correct next. | Cover the bottom half of the screen — the top half alone should communicate the current state. |
| **Emotional tone** | Encouraging language instead of harsh warnings; e.g. "Let's adjust your stance" instead of "Wrong form." | Grep the codebase for words: "wrong", "bad", "fail", "error", "incorrect" — none should appear in user-facing strings. |
| **Reward state** | Delightful but restrained animation that does not obscure results. | During the reward animation, can you still read every stat in the summary card? If not, dial back the animation. |
| **Escalation flow** | Calm, clear, human-centered handoff with obvious CTAs and reassuring copy. | The screen should feel like "help is here" not "you failed." Read the copy aloud — does it sound like a kind nurse or a robot? |
| **Visual consistency** | Same color logic, spacing, icon style, and typography across all screens. | Screenshot every screen side by side — do they look like they belong to the same app? No one-off colors, font sizes, or spacing. |

## Technical Guidelines

- **Platform**: iOS 16+, iPhone only, Swift 5.9+, SwiftUI
- **Architecture**: MVVM (Views → ViewModels → Services)
- **All AI inference runs on-device** — zero network calls for camera/pose data
- **Privacy is the #1 technical constraint** — never transmit video or health data off-device
- Use `async/await` for all asynchronous operations
- HealthKit queries go through `HealthKitManager` — never query `HKHealthStore` directly from views
- Pose estimation goes through `PoseEstimationService` — keep SDK details out of ViewModels

## File Structure

See `tasks/tasks-physiopal.md` for the full folder structure and team assignments.
