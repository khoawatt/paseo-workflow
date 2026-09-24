# Security Policy

Do not open a public issue containing credentials, authentication state, live
Paseo config, private keys, cookies, host backups, or runtime IDs. Use the
repository's GitHub Security Advisory flow to report a suspected vulnerability
privately.

This bootstrap treats provider ID plus `paseoTools` as a Paseo tool-capability
boundary, not an operating-system security sandbox. Provider-native permissions
and human approval remain separate controls.

Before reporting a security issue, reproduce it with sanitized fixtures when
possible and include the Paseo version, WSL/Ubuntu version, affected bootstrap
commit, expected boundary, observed behavior, and minimal safe reproduction.
Never include real secrets or raw live config.
