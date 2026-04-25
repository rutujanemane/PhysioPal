# ZETIC LA Hacks Brief for PhysioPal

ZETIC’s LA Hacks challenge is to build an AI-powered app using **Melange** where the **primary functionality runs on-device** and cloud usage is limited to secondary tasks.[cite:2][cite:75]

For PhysioPal, this is a strong fit because the app’s core loop — camera-based exercise supervision and form feedback — can run locally on the iPhone, while optional cloud features such as escalation, call initiation, or reporting can remain secondary.[cite:2][cite:75]

## What ZETIC is looking for

Strong submissions should:[cite:75]

- Run core functionality directly on-device.[cite:75]
- Clearly separate on-device and cloud responsibilities.[cite:75]
- Optimize latency, efficiency, and resource usage.[cite:75]
- Deliver a working prototype with real-world usability.[cite:75]
- Use the Melange SDK directly in the product.[cite:75]

## What to avoid

ZETIC explicitly warns against these patterns:[cite:75]

- Cloud-heavy applications with minimal on-device use.[cite:75]
- Thin wrappers around APIs without system-level thinking.[cite:75]
- Generic chatbot projects without meaningful functionality.[cite:75]

## Judging criteria

The challenge page says submissions are judged on:[cite:75]

- Effective use of on-device inference with the Melange SDK as the primary functionality.[cite:75]
- Clarity in separating on-device and cloud responsibilities.[cite:75]
- Performance, latency, and efficiency considerations.[cite:75]
- Overall user experience and usability.[cite:75]

## Why PhysioPal fits well

PhysioPal lines up well with ZETIC’s preferred healthcare direction because the challenge explicitly lists **healthcare** as an example domain for an on-device assistant with cloud fallback.[cite:75]

A clean mapping for PhysioPal is:

| Product function | Where it should run | Why |
|---|---|---|
| Pose estimation / form supervision | On-device | This is the core user value and must remain private, low-latency, and real-time.[cite:75][cite:57] |
| Exercise evaluation rules | On-device | This is directly tied to live coaching and should work offline.[cite:75] |
| Health-based routine adjustment | On-device | This keeps readiness decisions private and fast.[cite:75] |
| Twilio / Zoom escalation | Cloud-supported secondary action | This is not the primary AI workload and can remain optional.[cite:75] |
| Reporting / sharing | Optional cloud | This is secondary and should not be required for the app’s main use case.[cite:75] |

## Winning framing for the demo

The best concise framing is: **“PhysioPal is a privacy-first digital physiotherapist that uses Melange to run real-time exercise supervision directly on-device, with human escalation only when needed.”**[cite:75][cite:2]

That sentence hits ZETIC’s strongest values: on-device inference, privacy, real-world usefulness, and clear cloud separation.[cite:75]
