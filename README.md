# bc_carryandhideintrunk

This resource provides a carry and trunk script for FiveM using QBCore. It includes:

- A client-side script (`client.lua`)
- A server-side script (`server.lua`) with Discord webhook logging
- A separate Discord webhook module (`discord_webhook.lua`)
- A configuration file (`config.lua`)

## Installation

1. Place the resource folder in your server's resources directory.
2. Add `ensure bc_carryandhideintrunk` (or your resource name) to your server.cfg.
3. Configure your webhook URL, bot name, and embed color in `discord_webhook.lua`.
4. Adjust other settings in `config.lua` as needed.

## Features

- Carry players and hide them in trunks.
- Discord webhook logging for carry events.
- Custom keybinds and command-based interactions.

## License

- GNU GENERAL PUBLIC LICENSE
- Version 3, 29 June 2007
