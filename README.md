# Action Bar Storage

A World of Warcraft addon (Patch 12.0 / Midnight) that lets you save action bar layouts as named profiles and restore them on any character.

## Features

- **Save individual bars or all bars** into named profiles
- **Hover & click bar selection** — an overlay highlights whichever action bar your mouse is over; click to select it
- **Cross-character** — profiles are stored account-wide and available on every character
- **Bar remapping** — profiles remember which bar each layout came from, and apply back to the correct bar by default
- **Profile management** — view slot-by-slot contents, rename, or delete profiles from the dialog

## Installation

1. Download or clone this repository
2. Copy the `ActionBarStorage` folder into your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\ActionBarStorage\
   ```
3. Launch WoW and enable the addon in the AddOns menu on the character select screen

## Usage

| Command | Action |
|---|---|
| `/abs` | Open / close the Action Bar Storage window |
| `/actionbarstorage` | Same as above |

### Saving a profile
1. Open the window with `/abs`
2. Click **New Profile**
3. Enter a profile name and click **Next →**
4. The overlay mode activates — hover over any action bar to highlight it, then **click** to select it (green checkmark = selected). Click **All** to select every visible bar at once.
5. Click **Confirm** to save

### Applying a profile
1. Select a profile from the list on the left
2. Click **Apply Profile**
3. The saved bar layouts are written back to the same bar positions they were captured from

> **Note:** Profiles can only be applied outside of combat. Attempting to apply while in combat will show an error message.

## Limitations

- **Class spells are character-specific** — applying a profile from a Paladin onto a Mage will leave class ability slots empty. Same-class alts work perfectly.
- Macros are matched by name across characters, so a macro must exist on the destination character to be placed.
- Items require the item to be in your bags on the destination character.

## License

MIT
