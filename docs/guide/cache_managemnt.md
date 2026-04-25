Cache Management
TBD reference for managed model cache behavior and ModelCacheManager.

This page is a placeholder. Detailed cache management documentation is still being prepared.

This page will be expanded to cover managed model cache behavior, ModelCacheHandlingPolicy, and ModelCacheManager.

Current Scope
For now, the main distinction is:

cacheHandlingPolicy controls managed model artifacts stored on disk
kvCacheCleanupPolicy controls the in-memory LLM conversation KV cache
Do not treat them as the same setting.

ModelCacheHandlingPolicy
The full behavior of overlapping aliases, artifact retention, and cache cleanup policy combinations is still TBD.

Until this page is expanded, the safest interpretation is:

REMOVE_OVERLAPPING: prefer replacing overlapping managed cache entries for the same model selection flow
KEEP_EXISTING: prefer leaving existing managed cache entries in place
ModelCacheManager
The SDK now includes a managed cache utility object, but detailed usage examples are still TBD.

Android
Android exposes ModelCacheManager for managed cache deletion and pruning operations.

Current public operations include:

removeGeneral(...)
removeLlm(...)
removeHf(...)
removeAll()
prune()
iOS
iOS also exposes ModelCacheManager with corresponding managed cache deletion and pruning operations.

Current public operations include:

removeGeneral(...)
removeLlm(...)
removeHf(...)
removeAll()
prune()
Planned Expansion
This page will later include:

exact ModelCacheHandlingPolicy semantics
managed alias and artifact lifecycle
ModelCacheManager examples
platform-specific notes for Android and iOS
See Also