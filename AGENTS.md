# Public repository safety

Before every commit or push, inspect the staged diff and tracked files. Never publish secrets, credentials, private keys, personal absolute paths, internal hosts or infrastructure, local logs/data, or build artifacts. Keep scripts portable by deriving paths from the repository root. If anything is uncertain, stop and sanitize it first.
