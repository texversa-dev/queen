local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "RizzHub",
    Icon = 0,
    LoadingTitle = "Rizzy",
    LoadingSubtitle = "by Unkown Rizzlers",
    ShowText = "RizzHub Loading...",
    Theme = "Ocean",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "RizzHub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

--// SERVICES AND VARIABLES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Banned IDs list (Players with these IDs are excluded from AimAssist and Chams)
local BannedIDs = {
    9258682584,
    9254579427, -- The specified user ID
}

-- AimAssist (MouseMoveRel) Variables
local AAssistEnabled = false
local AAFOVRadius = 200
local AimSpeed = 2 -- Lower = faster movement
local holdingRMB = false
local TargetLimb = "Head" -- Default target limb for AimAssist

-- Global Feature Variables
local ESPEnabled = false
local MasterDisabled = false
local WallCheckEnabled = true
local TeamCheckEnabled = false
local prevStates = {}
local ESPHighlights = {}

--// AIMASSIST FOV CIRCLE SETUP
local AACircle
if Drawing then
    AACircle = Drawing.new("Circle")
    AACircle.Visible = false
    AACircle.Color = Color3.fromRGB(255, 0, 0)
    AACircle.Thickness = 2
    AACircle.Filled = false
    AACircle.Radius = AAFOVRadius
end

-- Keep FOV circle centered
RunService.RenderStepped:Connect(function()
    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    
    if AACircle and AACircle.Visible then
        AACircle.Position = center
    end
end)

--// SHARED CORE FUNCTIONS

local function hasLineOfSight(origin, targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local direction = (targetPart.Position - origin)
    local result = workspace:Raycast(origin, direction, rayParams)
    
    if result and result.Instance then
        if not targetPart:IsDescendantOf(result.Instance) and result.Instance ~= targetPart then
            return false
        end
    end
    return true
end

local function getClosestPlayer(radius)
    local mousePos = Camera.ViewportSize / 2
    local closestTargetPart, closestDist = nil, math.huge
    local targetLimbName = (TargetLimb == "Head") and "Head" or "HumanoidRootPart" -- "Torso" maps to HumanoidRootPart

    for _, player in ipairs(Players:GetPlayers()) do
        -- Skip self
        if player == LocalPlayer then continue end
        -- Skip Banned IDs
        if table.find(BannedIDs, player.UserId) then continue end
        -- Skip Teammates
        if TeamCheckEnabled and player.Team == LocalPlayer.Team then continue end

        local character = player.Character
        local targetPart = character and character:FindFirstChild(targetLimbName)

        if targetPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                if dist < radius then
                    -- Wall Check
                    if WallCheckEnabled and hasLineOfSight(Camera.CFrame.Position, targetPart) or not WallCheckEnabled then
                        if dist < closestDist then
                            closestDist = dist
                            closestTargetPart = targetPart
                        end
                    end
                end
            end
        end
    end
    return closestTargetPart
end

local function aimAt(targetPos)
    local mousePos = Camera.ViewportSize / 2
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if not onScreen then return end

    local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos
    local moveX = delta.X / AimSpeed
    local moveY = delta.Y / AimSpeed

    if mousemoverel then
        mousemoverel(moveX, moveY)
    end
end

-- Input handling for Right Mouse Button (RMB) for AimAssist
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRMB = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingRMB = false
    end
end)

--// UI CREATION

-- Main Tab (Notification)
Rayfield:Notify({
    Title = "Notification",
    Content = "Thank you for using RizzHub",
    Duration = 6.5,
    Image = 4483362458,
})

--// AimAssist (MouseMoveRel) Tab
local AATab = Window:CreateTab("AimAssist", 4483362458)

local AAssistToggle = AATab:CreateToggle({
    Name = "Enable AimAssist (RMB)",
    CurrentValue = false,
    Flag = "AAssistToggle",
    Callback = function(Value)
        AAssistEnabled = Value
        if AACircle then
            AACircle.Visible = Value
        end
    end,
})

