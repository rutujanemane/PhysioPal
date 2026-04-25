iOS Issues
Troubleshoot common iOS integration issues with ZETIC Melange.

This page covers iOS-specific issues you may encounter when integrating ZETIC Melange.

Swift Package Manager Issues
Package Resolution Failure
Symptom: Xcode fails to resolve the Melange package with errors like "Failed to resolve dependencies" or "Unable to fetch repository."

Solutions:

Verify the package URL is correct: https://github.com/zetic-ai/ZeticMLangeiOS
Check your internet connection and try again.
In Xcode, go to File then Packages then Reset Package Caches, then resolve again.
If using a VPN or corporate proxy, ensure GitHub is accessible.
Version Conflicts
Symptom: Package version conflicts with other dependencies.

Solution: Try specifying a specific version or branch when adding the package dependency instead of using "Up to Next Major Version."

Linker Errors
Undefined Accelerate Symbols
Symptom: Build fails with linker errors similar to:


Undefined symbol: _cblas_sgemm$NEWLAPACK$ILP64
Undefined symbol: _vDSP_maxv
Undefined symbol: _vDSP_measqv
Undefined symbol: _vDSP_sve
Undefined symbol: _vDSP_vadd
Undefined symbol: _vDSP_vdiv
Undefined symbol: _vDSP_vmul
Undefined symbol: _vDSP_vsadd
Undefined symbol: _vDSP_vsmsa
Undefined symbol: _vDSP_vsmul
Undefined symbol: _vDSP_vsub
Cause: ZeticMLange uses Apple's Accelerate framework (vDSP, BLAS). Swift Package Manager does not link system frameworks automatically, so the app target needs to link it explicitly.

Solution: Add Accelerate.framework to your app target's linked libraries:

Select your app target in Xcode.
Open General → Frameworks, Libraries, and Embedded Content (or Build Phases → Link Binary With Libraries).
Click +, search for Accelerate.framework, and add it.
See Setup → Link Accelerate.framework for step-by-step instructions.

This manual step is a temporary workaround. A future SDK release will auto-link Accelerate through SPM so this troubleshooting entry no longer applies.

Code Signing Issues
Symptom: Build fails with signing errors related to the Melange framework.

Solutions:

Ensure you have a valid development certificate and provisioning profile.
In your target's Signing & Capabilities, verify the team and bundle identifier are correct.
If using automatic signing, try toggling it off and on again.
Simulator Limitations
Symptom: Model runs on simulator but performance is unexpectedly slow, or you see degraded results.

Cause: iOS Simulators do not have Neural Engine hardware.

Solution: Always test on a physical device for accurate performance and results. The simulator will use CPU fallback.

Performance measurements on the simulator are not representative of real device performance. Always benchmark on physical hardware.

Model Initialization Errors
Symptom: ZeticMLangeModel initializer throws an error.

Solutions:

Verify your Personal Key is correct. Copy it from the Melange Dashboard.
Verify your Model Key matches a compiled model that has reached "Ready" status.
Ensure the device has network connectivity for the initial model download.
Check that you are using a physical device, not a simulator (for NPU-dependent functionality).
App Transport Security
Symptom: Network requests fail with ATS-related errors.

Solution: The Melange SDK communicates over HTTPS, which should work with default ATS settings. If you have customized ATS settings in your Info.plist, ensure HTTPS connections are allowed.

Memory Warnings
Symptom: App receives memory warnings or crashes when loading large models.

Solutions:

Ensure you are not holding references to multiple large model instances simultaneously.
Release model instances when they are no longer needed.
For LLM models, call cleanUp() to release the KV cache when done.
Still Having Issues?