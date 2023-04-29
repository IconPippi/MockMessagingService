local MockMessagingService = {}

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
    local callbackEvent: BindableEvent = Instance.new("BindableEvent")
    callbackEvent.Parent = script
    callbackEvent.Name = topic .. "_CallbackEvent"

    subscribeRequest:Fire(topic)
    
    return callbackEvent.Event:Connect(callback)
end

return MockMessagingService