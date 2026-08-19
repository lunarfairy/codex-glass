# Codex Glass v1.0.1 portable release plan

## Goal

Make the public Windows package work on a computer that only has Codex Desktop
installed. The installer must also run correctly in Windows PowerShell 5.

## Confirmed causes

1. `Install.ps1` is UTF-8 without a BOM and contains Chinese text. Windows
   PowerShell 5 interprets it using the system code page, corrupting quoted
   strings and producing a parser error.
2. The application launches `codex app-server` through `PATH`. Codex Desktop
   does not guarantee that the CLI command is on `PATH`, so the overlay starts
   with the placeholder instead of a percentage.

## Design

- Bundle the official Windows x64 Codex CLI executable in `app/tools/codex.exe`
  in the release archive. The application prefers this executable and falls
  back to `codex` only for local development.
- Start the executable directly with an argument list instead of invoking
  `cmd.exe`.
- Preserve the last known percentage on transient failures. When no percentage
  has ever been obtained, the hover text and controller tell the user to open
  Codex Desktop and sign in.
- Make both PowerShell scripts ASCII-only, removing their dependency on the
  legacy PowerShell source encoding behaviour.
- Include the Codex CLI attribution and Apache-2.0 license in the release
  archive. The release build script receives a CLI path explicitly, so the
  binary is not committed to this repository.

## Verification

1. Unit-test bundled CLI selection and direct process startup arguments.
2. Unit-test the explanatory unavailable state.
3. Run the complete .NET test suite.
4. Build a release archive, confirm it contains the bundled executable and
   licenses, and run both installer scripts through Windows PowerShell 5's
   parser.
5. Run the packaged CLI directly with `--version` and compare the archive
   checksum after upload.
