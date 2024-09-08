local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local MAX_TEXT_SIZE = 2
local MIN_TEXT_SIZE = 1
local TEXT_SIZE_INCREMENT = 1
local MAX_DISTANCE = 250
local MIN_DISTANCE = 10
local REFRESH_INTERVAL = 5 -- Time in seconds to refresh all GUIs

-- Function to calculate player account age
local function getPlayerAge(player)
    local accountAgeDays = player.AccountAge
    local currentYear = os.date("*t").year
    local accountCreationDate = tick() - accountAgeDays * 86400
    local accountCreationYear = os.date("*t", accountCreationDate).year
    return currentYear - accountCreationYear
end

-- Function to remove existing GUIs and highlights from a character
local function clearGUIs(character)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BillboardGui") or child:IsA("Highlight") then
            child:Destroy()
        end
    end
end

-- Function to create a health bar for a player
local function createHealthBar(player)
    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end

    local healthGui = Instance.new("BillboardGui")
    healthGui.Parent = humanoidRootPart
    healthGui.Size = UDim2.new(6, 0, 0.5, 0)
    healthGui.StudsOffset = Vector3.new(0, -2, 0)
    healthGui.AlwaysOnTop = true
    healthGui.MaxDistance = MAX_DISTANCE

    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Parent = healthGui
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    backgroundFrame.BackgroundTransparency = 0.5

    local healthFrame = Instance.new("Frame")
    healthFrame.Parent = backgroundFrame
    healthFrame.Size = UDim2.new(1, 0, 1, 0)
    healthFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFrame.BackgroundTransparency = 0.3

    humanoid.HealthChanged:Connect(function(health)
        local healthPercent = health / humanoid.MaxHealth
        healthFrame.Size = UDim2.new(healthPercent, 0, 1, 0)
    end)
end

-- Function to update text size based on distance
local function updateTextSize(billboardGui, distance)
    local scale = math.clamp((distance - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE), 0, 1)
    local textSize = MIN_TEXT_SIZE + scale * TEXT_SIZE_INCREMENT

    for _, child in ipairs(billboardGui:GetChildren()) do
        if child:IsA("TextLabel") then
            -- Update the size of the age label only
            if child.Name == "AgeLabel" then
                child.TextSize = textSize
            end
        end
    end
end

-- Function to highlight a player and show their name and age
local function highlightPlayer(player)
    local character = player.Character
    if not character then return end

    -- Skip highlighting local player's character
    if player == Players.LocalPlayer then
        clearGUIs(character) -- Clear old GUIs and highlights
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        -- Create highlight for local player's character
        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.FillColor = Color3.fromRGB(255, 255, 255) -- White fill color
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- White outline color
        highlight.OutlineTransparency = 0 -- Fully visible outline
        highlight.FillTransparency = 0.5 -- Slightly transparent fill
    else
        -- Remove any existing highlight if present
        clearGUIs(character)

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local localPlayer = Players.LocalPlayer
        if not humanoidRootPart or not localPlayer then return end

        -- Create highlight for other players' characters
        local highlight = Instance.new("Highlight")
        highlight.Parent = character

        -- Check if the player is a friend of the local player
        local isFriend = localPlayer:IsFriendsWith(player.UserId)
        if isFriend then
            -- Highlight friends in green
            highlight.FillColor = Color3.fromRGB(0, 0, 255) -- Blue fill color for friends
            highlight.OutlineColor = Color3.fromRGB(0, 255, 255) -- Cyan outline color for friends
        else
            -- Highlight other players in red
            highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red fill color for other players
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- Yellow outline color for other players
        end

        -- Create name and age GUI
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Parent = humanoidRootPart
        billboardGui.Size = UDim2.new(10, 0, 2, 0)
        billboardGui.StudsOffset = Vector3.new(0, -0.5, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.MaxDistance = MAX_DISTANCE

        local frame = Instance.new("Frame")
        frame.Parent = billboardGui
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1

        -- Name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Parent = frame
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.Text = player.Name
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextTransparency = 0.3
        nameLabel.TextScaled = false

        -- Age label
        local ageLabel = Instance.new("TextLabel")
        ageLabel.Name = "AgeLabel"
        ageLabel.Parent = frame
        ageLabel.Size = UDim2.new(1, 0, 0.3, 0)
        ageLabel.Position = UDim2.new(0, 0, 0.3, 0)
        ageLabel.Text = "Account Age: " .. getPlayerAge(player)
        ageLabel.BackgroundTransparency = 1
        ageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ageLabel.TextStrokeTransparency = 0
        ageLabel.TextTransparency = 0.3
        ageLabel.TextScaled = true

        createHealthBar(player)

        -- Update text size based on distance
        RunService.RenderStepped:Connect(function()
            if not localPlayer.Character then return end
            local localHumanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not localHumanoidRootPart then return end

            local distance = (localHumanoidRootPart.Position - humanoidRootPart.Position).magnitude
            updateTextSize(billboardGui, distance)
        end)
    end
end

-- Function to handle when a character is added
local function onCharacterAdded(player)
    local character = player.Character or player.CharacterAdded:Wait()
    if character then
        character:WaitForChild("HumanoidRootPart")
        character:WaitForChild("Humanoid")
        highlightPlayer(player)
    end
end

-- Function to refresh GUIs periodically
local function refreshGUIs()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                highlightPlayer(player)
            end
        end
        wait(REFRESH_INTERVAL)
    end
end

-- Main function to initialize everything
local function initialize()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            onCharacterAdded(player)
        end)
    end)

    -- Initialize for all existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            onCharacterAdded(player)
        end
    end

    -- Start refreshing GUIs
    refreshGUIs()
end

-- Run the initialization function
initialize()