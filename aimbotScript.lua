local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "Aimbot Script | By Cat",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "AimbotCatConfig",
    IntroEnabled = true,
    IntroText = "Aimbot Script | By Cat",
    CloseCallback = function() end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Default settings
local aimbotEnabled = false
local espEnabled = false
local aimRadius = 35.5
local aimHeightTolerance = 7.5

-- UI Tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(v)
        aimbotEnabled = v
    end
})

MainTab:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(v)
        espEnabled = v
    end
})

MainTab:AddTextbox({
    Name = "Aimbot Radius",
    Default = tostring(aimRadius),
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            aimRadius = num
        end
    end
})

MainTab:AddTextbox({
    Name = "Height Tolerance",
    Default = tostring(aimHeightTolerance),
    TextDisappear = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            aimHeightTolerance = num
        end
    end
})

-- ESP Management
local espFolder = Instance.new("Folder")
espFolder.Name = "MaxV5_ESP"
espFolder.Parent = game.CoreGui

local function createESP(player)
    local esp = Instance.new("BillboardGui")
    esp.Name = player.Name
    esp.AlwaysOnTop = true
    esp.Size = UDim2.new(0, 100, 0, 30)
    esp.StudsOffset = Vector3.new(0, 3, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = ""
    label.Parent = esp

    esp.Parent = espFolder
end

local function removeESP(player)
    local gui = espFolder:FindFirstChild(player.Name)
    if gui then
        gui:Destroy()
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

local function isAlive(player)
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead
end

local function getClosestHorizontalPlayer()
    local closest = nil
    local shortestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if theirRoot and myRoot then
                local deltaY = math.abs(theirRoot.Position.Y - myRoot.Position.Y)
                local horizontalDist = (Vector3.new(theirRoot.Position.X, 0, theirRoot.Position.Z) - Vector3.new(myRoot.Position.X, 0, myRoot.Position.Z)).Magnitude

                -- Check team only if both players are on a team
                local isSameTeam = (player.Team == LocalPlayer.Team)
                if (player.Team and isSameTeam) or not player.Team then
                    if horizontalDist <= aimRadius and deltaY <= aimHeightTolerance then
                        if horizontalDist < shortestDist then
                            shortestDist = horizontalDist
                            closest = player
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- Main loop
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- ESP Updates
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local espGui = espFolder:FindFirstChild(player.Name)
            local char = player.Character
            local head = char and char:FindFirstChild("Head")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if espGui and head and root and hum and isAlive(player) then
                espGui.Adornee = head
                local healthPercent = math.floor((hum.Health / hum.MaxHealth) * 100)
                espGui.TextLabel.Text = player.Name .. " | " .. math.floor((myRoot.Position - root.Position).Magnitude) .. " studs | " .. healthPercent .. "% HP"
                espGui.Enabled = espEnabled
            elseif espGui then
                espGui.Enabled = false
            end
        end
    end

    -- Aimbot Updates
    if aimbotEnabled then
        local target = getClosestHorizontalPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local tPos = target.Character.Head.Position
            local cPos = Camera.CFrame.Position
            local direction = (tPos - cPos).Unit
            Camera.CFrame = CFrame.new(cPos, cPos + direction)
        end
    end
end)
