# Venture Map

An iOS app helping Detroit community leaders track neighborhood outreach and discover expansion opportunities. Built with SwiftUI.

## About

Venture Map was built during the **Apple Developer Academy Foundations Program** (October 2026) by Team Fantastic 3.0 (Erisha Smith, Ashton, Chris).

The app serves **Ron**, a Detroit community leader who works across neighborhoods and wants to understand where he's having impact and where to expand next. It logs the neighborhoods he's interacted with, visualizes his reach on a map, and surfaces patterns to guide outreach strategy.

## Features

- **Interactive Map** — Visualize outreach activity across Detroit neighborhoods
- **Event Logging** — Record community events with location, date, and details
- **Reach Analytics** — See which neighborhoods you're active in and spot gaps
- **Organization Search** — Discover local organizations to partner with
- **Guest Mode** — Explore the app without creating an account

## Tech Stack

- **SwiftUI** — Native iOS UI (iOS 26+)
- **MapKit** — Interactive maps and location services
- **SwiftData** — Local persistence
- **Node.js** — Lightweight proxy server for organization search
- **Apple Human Interface Guidelines** — Design system with Liquid Glass treatments

## Project Structure

```
VentureMap/                    # Main iOS app target
├── Views/
│   ├── Home/                  # Map view, event markers, filters
│   ├── Events/                # Event detail, editing, creation
│   ├── Reach/                 # Analytics dashboards and metrics
│   ├── Search/                # Organization and location search
│   ├── Onboarding/            # Welcome flow and tutorial
│   ├── Authentication/        # Sign in / sign up
│   └── Profile/               # User profile and settings
├── Models/                    # Data models
├── Services/                  # Business logic and API clients
├── Extensions/                # SwiftUI helpers
└── Server/                    # Node.js proxy for organization search
```

## Getting Started

### Prerequisites

- Xcode 16+ on macOS 15+
- iPhone running iOS 26+ (or Simulator)
- Node.js 18+ (for the organization search proxy)

### iOS App

1. Clone the repo:
   ```bash
   git clone https://github.com/RISHAOFFICIAL/venture-map.git
   ```

2. Open in Xcode:
   ```bash
   open VentureMap.xcodeproj
   ```

3. Build and run (Cmd+R)

### Organization Search Server (Optional)

The app includes an optional Node.js proxy for organization search:

```bash
npm install
npm start
```

## Design Process

This project followed Apple's app design process:

1. **Discover** — User research with Ron to understand his workflow
2. **Define** — Scoped to one thing done well: tracking and visualizing outreach
3. **Design** — Lo-fi wireframes through hi-fi prototype, with HIG checks at each stage
4. **Build** — Iterative SwiftUI implementation

## Team

- **Erisha Smith** — iOS Developer
- **Ashton** — iOS Developer
- **Chris** — iOS Developer

Built as part of the Apple Developer Academy Foundations Program, Michigan State University, Detroit.

## License

All rights reserved.

---

Built by [Erisha Smith](https://www.linkedin.com/in/erishasmith) — iOS Developer, Apple Developer Academy Foundations Graduate.
