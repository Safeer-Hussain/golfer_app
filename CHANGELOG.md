# Changelog

All notable changes to the Golfer application will be documented in this file.

## [1.0.1+2] - 2026-11-18

### Added
- **Sprint 8: Wind Vector Compass HUD & True Crosswind Resolver**:
  - Vector decomposition engine calculating headwind, tailwind, and crosswind knots from atmospheric wind bearing and hole heading.
  - Interactive vector compass rose HUD with cardinal dial ticks, hole line arrow, wind source vector, and center velocity badge.
  - Aerodynamic yardage delta and true "play-as" distance calculations with club adjustment recommendations (+1, +2, -1 clubs).
  - Crosswind lateral drift estimation and caddie aim offset recommendations (e.g. "Aim 6.5y Right of Pin into crosswind").
  - Atmospheric wind presets for quick calibration (Links Coastal Gale, Inland Right Cross, Downwind Assist, Dawn Patrol Calm, Quartering Water Hazard).
  - Offline-first SQLite persistence for logging shot vector calculations and viewing history.
  - Multi-unit conversion support (Knots, MPH, M/S, KM/H).
  - Responsive 360dp landscape safety and zero-color-hardcoding theme integration.
  - Full automated unit and widget test suite covering aerodynamic math, controller state, and landscape viewport rendering.
- **CI/CD & GitHub Actions Release Pipeline**:
  - Automated release workflow in `.github/workflows/release.yml` for building release APKs on tag push and attaching them to GitHub Releases.

## [1.0.0+1] - 2026-11-18

### Initial Production Release
- Multi-player golf flight management (up to 4 players).
- Digital scorecard with live gross/net scoring and hole stepper navigation.
- GPS Rangefinder with satellite map visualization and touch crosshair.
- AI Caddie strategy engine with shot recommendations and hazard analysis.
- Social clubhouse feed and bag calibrator.
- Sprints 1 through 7: Nassau Side-Bet Calculator, Green Reading Simulator, Swing Tempo Trainer, USGA Handicap Differential, Skins Pot Splitter, Wolf Game Mode, and Club Gapping Matrix.
