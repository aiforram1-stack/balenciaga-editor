# BalenciagaEditor (macOS)

A brutalist, Balenciaga-inspired advanced writing editor for macOS. Designed for focus, speed, and aesthetic minimalism.

![App Header](https://raw.githubusercontent.com/aiforram1-stack/balenciaga-editor/main/header.png) *Note: Replace with actual screenshot*

## ✨ Features

- **Multi-document Tabs**: Manage multiple files in a single window with a sleek tabbed interface.
- **Workspace Browser**: Navigate your project files with ease using the sidebar.
- **Markdown Mastery**: Built-in actions for bold, italic, headings, lists, quotes, and inline code.
- **Live Preview**: See your formatted content in real-time as you type.
- **Outline Navigation**: Quickly jump between sections using the auto-generated outline.
- **Live Statistics**: Real-time tracking of words, characters, paragraphs, and estimated reading time.
- **Word-Goal Tracking**: Set and monitor your progress toward your writing goals.
- **Focus & Typewriter Modes**: Distraction-free writing environments.
- **Autosave**: Never lose your work with intelligent background saving.

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 or later
- Swift 5.9+

### Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/aiforram1-stack/balenciaga-editor.git
   cd balenciaga-editor
   ```

2. Run the application:

   ```bash
   swift run
   ```

### Build Standalone App

To create a double-clickable macOS app bundle:

```bash
./scripts/build_standalone_app.sh
open dist/BalenciagaWriter.app
```

## 🛠 Tech Stack

- **SwiftUI**: Modern, declarative UI framework.
- **Swift Package Manager**: Dependency management.
- **AppKit Interop**: For deep system integration and advanced editor features.

## 🧪 Validation

Run the validation suite to ensure everything is working correctly:

```bash
swiftc -emit-executable Sources/BalenciagaEditor/Models.swift Sources/BalenciagaEditor/Utilities.swift Sources/BalenciagaEditor/AppState.swift scripts/feature_validation.swift -o /tmp/balenciaga_writer_validation
/tmp/balenciaga_writer_validation
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
