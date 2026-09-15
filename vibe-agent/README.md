# Vibe CLI Agent Plugin for Omarchy

A native-style agent plugin that integrates Vibe CLI into Omarchy's AI agent system, providing token usage tracking and default agent functionality.

## Features
- **Native Omarchy Integration**: Uses the same UI components and layout as Omarchy's built-in agents panel
- **Token Usage Tracking**: Displays token usage by model, day, and with reset timers
- **Default Agent Support**: Allows setting Vibe CLI as the default AI agent
- **Model Statistics**: Shows token usage for Mistral models (mistral-large, mistral-small, codestral, mistral-embed)
- **Limit Tracking**: Displays session and weekly usage limits with reset countdowns

## Installation

### Using Omarchy CLI
```sh
omarchy plugin add https://github.com/Mario-Kart14/MistralCLI_OmarchyPlugins.git --enable
```

### Manual Installation
1. Clone or copy the `vibe-agent` folder to `~/.config/omarchy/plugins/omarchy.vibe/`:
   ```sh
   mkdir -p ~/.config/omarchy/plugins/omarchy.vibe
   cp -r /path/to/vibe-agent/* ~/.config/omarchy/plugins/omarchy.vibe/
   ```
2. Enable the plugin:
   ```sh
   omarchy plugin enable omarchy.vibe
   ```

## Usage

### Bar Widget
- **Left-click**: Opens the agent panel with usage statistics
- **Right-click**: Launches Vibe CLI directly
- **Middle-click**: Cycles through available providers (if multiple)

### Panel Features
The panel displays:
- **Hero Section**: Vibe CLI icon (⚡) and status
- **Status**: Configuration status message
- **Limits**: Session and weekly usage limits with reset timers
- **Tokens by Day**: Daily token usage for the past week
- **Tokens by Model**: Token usage breakdown by Mistral model
- **Set as Default Agent**: Button to set Vibe CLI as the default agent

### Commands
- Set as default agent: `omarchy default agent vibe`
- Launch Vibe CLI: `vibe`

## Configuration

To use Vibe CLI as an agent in Omarchy, ensure:
1. Vibe CLI is installed and available in your `PATH`
2. The plugin is enabled in Omarchy

## Requirements
- Omarchy (Quattro shell)
- Vibe CLI installed and accessible

## License
MIT
