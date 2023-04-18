-- Check whether the MMS API has been enabled by the plugin

if script:FindFirstChild("MockMessagingService") == nil then
	return game:GetService("MessagingService")
else
	warn("INFO: Using MockMessagingService instead of MessagingService")
	return require(script.MockMessagingService)
end