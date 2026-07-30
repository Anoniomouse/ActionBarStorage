# Changelog

## [1.0.7] - 2026-07-30

### Fixed
- Bar selector now detects Blizzard default bars without any UI addon installed
- Midnight 12.0 renamed action button globals (e.g. ActionButton1 → MainActionBarButtonContainer1); detection updated for new names
- Parent-walk logic finds the full bar container frame instead of the 45×45 per-button wrapper
- Cover frames anchored to first and last button ensure accurate hover detection for all bar layouts

## [1.0.6] - 2026-07-23

### Fixed
- Bar remap button now displays correctly; WoW font does not support Unicode arrows

## [1.0.5] - 2026-07-23

### Added
- Bar remapping in apply dialog — click the → button on any bar to apply it to a different bar instead

## [1.0.4] - 2026-07-23

### Fixed
- Reverted interface version to 120007; 12.1 not yet live

## [1.0.3] - 2026-07-23

### Changed
- Updated for patch 12.1

## [1.0.2] - 2026-06-16

### Changed
- Updated for patch 12.0.7

## [1.0.1] - 2026-05-19

### Fixed
- Selector dialog instruction text no longer overflows the panel edge

## [1.0.0] - 2026-05-18

### Added
- Save individual action bars or all bars into named profiles
- Hover & click bar selector — gold highlight on hover, green on selection
- Cross-character profiles stored account-wide (`SavedVariables`)
- Apply profile to any character; skipped slots reported in chat with reason
- Per-bar apply dialog — choose which bars to restore before applying
- Export profile to clipboard as a shareable text string
- Import profile from exported text string
- Rename and delete profiles via custom dialogs
- Full Midnight 12.0.5 compatibility: updated action bar APIs, SavedVariables path
- Works with Blizzard default bars, ElvUI, Bartender4, and Dominos
- Override/vehicle bar detection — main bar excluded from selector while mounted
