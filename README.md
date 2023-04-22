# MockMessagingService
This Roblox Studio plugin provides a localhost alternative to the MessagingService Roblox API.
It is currently impossible to communicate across locally-running Roblox servers on your machine through the provided MS API, unless you were to create a secondary place under the same universe of your main one. This, however did not cover my specific use case and I therefore decided to engineer a hacky alternative.

## Installation
Copy the `MockMessagingService.rbxm` file to your Roblox Studio plugin folder (`%LOCALAPPDATA%/Roblox/Plugins/MockMessagingService.rbxm` on Windows).

You can either download the plugin from the GitHub releases page or build it yourself using Rojo: `rojo build -o MockMessagingService.rbxm`.

## Usage
In order to enable your Roblox projects to interact with this mock API you will need to:
 - Open a Roblox Studio project of your choice (NOTE: The library will be automatically injected inside of `ServerScriptService`)
 - Head to the plugins tab
 - Click on the button labeled "Toggle MMS" (You might see a WARNING in the console, it's on the TODO list, ignore)
 - To invoke the API in your code you will first import it with `local MS = require(game.ServerScriptService.MessagingService)` (Your code will automatically know to use the real MessagingService API when the plugin is disabled or in a producation environment)
 - Enjoy MMS!

## Example
This code belongs in a server-side script:
```lua
local MS = require(game.ServerScriptService.MessagingService)

MS:SubscribeAsync("MMS-Test", function(data)
	print("Received data: " .. data)
end)
```

This code can exist in a different locally-running Roblox server instance:
```lua
local MS = require(game.ServerScriptService.MessagingService)

MS:PublishAsync("MMS-Test", "Hello world!")
```

Expected output (in the console of your first script):
```
Received data: Hello world!
```

## How it works
MockMessagingService takes advantage of the plugin `settings.json` file. The service writes incoming topic messages in specific setting fiels, and at the same time it listens for any changes to the fields of subscribed topics so it can relay them to the game. Due to this file being shared across all active Roblox Studio instances, data is able to travel across the sandbox boundaries. 
Communication between the plugin and game scripts is achieved through `BindableEvents`.

## Building and contributing
This project uses Rojo to manage its structure and perform builds.

Use this bash command to quickly deploy the plugin in your Roblox Studio environment:
`rojo build -o $LOCALAPPDATA/Roblox/Plugins/MockMessagingService.rbxm`
