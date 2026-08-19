# Codex Glass v1.0.2 lightweight external CLI design

## Goal

Publish a smaller Windows package that does not bundle or download Codex CLI.
The user installs the official Codex CLI themselves, and Codex Glass uses the
CLI already visible on the user's PATH.

## User flow

1. The README links to the official Codex CLI installation instructions.
2. The user installs the latest official CLI and signs in to Codex Desktop.
3. The user unpacks Codex Glass and runs `安装.cmd`.
4. The installer verifies that `codex --version` works before copying files.
5. If the CLI is missing, the installer stops without changing the existing
   installation and gives the official download address and restart guidance.

## Product rules

- Codex Glass never downloads, updates, or bundles Codex CLI.
- The v1.0.2 release archive must not contain `app/tools/codex.exe`.
- The application keeps `codex` as its development and runtime command when a
  bundled executable is absent.
- The installer does not guess a proxy port or change proxy settings.
- v1.0.1 remains published for users who prefer the self-contained package.

## Error handling

- Missing or unusable CLI: abort installation before copying files and display
  a concise instruction to install the official CLI, then reopen the installer.
- CLI is installed but the account cannot be read: preserve the existing
  runtime message asking the user to sign in to Codex.

## Verification

1. Unit-test that the CLI locator falls back to `codex` when no bundled binary
   is present.
2. Package the app and assert that no `tools/codex.exe` entry exists.
3. Run the installer with an intentionally unavailable `codex` command and
   verify it exits before copying application files.
4. Run the complete test suite and GitHub Actions workflow.
