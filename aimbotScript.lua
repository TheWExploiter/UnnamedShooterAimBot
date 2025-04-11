local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
local aimRadius = 35.5
local aimHeightTolerance = 7.5  -- Only target players within 10 studs of height difference

-- Create ESP Management
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

-- Get closest target on same XZ level within height tolerance
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

                if horizontalDist <= aimRadius and deltaY <= aimHeightTolerance then
                    if horizontalDist < shortestDist then
                        shortestDist = horizontalDist
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
                espGui.TextLabel.Text = player.Name .. " | " .. math.floor(dist) .. " studs away"
                espGui.Enabled = true
            elseif espGui then
                espGui.Enabled = false
            end
        end
    end

    -- Aimbot Aim
    local target = getClosestHorizontalPlayer()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local tPos = target.Character.Head.Position
        local cPos = Camera.CFrame.Position

        -- Calculate horizontal position (XZ plane) for smooth aiming
        local horizontalTarget = Vector3.new(tPos.X, cPos.Y, tPos.Z)

        -- Aim at the target's head position by adjusting both horizontal and vertical angles
        local direction = (tPos - cPos).unit -- Normalized direction vector to the target
        local targetCFrame = CFrame.new(cPos, cPos + direction) -- Adjust the CFrame based on the direction
        Camera.CFrame = targetCFrame
    end
end)
