# ZETIC Melange iOS Setup for PhysioPal

This document summarizes the iOS setup path for **ZETIC Melange** in a Swift / SwiftUI iPhone app.[cite:57][cite:60]

## Recommended platform choice

For PhysioPal, the best implementation path is a **native iOS app in Swift / SwiftUI** because ZETIC’s public setup and sample app flow is native-first on iOS and uses Swift Package Manager.[cite:57][cite:60]

## Prerequisites

ZETIC’s iOS setup guide lists these prerequisites:[cite:57]

- Xcode 14 or later.[cite:57]
- iOS 15.0 or later.[cite:57]
- A physical iPhone, with iPhone 8 or later recommended.[cite:57]
- A Personal Key from the Melange Dashboard for production-style integration.[cite:57][cite:79]

For demo experiments, the quick start also notes that a preconfigured demo flow exists and no account is required for the basic trial path.[cite:60]

## Important device note

Melange should be tested on a **physical device**, not a simulator, because simulators do not have Apple Neural Engine hardware and do not reflect real performance behavior.[cite:57]

## Add the SDK in Xcode

Use Swift Package Manager to add Melange:[cite:57][cite:60]

1. Open the Xcode project.[cite:57]
2. Go to **File → Add Package Dependencies**.[cite:57][cite:60]
3. Use the package URL: `https://github.com/zetic-ai/ZeticMLangeiOS`.[cite:57][cite:60]
4. Prefer **Exact Version 1.6.0** or **Up to Next Major Version from 1.6.0**, because the setup guide targets `ZeticMLange iOS 1.6.0`.[cite:57]
5. Add the package to the app target.[cite:57]

## Link Accelerate.framework

Melange depends on Apple’s **Accelerate.framework** for vDSP and BLAS kernels, and the docs say Swift Package Manager does not link this system framework automatically.[cite:57]

Manual step:[cite:57]

1. Select the app target in Xcode.[cite:57]
2. Open **General → Frameworks, Libraries, and Embedded Content** or **Build Phases → Link Binary With Libraries**.[cite:57]
3. Add `Accelerate.framework`.[cite:57]

## First-run behavior

The docs state that first-time initialization may perform a network call to download the optimized model binary, and that binary is then cached locally so later initializations are faster.[cite:57][cite:60]

This matters for the demo because the team should run the app once before judging to avoid a visible first-download pause.[cite:57][cite:60]

## Quick-start inference model

The quick start provides a demo model key named `Steve/YOLOv11_comparison` to test the pipeline immediately and confirm that the SDK works before switching to a final model path.[cite:60]

This is useful even if PhysioPal later uses a pose-related flow, because it validates:

- package installation,[cite:60]
- device execution,[cite:60]
- local caching behavior,[cite:60]
- and the general Melange initialization path.[cite:57][cite:60]

## Implementation checklist

- Add the Swift package successfully.[cite:57][cite:60]
- Link `Accelerate.framework`.[cite:57]
- Verify the app runs on a physical device.[cite:57]
- Perform one test initialization before deeper integration.[cite:57]
- Confirm the first-run download completes and later runs are faster.[cite:57][cite:60]
- Only after that, wire the model output into the supervision UI.[cite:57]

## Practical recommendation for Cursor

Ask Cursor to implement the Melange integration in this order:

1. Create a tiny SDK verification service that initializes a known Melange model on app launch.[cite:57][cite:60]
2. Log success/failure clearly in Xcode console.[cite:57]
3. Keep this verification path isolated from the camera flow until the SDK is confirmed working.[cite:57]
4. Then replace the mock pose stream with actual model outputs.[cite:57]
