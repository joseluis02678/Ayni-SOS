# Release signing (gitignored secrets)

- `ayni-release.jks` — local release keystore (do not commit)
- Apps load `android/key.properties` (see `key.properties.example`)

Default local passwords used for prototype builds are in your local `key.properties` only.
Rotate before any Play Store upload.
