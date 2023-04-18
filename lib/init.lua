-- Check if we are in a prod environment or if the plugin has enabled the mock API

if game.JobId ~= "" or script:FindFirstChild("MockMessagingService") == nil then
	return game:GetService("MessagingService")
else
	warn("INFO: Using MockMessagingService instead of MessagingService")
	return require(script.MockMessagingService)
end