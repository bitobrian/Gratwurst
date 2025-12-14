# Gratwurst
A delicious automatic congratulations messaging addon for World of Warcraft.

## Features

- [x] Input and save grats message
- [x] Set and save delay
- [x] Choose from randomized string list
- [x] **NEW in 1.8.0**: Individual message management with listbox interface
- [x] **NEW in 1.8.0**: Add, edit, delete, and reorder messages
- [x] **NEW in 1.8.0**: Comprehensive default message list
- [x] **NEW in 1.8.0**: Message count display
- [x] **NEW in 1.8.0**: Restore defaults functionality

## Usage

Make changes and deploy to your WoW installation.

### Quick Deploy

Run `.\dev.ps1` to automatically detect your WoW installation and copy the addon. Or use `.\dev.ps1 scan` to list all detected WoW installations if you have multiple.

On VS Code, you can use the launch.json with `dev.ps1` to quickly back-up and copy the addon using F5.

### Message Management

The addon now features a modern listbox interface for managing your congratulatory messages:

- **Add Message**: Click the "Add Message" button to create new messages
- **Edit Message**: Click "Edit" on any message to modify it
- **Delete Message**: Click "Del" to remove unwanted messages
- **Reorder Messages**: Use ↑ and ↓ buttons to change message order
- **Restore Defaults**: Click "Restore Defaults" to reset to the built-in message list

### Message Format

Use `$player` in your messages to automatically insert the player's name:
- `"Gratz $player!"` becomes `"Gratz John!"`
- `"Congratulations on your achievement $player!"` becomes `"Congratulations on your achievement John!"`

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/bitobrian/Gratwurst/issues) to report any bugs or file feature requests.

### Developing

PRs are welcome!

### Tooling

Any text editor! Feel free to handwrite, scan, and ocr into Notepad!

### Thanks

#### Contributors

- [Server Restart In Podcast Crew](https://www.serverrestartin.com/)!

#### Github Action for packaging

[Vger Blizz Forum Post](https://us.forums.blizzard.com/en/wow/t/creating-addon-releases-with-github-actions/613424)

[Pawn Addon Source](https://github.com/VgerMods/Pawn)