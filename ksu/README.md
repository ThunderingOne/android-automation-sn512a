# KernelSU staging for GhostLock path
- KernelSU.apk — v3.3.0 manager (install after exploit roots the session)
- kernelsu.ko — lkm-aarch64-android13-5.15 (exact KMI match for our kernel)
- Flow: ghostlock payload -> root -> ksud late-load kernelsu.ko -> manager app
