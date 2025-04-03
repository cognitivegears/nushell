# CLAUDE.md - Coding Guidelines and Commands

## Build & Test Commands
- **Build Rust plugin**: Execute `build.nu` in plugin directory (e.g., `cd plugins/nu_plugin_clipboard && ./build.nu`)
- **Test nupm scripts**: Run `cd plugins/nupm && nu tests/mod.nu`
- **Install plugin**: Use `./build.nu` which runs `cargo install --path .`

## Code Style Guidelines

### Nushell Scripts
- Use `def` for internal functions, `export def` for exposed functions
- Type parameters: `[param: string, optional?: string]` (note `?` for optional)
- Error handling: Use proper error messages and return values
- Use `$"..."` for string interpolation
- Use pipes (`|`) for data transformation

### Rust Code
- Follow standard Rust naming conventions (snake_case for functions, CamelCase for types)
- Use feature flags for platform-specific code
- Implement proper error handling with Result types
- Use Rust's module system with clear organization
- Conditional compilation with `#[cfg(...)]` attributes

## Project Structure
- Plugins in `plugins/` directory with `nupm.nuon` for package metadata
- Each plugin has independent versioning and documentation