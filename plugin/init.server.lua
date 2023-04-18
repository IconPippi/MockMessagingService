if not plugin then return end

-- ################## UI Logic ##################
local toolbar = plugin:CreateToolbar("MockMessagingService plugin")
local enabled = false

function _clone()
    _remove()
    local clone = script.Parent.MessagingService.MockMessagingService:Clone()
    clone.Parent = game.ServerScriptService.MessagingService
end

function _remove()
    if game.ServerScriptService.MessagingService:FindFirstChild("MockMessagingService") ~= nil then
        game.ServerScriptService.MessagingService.MockMessagingService:Destroy()
    end
end

-- TODO: proper icon
local toggleButton = toolbar:CreateButton("Toggle MMS", "Enables or disables MockMessagingService", "rbxassetid://484838285")
toggleButton.ClickableWhenViewportHidden = true

-- if it's a brand new project that has never been exposed to MMS before
-- we only want to copy the "require" script, but not the actual library
if game.ServerScriptService:FindFirstChild("MessagingService") == nil then
    local clone = script.Parent.MessagingService:Clone()
    clone.Parent = game.ServerScriptService
    game.ServerScriptService.MessagingService.MockMessagingService:Destroy()
end

local function toggleButtonClicked()
    enabled = not enabled

    if enabled then _clone() else _remove() end
end

toggleButton.Click:Connect(toggleButtonClicked)

plugin.Unloading:Connect(function()
    enabled = false
    _remove()
end)

-- ################## Data exchange logic ##################
local MMS = game.ServerScriptService:WaitForChild("MessagingService"):WaitForChild("MockMessagingService")

local publishRequest: BindableEvent = MMS:WaitForChild("PublishRequest")
local subscribeRequest: BindableEvent = MMS:WaitForChild("SubscribeRequest")

local subscribedTopics = {}

publishRequest.Event:Connect(function (topic: string, message)
    -- plugin:SetSetting hits disc instead of memory, so it can be slow. Spawn so we don't hang.
    task.spawn(plugin.SetSetting, plugin, topic, message)
end)

subscribeRequest.Event:Connect(function (topic: string)
    table.insert(subscribedTopics, topic)
end)

game:GetService("RunService").Heartbeat:Connect(function()
    for i, topic in ipairs(subscribedTopics) do
        local data = plugin:GetSetting(topic)
        if data then
            local callback: BindableEvent = MMS:WaitForChild(topic .. "_CallbackEvent")
            callback:Fire(data)
            plugin:SetSetting(topic, nil)
        end
    end
end)