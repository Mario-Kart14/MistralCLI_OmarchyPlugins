# Vibe CLI Default Agent Plugin for Omarchy

A bar widget plugin that sets **Vibe CLI** as the default AI agent in Omarchy and provides quick access to its configuration.

## Features
- Set Vibe CLI as the default AI agent with one click.
- Check if Vibe CLI is installed.
- Launch Vibe CLI directly from the panel.

## Installation

### Using Omarchy CLI
```sh
omarchy plugin add https://github.com/Mario-Kart14/MistralCLI_OmarchyPlugins.git --enable
omarchy bar add io.github.mario-kart14.vibe-default-agent --section right
```

### Manual Installation
1. Clone or copy the `vibe-default-agent` folder to `~/.config/omarchy/plugins/io.github.mario-kart14.vibe-default-agent/`:
   ```sh
   mkdir -p ~/.config/omarchy/plugins/io.github.mario-kart14.vibe-default-agent
   cp -r /path/to/vibe-default-agent/* ~/.config/omarchy/plugins/io.github.mario-kart14.vibe-default-agent/
   ```
2. Enable the plugin:
   ```sh
   omarchy plugin enable io.github.mario-kart14.vibe-default-agent
   ```
3. Add it to your bar (optional, if not auto-added):
   ```sh
   omarchy bar add io.github.mario-kart14.vibe-default-agent --section right
   ```

## Usage
- **Left-click** the "Vibe" widget in the bar to open the configuration panel.
- Use the panel to:
  - Set Vibe CLI as the default AI agent.
  - Check if Vibe CLI is installed.
  - Launch Vibe CLI directly.

## Requirements
- **Vibe CLI** must be installed and available in your `PATH`.
- Omarchy (Quattro shell).

## Configuration
To ensure Vibe CLI is recognized as a valid agent by Omarchy, you may need to create a symlink or ensure it is in your `PATH`.

Example:
```sh
# If Vibe CLI is installed via npm or another method, ensure it's in PATH
which vibe  # Should return a valid path

# If not, create a symlink (adjust path as needed)
ln -s /path/to/vibe /usr/local/bin/vibe
```

## License
MIT
