if not plugin then return end

-- ################## UI Logic ##################
local toolbar = plugin:CreateToolbar("MockMessagingService plugin")
local enabled = false

local function _remove()
    if game.ServerScriptService.MessagingService:FindFirstChild("MockMessagingService") ~= nil then
        game.ServerScriptService.MessagingService.MockMessagingService:Destroy()
    end
end

local function _clone()
    _remove()
    local clone = script.Parent.MessagingService.MockMessagingService:Clone()
    clone.Parent = game.ServerScriptService.MessagingService
end

-- TODO: proper icon
local toggleButton = toolbar:CreateButton("Toggle MMS", "Enables or disables MockMessagingService", "rbxassetid://484838285")
toggleButton.ClickableWhenViewportHidden = true

-- if it's a brand new project that has never been exposed to MMS before
-- we only want to copy the "require" script, but not the actual library.
-- otherwise we check if MMS is already enabled and set the plugin state accordingly
if game.ServerScriptService:FindFirstChild("MessagingService") == nil then
    local clone = script.Parent.MessagingService:Clone()
    clone.Parent = game.ServerScriptService
    game.ServerScriptService.MessagingService.MockMessagingService:Destroy()
elseif game.ServerScriptService.MessagingService:FindFirstChild("MockMessagingService") ~= nil then 
    enabled = true 
end

local function toggleButtonClicked()
    enabled = not enabled

    if enabled then _clone() else _remove() end
end

toggleButton.Click:Connect(toggleButtonClicked)

-- ################## Data exchange logic ##################
local MMS = game.ServerScriptService:WaitForChild("MessagingService"):WaitForChild("MockMessagingService")

local publishRequest: BindableEvent = MMS:WaitForChild("PublishRequest")
local subscribeRequest: BindableEvent = MMS:WaitForChild("SubscribeRequest")

local subscribedTopics = {}

local function _elapsedSeconds(lastTime)
    local currentTimestamp = os.time()
    return currentTimestamp - lastTime
end

local function _serverCount()
    return plugin:GetSetting("_serverCount") or 0
end

-- increase the number of servers currently using MMS by one
plugin:SetSetting("_serverCount", _serverCount() + 1)

--[[ Constraints:

        [Limit]	                                [Maximum]
    Size of message	                        1kB
    Messages sent per game server	        150 + 60 * (number of players in this game server) per minute
    Messages received per topic	            (10 + 20 * number of servers) per minute
    Messages received for entire game	    (100 + 50 * number of servers) per minute
    Subscriptions allowed per game server	5 + 2 * (number of players in this game server)

--]]
local Constraints = {
    sentMessages = {
        max = (150 + 60 * #game.Players:GetPlayers()) / 60,
        count = 0,
        lastTime = os.time()
    },
    subscriptions = {
        max = 5 + 2 * #game.Players:GetPlayers(),
        count = 0
    },
    receivedMessagesTopic = {
        max = (10 + 20 * _serverCount()) / 60,
        count = 0,
        lastTime = os.time()
    },
    receivedMessagesTotal = {
        max = (100 + 50 * _serverCount()) / 60,
        count = 0,
        lastTime = os.time()
    },
    maxTopicLength = 80
}

publishRequest.Event:Connect(function (topic: string, message)
    -- check if topic length exceeds 80 chars
    if string.len(topic) > Constraints.maxTopicLength then
        error("Topic length exceeds 80 characters")
    end

    -- check if message size exceeds 1kB
    if string.len(tostring(message)) > 1024 then
        error("Message size exceeds 1kB")
    end

    -- check if message limit per game server is reached
    Constraints.sentMessages.count += 1
    local elapsed = _elapsedSeconds(Constraints.sentMessages.lastTime)
    if Constraints.sentMessages.count > Constraints.sentMessages.max * elapsed then
        error("Message limit per game server per minute reached")
    end

    -- plugin:SetSetting hits disc instead of memory, so it can be slow. Spawn so we don't hang.
    task.spawn(plugin.SetSetting, plugin, topic, message)

    Constraints.lastTimestamp = os.time()
end)

subscribeRequest.Event:Connect(function (topic: string)
    -- check if topic length exceeds 80 chars
    if string.len(topic) > Constraints.maxTopicLength then
        error("Topic length exceeds 80 characters")
    end

    -- check if already subscribed to topic
    if subscribedTopics[topic] ~= nil then return end

    -- check if subscription limit per game server is reached
    Constraints.subscriptions.count += 1
    if Constraints.subscriptions.count >= Constraints.subscriptions.max then
        error("Subscription limit per game server reached")
    end

    table.insert(subscribedTopics, topic)

    Constraints.lastTimestamp = os.time()
end)

game:GetService("RunService").Heartbeat:Connect(function()
    -- Check if message limit for entire game is reached
    local elapsed = _elapsedSeconds(Constraints.receivedMessagesTotal.lastTime)
    if Constraints.receivedMessagesTotal.count >= Constraints.receivedMessagesTotal.max * elapsed then
        return
    end

    for i, topic in ipairs(subscribedTopics) do
        -- check if message limit per topic is reached
        local elapsed = _elapsedSeconds(Constraints.receivedMessagesTopic.lastTime)
        if Constraints.receivedMessagesTopic.count >= Constraints.receivedMessagesTopic.max * elapsed then
            continue
        end

        local data = plugin:GetSetting(topic)
        if data then
            -- we want to clear the setting field even if there's
            -- no one subscribed to this topic ready to accept the data
            task.spawn(plugin.SetSetting, plugin, topic, nil)

            local callback: BindableEvent = MMS:WaitForChild(topic .. "_CallbackEvent")
            callback:Fire(data)
        end
    end
end)

-- ################## Unloading ##################
plugin.Unloading:Connect(function()
    plugin:SetSetting("_serverCount", _serverCount() - 1)

    enabled = false
    _remove()
end)