AATab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso"},
    CurrentOption = TargetLimb,
    Flag = "TargetPart",
    Callback = function(Value)
        TargetLimb = Value
    end,
})

local AARadiusSlider = AATab:CreateSlider({
    Name = "AimAssist FOV",
    Range = {0, 300},
    Increment = 5,
    Suffix = "px",
    CurrentValue = AAFOVRadius,
    Flag = "AARadiusSlider",
    Callback = function(Value)
        AAFOVRadius = Value
        if AACircle then
            AACircle.Radius = Value
        end
    end,
})

local AASmoothSlider = AATab:CreateSlider({
    Name = "Aim Speed (Lower = Faster)",
    Range = {0.5, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = AimSpeed,
    Flag = "AASmoothSlider",
    Callback = function(Value)
        AimSpeed = Value
    end,
})

AATab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = WallCheckEnabled,
    Flag = "AWallCheck",
    Callback = function(Value)
        WallCheckEnabled = Value
    end,
})

AATab:CreateToggle({
    Name = "Team Check",
    CurrentValue = TeamCheckEnabled,
    Flag = "ATeamCheck",
    Callback = function(Value)
        TeamCheckEnabled = Value
    end,
})


--// Chams ESP Tab
local ESPTab = Window:CreateTab("Chams", 4483362458)

local function applyChams(character)
    if ESPHighlights[character] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "RizzChams"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = workspace
    ESPHighlights[character] = highlight
end

local function removeChams(character)
    if ESPHighlights[character] then
        ESPHighlights[character]:Destroy()
        ESPHighlights[character] = nil
    end
end

local ESPToggle = ESPTab:CreateToggle({
    Name = "Chams",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        ESPEnabled = Value
    end,
})

-- ESP highlight update
RunService.RenderStepped:Connect(function()
    if ESPEnabled and not MasterDisabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            -- Skip Banned IDs
            if table.find(BannedIDs, player.UserId) then 
                removeChams(player.Character)
                continue 
            end
            if TeamCheckEnabled and player.Team == LocalPlayer.Team then continue end

            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char.PrimaryPart then
                applyChams(char)
            else
                removeChams(char)
            end
        end
    else
        for character, highlight in pairs(ESPHighlights) do
            removeChams(character)
        end
    end
end)

--// Settings Tab
local MainTab = Window:CreateTab("Settings", 4483362458)

-- Master Disable toggle
local MasterToggle = MainTab:CreateToggle({
    Name = "Master Disable",
    CurrentValue = false,
    Flag = "MasterDisable",
    Callback = function(Value)
        MasterDisabled = Value
        if MasterDisabled then
            prevStates = {
                AAssistEnabled = AAssistEnabled,
                ESPEnabled = ESPEnabled,
                WallCheckEnabled = WallCheckEnabled,
                TeamCheckEnabled = TeamCheckEnabled
            }
            AAssistToggle:Set(false)
            ESPToggle:Set(false)
        else
            AAssistToggle:Set(prevStates.AAssistEnabled)
            ESPToggle:Set(prevStates.ESPEnabled)
        end
    end,
})

-- Unload Button
local UnloadButton = MainTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        AAssistToggle:Set(false)
        ESPToggle:Set(false)
        MasterToggle:Set(false)

        for character, highlight in pairs(ESPHighlights) do
            removeChams(character)
        end
        if AACircle then AACircle:Remove() end
        Window:Destroy()
        Rayfield = nil
        print("RizzHub Unloaded")
    end
})

--// CORE AIMBOT LOGIC

-- AimAssist (MouseMoveRel) Logic
RunService.RenderStepped:Connect(function()
    if AAssistEnabled and holdingRMB and not MasterDisabled then
        local targetPart = getClosestPlayer(AAFOVRadius) 
        if targetPart then
            aimAt(targetPart.Position)
        end
    end
end)