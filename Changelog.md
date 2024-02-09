# Changelog

## v1.0.0

- Fix: `certficate` typo in config parser.
- Improvement: Invoke-HttpUnit pipeline input.
- Feature: Add ServerCertificate property to the TestResult object.
- Feature: Add TCP connection test.
- Feature: Add a type format file for `TestResult`

## v0.6.0

- Adds IPs functionality

## v0.5.1

- Improves support for batching in SSLCertificate commands

## v0.5

- Adds SSLCertificate commands

## v0.4

- Switch to [Import-ConfigData](https://github.com/cdhunt/Import-ConfigData) for Toml parsing
  - Which also brings PSD1 and YAML support
- Better handle of SSL failures
- Adds basic functional tests
- Updates CI
- Updates Docs

## v0.3

- Initial release
