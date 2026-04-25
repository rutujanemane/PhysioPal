Error Codes
Reference for ZETIC Melange error codes and their meanings.

This page documents error codes you may encounter when using the ZETIC Melange SDK.

SDK Runtime Errors
Authentication Errors
Error	Platform	Cause	Solution
Model not found	Android	Invalid model key or personal key	Verify keys on the Dashboard
Failed to download model	iOS	Invalid key or network failure	Check keys and network connectivity
HTTP 401 / 403	Both	Authentication failure	Regenerate your personal key
Inference Errors
Error	Platform	Cause	Solution
Input shape mismatch	Both	Input tensor dimensions do not match model expectations	Check expected shapes on the Dashboard
UnsatisfiedLinkError	Android	JNI libraries not extracted correctly	Add useLegacyPackaging true to Gradle config
Compilation Errors
Error	Context	Cause	Solution
Unsupported operation	Model upload	Model contains unsupported ops	Simplify model or use a different opset
Conversion failed	Model upload	General compilation failure	Check model format and try onnxsim
For detailed troubleshooting steps for each error type, see:

Common Errors
Android Issues
iOS Issues
Model Conversion Issues
Getting Help