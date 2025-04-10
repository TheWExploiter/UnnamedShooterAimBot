local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
local aimRadius = 45

-- Create Hitbox
local hitbox = Instance.new("Part")
hitbox.Shape = Enum.PartType.Ball
hitbox.Anchored = true
hitbox.CanCollide = false
hitbox.Material = Enum.Material.ForceField
hitbox.Transparency = 0.7
hitbox.Color = Color3.fromRGB(0, 255, 0)
hitbox.Size = Vector3.new(aimRadius * 2, aimRadius * 2, aimRadius * 2)
hitbox.Parent = workspace

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

-- Auto-manage ESP for players joining/leaving
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Setup ESP for players already in-game
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

-- Check if player is alive
local function isAlive(player)
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead
end

-- Get closest target in 3D space (removing vertical tolerance)
local function getClosestPlayer()
    local closest = nil
    local shortestDist = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local distance = (theirRoot.Position - myRoot.Position).Magnitude
                if distance <= aimRadius then
                    if distance < shortestDist then
                        shortestDist = distance
                        closest = player
                    end
                end
            end
        end
    end

    return closest
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    hitbox.Position = myRoot.Position

    -- Update ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local espGui = espFolder:FindFirstChild(player.Name)
            local char = player.Character
            local head = char and char:FindFirstChild("Head")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if espGui and head and root and isAlive(player) then
                espGui.Adornee = head
                local dist = (myRoot.Position - root.Position).Magnitude
                espGui.TextLabel.Text = player.Name .. " | " .. math.floor(dist) .. " studs"
                espGui.Enabled = true
            elseif espGui then
                espGui.Enabled = false
            end
        end
    end

    -- Aimbot Aim: Always aim directly at the target's head, regardless of vertical difference.
    local target = getClosestPlayer()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local headPos = target.Character.Head.Position
        local cameraPos = Camera.CFrame.Position
        Camera.CFrame = CFrame.new(cameraPos, headPos)
    end
end)
