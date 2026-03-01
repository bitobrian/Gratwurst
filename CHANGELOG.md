# Changelog

## [1.9.0] - 2026-03-01

### Fixed
- Grats messages no longer send if combat begins during the delay window after an achievement fires
- Replaced deprecated `SendChatMessage` with `C_ChatInfo.SendChatMessage`

### Changed
- Config panel controls (checkbox, Max Delay slider, Frequency slider) are now in a left-aligned vertical stack for a cleaner layout

### Internal
- Version number is now injected at package time via `@project-version@` token; source files no longer contain a hardcoded version
- Added `package.sh` and `package.ps1` for local and CI packaging
- CI workflow now triggers automatically on version tag push and validates semver format on manual runs
- Action dependencies pinned to exact commit SHAs

## [1.8.0] - 2025-06-25

### Added
- **Complete UI Overhaul**: Replaced EditBox with modern ScrollFrame-based message list
- **Individual Message Management**: 
  - Add new messages via "Add Message" button
  - Edit existing messages with inline dialog
  - Delete messages with confirmation
  - Reorder messages with up/down arrows
- **Default Message List**: Comprehensive set of 10 default congratulatory messages
- **Message Count Display**: Shows current number of messages in the list
- **Restore Defaults**: Button to reset to the built-in default messages
- **Backward Compatibility**: Automatic migration from old string format to new array format
- **Enhanced User Experience**: 
  - Movable dialogs for adding/editing messages
  - Keyboard shortcuts (Enter to save, Escape to cancel)
  - Visual feedback with message backgrounds
  - Proper button states (disabled when not applicable)

### Changed
- **Data Structure**: Messages now stored as array instead of single string with newlines
- **UI Layout**: Modernized interface with better visual hierarchy
- **Message Parsing**: Updated to work with new array structure
- **Configuration**: Enhanced settings panel with improved organization

### Technical Improvements
- **Code Organization**: Better separation of concerns with dedicated message management functions
- **Error Handling**: Improved validation and error checking
- **Performance**: More efficient message handling and UI updates
- **Maintainability**: Cleaner code structure for future enhancements

### Fixed
- **Message Persistence**: Proper saving and loading of message arrays
- **UI Responsiveness**: Better handling of dynamic content updates
- **Memory Management**: Proper cleanup of UI elements

### Migration Notes
- Existing users will have their messages automatically migrated to the new format
- Old `GratwurstMessage` variable is cleaned up after migration
- No data loss during the upgrade process

## [1.7.2] - Previous Version
- Basic EditBox-based message input
- Simple string-based message storage
- Basic randomization functionality 