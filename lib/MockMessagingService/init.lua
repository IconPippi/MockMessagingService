local MockMessagingService = {}

--[[ TODO constraints:

        [Limit]	                                [Maximum]
    Size of message	                        1kB
    Messages sent per game server	        150 + 60 * (number of players in this game server) per minute
    Messages received per topic	            (10 + 20 * number of servers) per minute
    Messages received for entire game	    (100 + 50 * number of servers) per minute
    Subscriptions allowed per game server	5 + 2 * (number of players in this game server)

--]]

local function _getOrNew(name)
    local rq = script:FindFirstChild(name, false)

    if not rq then
        rq = Instance.new("BindableEvent")
        rq.Parent = script
        rq.Name = name
    end
    return rq
end

local publishRequest: BindableEvent = _getOrNew("PublishRequest")
local subscribeRequest: BindableEvent = _getOrNew("SubscribeRequest")

function MockMessagingService:PublishAsync(topic: string, message)
    publishRequest:Fire(topic, message)
end

function MockMessagingService:SubscribeAsync(topic: string, callback): RBXScriptConnection
    local callbackEvent = Instance.new("BindableEvent")
    callbackEvent.Parent = script
    callbackEvent.Name = topic .. "_CallbackEvent"

    subscribeRequest:Fire(topic)
    
    return callbackEvent.Event:Connect(callback)
end

return MockMessagingService