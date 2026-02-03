local SERVER_URL = "https://YOUR_REPLIT_URL"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptPresenceUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 400)
Frame.Position = UDim2.new(1, -320, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.BorderSizePixel = 0
Title.Text = "🟢 Script Users Online"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 50)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Connecting..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -20, 1, -90)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 80)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.Parent = Frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.Name
UIListLayout.Parent = ScrollingFrame

local connectedUsers = {}
local isRunning = true
local sessionId = HttpService:GenerateGUID(false)

local function createUserEntry(username, userId)
    local UserFrame = Instance.new("Frame")
    UserFrame.Size = UDim2.new(1, 0, 0, 35)
    UserFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    UserFrame.BorderSizePixel = 0
    UserFrame.Name = "User_" .. userId
    
    local UserCorner = Instance.new("UICorner")
    UserCorner.CornerRadius = UDim.new(0, 6)
    UserCorner.Parent = UserFrame
    
    local UserLabel = Instance.new("TextLabel")
    UserLabel.Size = UDim2.new(1, -15, 1, 0)
    UserLabel.Position = UDim2.new(0, 10, 0, 0)
    UserLabel.BackgroundTransparency = 1
    UserLabel.Text = "🟢 " .. username
    UserLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    UserLabel.TextSize = 13
    UserLabel.Font = Enum.Font.Gotham
    UserLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserLabel.Parent = UserFrame
    
    UserFrame.Parent = ScrollingFrame
    return UserFrame
end

local function updateUI()
    local count = 0
    for _ in pairs(connectedUsers) do
        count = count + 1
    end
    
    Title.Text = string.format("🟢 Script Users Online (%d)", count)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

local function makeRequest(endpoint, method, body)
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = SERVER_URL .. endpoint,
            Method = method or "GET",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body and HttpService:JSONEncode(body) or nil
        })
    end)
    
    if success and result.Success then
        return true, result.Body
    else
        return false, result
    end
end

local function registerWithServer()
    local success, response = makeRequest("/join", "POST", {
        username = LocalPlayer.Name,
        userId = tostring(LocalPlayer.UserId),
        sessionId = sessionId
    })
    
    if success then
        StatusLabel.Text = "Connected!"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        return true
    else
        StatusLabel.Text = "Connection Failed"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return false
    end
end

local function pollServer()
    while isRunning do
        local success, response = makeRequest("/poll?sessionId=" .. sessionId, "GET")
        
        if success then
            local data = HttpService:JSONDecode(response)
            
            local newUsers = {}
            for _, user in pairs(data.users or {}) do
                newUsers[user.userId] = true
                
                if not connectedUsers[user.userId] then
                    local displayName = user.username
                    if user.userId == tostring(LocalPlayer.UserId) then
                        displayName = displayName .. " (You)"
                    end
                    
                    connectedUsers[user.userId] = {
                        username = user.username,
                        frame = createUserEntry(displayName, user.userId)
                    }
                    
                    if user.userId ~= tostring(LocalPlayer.UserId) then
                        print("🟢 " .. user.username .. " is now using the script!")
                    end
                end
            end
            
            for userId, userData in pairs(connectedUsers) do
                if not newUsers[userId] then
                    if userData.frame then
                        userData.frame:Destroy()
                    end
                    if userId ~= tostring(LocalPlayer.UserId) then
                        print("🔴 " .. userData.username .. " stopped using the script")
                    end
                    connectedUsers[userId] = nil
                end
            end
            
            updateUI()
        end
        
        task.wait(3)
    end
end

local function unregisterFromServer()
    makeRequest("/leave", "POST", {
        sessionId = sessionId
    })
end

task.spawn(function()
    task.wait(1)
    
    if registerWithServer() then
        print("✅ Script Presence Detector loaded!")
        print("👤 You are: " .. LocalPlayer.Name)
        
        task.spawn(pollServer)
    else
        warn("❌ Failed to connect to server!")
        warn("Make sure you've updated SERVER_URL in the script")
    end
end)

ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui:IsDescendantOf(game) then
        isRunning = false
        unregisterFromServer()
        print("Script unloaded")
    end
end)

task.spawn(function()
    while isRunning do
        task.wait(25)
        makeRequest("/heartbeat", "POST", {
            sessionId = sessionId
        })
    end
end)
