# Agent Guidelines for Slide-chan

This document provides essential information for AI agents working on the Slide-chan iOS project. Slide-chan is a SwiftUI-based 4chan client.

## 1. Build, Lint, and Test Commands

### Prerequisites
- Xcode 15+
- iOS 18.0+ deployment target
- `xcode-build-server` (optional, for LSP)

### Common Commands
- **Build**: 
  ```bash
  xcodebuild -workspace slide-chan.xcodeproj/project.xcworkspace -scheme slide-chan -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build
  ```
- **Clean**: 
  ```bash
  xcodebuild -workspace slide-chan.xcodeproj/project.xcworkspace -scheme slide-chan clean
  ```
- **Run All Tests**: 
  ```bash
  xcodebuild test -workspace slide-chan.xcodeproj/project.xcworkspace -scheme slide-chan -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'
  ```
- **Run Single Test**: 
  ```bash
  xcodebuild test -workspace slide-chan.xcodeproj/project.xcworkspace -scheme slide-chan -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:slide-chanTests/ClassName/testMethodName
  ```

*Note: Replace 'iPhone 15' with an available simulator name. Use `xcrun simctl list devices` to see options.*

## 2. Project Architecture & Conventions

The project follows a **MVVM (Model-View-ViewModel)** pattern using **SwiftUI** and **Combine**.

### Directory Structure
- `Models/`: Data structures conforming to `Codable`. Used for API responses.
- `ViewModels/`: Business logic, state management, and API orchestration. Annotated with `@MainActor`.
- `Views/`: SwiftUI View components.
    - `Main/`: Primary screens and navigation containers.
    - `Components/`: Reusable UI elements (rows, buttons, styles).
    - `Media/`: Media handling, full-screen viewers, and gallery components.
- `Services/`: Network logic (`APIService`) and external communications.
- `Utilities/`: Helper extensions and global utilities.
- `Resources/`: Assets, colors, and static data.

### Naming Conventions
- **Files/Types**: PascalCase (e.g., `ThreadViewModel.swift`, `Post`).
- **Variables/Functions**: camelCase (e.g., `fetchThread()`, `isBookmarked`).
- **Views**: Suffix with `View` (e.g., `ThreadDetailView`).
- **ViewModels**: Suffix with `ViewModel` (e.g., `BoardViewModel`).
- **Models**: Simple descriptive names (e.g., `Post`, `Board`).

### Coding Style & Formatting
- **Indentation**: 4 spaces.
- **Organization**: Use `// MARK: - [Section Name]` to group properties, logic, and view components.
- **Imports**: Standard library first, then Apple frameworks (SwiftUI, Combine, Foundation). Keep them alphabetically sorted.
- **Documentation & Language**: 
    - **English Only**: All code comments, documentation, and variable names MUST be in English.
    - **Doc-Strings**: Use consistent triple-slash (`///`) doc-strings for all public and internal types, properties, and functions. Explain the *intent* and parameters where necessary.
- **SwiftUI Patterns**:
    - Use `@StateObject` for ViewModels initialized within the view.
    - Use `@ObservedObject` for ViewModels passed from a parent view.
    - Prefer `.task { ... }` for triggering async data loading when a view appears.
    - Leverage `#Preview` macros for all View files. **MANDATORY**: Every new UI component MUST include a `#Preview` block using `MockData` where applicable.

### Concurrency
- Primary mechanism: `async/await`.
- UI updates: Ensure all ViewModel `@Published` properties are updated on the Main Actor (use `@MainActor` class annotation).
- Network: `URLSession.shared.data(from:)` is preferred.

### Error Handling
- Errors should be handled gracefully and displayed via UI alerts or state messages.
- Use `APIService.APIError` for network-related issues.
- Map low-level errors to user-friendly strings in ViewModels.

## 3. Cursor & Copilot Rules
(No specific `.cursorrules` or `.github/copilot-instructions.md` found. Follow the patterns established in existing files.)

## 4. API Integration
The app interacts with the 4chan JSON API.
- **Base URL**: `https://a.4cdn.org/`
- **Image URL**: `https://i.4cdn.org/[board]/[tim][ext]`
- **Thumbnail URL**: `https://i.4cdn.org/[board]/[tim]s.jpg`
- **Catalog**: `/[board]/catalog.json`
- **Thread**: `/[board]/thread/[id].json`

When adding new API endpoints, update `APIService.swift` and follow the `fetch<T>` pattern.

## 5. View Component Guidelines
- **SmartText.swift**: Used for rendering post content with greentext and reply link detection. Use this instead of standard `Text` for comments.
- **MediaView.swift**: The central component for displaying images and videos.

## 6. Testing Guidelines
- Unit tests go in `slide-chanTests/`.
- UI tests go in `slide-chanUITests/`.
- Use `XCTestCase` for all tests.
- Mock network calls where possible by injecting a mock `APIService` or using protocols.
