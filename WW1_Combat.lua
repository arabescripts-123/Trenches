-- WW1 Combat Script (Abas: Combat + Others)
local player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

repeat task.wait() until player.Character or player.CharacterAdded:Wait()
task.wait(0.5)

local guiParent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
pcall(function() local e = guiParent:FindFirstChild("WW1Gui") if e then e:Destroy() end end)
task.wait(0.2)

-- CONFIG
local AIM_FOV = 300

-- STATE
local espEnabled, aimbotEnabled = false, false
local rightMouseDown = false
local espBoxes, espConnections = {}, {}
local clickTpEnabled = false
local ghostEnabled = false
local ghostPart, ghostConnection, ghostOverlay, originalCFrame = nil, nil, nil, nil
local ghostSpeed = 65

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WW1Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 25)
MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 360)
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local s = Instance.new("UIStroke", MainFrame)
s.Color = Color3.fromRGB(80, 60, 30)
s.Thickness = 2

-- Title
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -40, 0, 32)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "  WW1 Script"
Title.TextColor3 = Color3.fromRGB(220, 190, 130)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true

-- Rejoin
local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Parent = MainFrame
rejoinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
rejoinBtn.Position = UDim2.new(1, -35, 0, 3)
rejoinBtn.Size = UDim2.new(0, 28, 0, 26)
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.Text = "R"
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.TextSize = 13
Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 6)
rejoinBtn.MouseButton1Click:Connect(function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
end)

-- Drag
local dragging, dragInput, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
Title.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ============ TABS ============
local TabsFrame = Instance.new("Frame")
TabsFrame.Parent = MainFrame
TabsFrame.BackgroundTransparency = 1
TabsFrame.Position = UDim2.new(0, 0, 0, 32)
TabsFrame.Size = UDim2.new(1, 0, 0, 28)

local function createTab(name, xPos)
    local t = Instance.new("TextButton")
    t.Parent = TabsFrame
    t.BackgroundColor3 = Color3.fromRGB(50, 45, 38)
    t.Position = UDim2.new(0, xPos, 0, 0)
    t.Size = UDim2.new(0, 105, 0, 26)
    t.Font = Enum.Font.GothamBold
    t.Text = name
    t.TextColor3 = Color3.fromRGB(200, 200, 200)
    t.TextSize = 12
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
    return t
end

local tabCombat = createTab("Combat", 10)
local tabOthers = createTab("Others", 120)

local ContentCombat = Instance.new("Frame")
ContentCombat.Parent = MainFrame
ContentCombat.BackgroundTransparency = 1
ContentCombat.Position = UDim2.new(0, 0, 0, 62)
ContentCombat.Size = UDim2.new(1, 0, 1, -62)
ContentCombat.Visible = true

local ContentOthers = Instance.new("Frame")
ContentOthers.Parent = MainFrame
ContentOthers.BackgroundTransparency = 1
ContentOthers.Position = UDim2.new(0, 0, 0, 62)
ContentOthers.Size = UDim2.new(1, 0, 1, -62)
ContentOthers.Visible = false

local function switchTab(active)
    ContentCombat.Visible = (active == "combat")
    ContentOthers.Visible = (active == "others")
    tabCombat.BackgroundColor3 = active == "combat" and Color3.fromRGB(80, 70, 50) or Color3.fromRGB(50, 45, 38)
    tabOthers.BackgroundColor3 = active == "others" and Color3.fromRGB(80, 70, 50) or Color3.fromRGB(50, 45, 38)
end
tabCombat.MouseButton1Click:Connect(function() switchTab("combat") end)
tabOthers.MouseButton1Click:Connect(function() switchTab("others") end)
switchTab("combat")

-- ============ HELPERS ============
local function createToggle(parent, text, yPos)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BackgroundColor3 = Color3.fromRGB(60, 55, 45)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.Size = UDim2.new(0, 210, 0, 30)
    btn.Font = Enum.Font.Gotham
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local ind = Instance.new("Frame")
    ind.Parent = btn
    ind.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    ind.Position = UDim2.new(1, -22, 0.5, -6)
    ind.Size = UDim2.new(0, 12, 0, 12)
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    return btn, ind
end

-- ============ ABA COMBAT ============
local espBtn, espInd = createToggle(ContentCombat, "ESP [J]", 0)
local aimBtn, aimInd = createToggle(ContentCombat, "Aimbot [X] (RMB)", 35)

-- FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Parent = ContentCombat
fovLabel.BackgroundTransparency = 1
fovLabel.Position = UDim2.new(0, 10, 0, 73)
fovLabel.Size = UDim2.new(0, 210, 0, 16)
fovLabel.Font = Enum.Font.Gotham
fovLabel.Text = "FOV: " .. AIM_FOV
fovLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
fovLabel.TextSize = 11
fovLabel.TextXAlignment = Enum.TextXAlignment.Left

local fovBox = Instance.new("TextBox")
fovBox.Parent = ContentCombat
fovBox.BackgroundColor3 = Color3.fromRGB(50, 45, 40)
fovBox.Position = UDim2.new(0, 10, 0, 91)
fovBox.Size = UDim2.new(0, 100, 0, 24)
fovBox.Font = Enum.Font.Gotham
fovBox.Text = tostring(AIM_FOV)
fovBox.TextColor3 = Color3.fromRGB(255, 255, 255)
fovBox.TextSize = 11
fovBox.ClearTextOnFocus = false
Instance.new("UICorner", fovBox).CornerRadius = UDim.new(0, 4)

fovBox.FocusLost:Connect(function()
    local n = tonumber(fovBox.Text)
    if n and n > 0 then AIM_FOV = n; fovLabel.Text = "FOV: " .. AIM_FOV
    else fovBox.Text = tostring(AIM_FOV) end
end)

-- Ghost TP
local ghostBtn, ghostInd = createToggle(ContentCombat, "Ghost TP [CapsLk]", 123)

-- Info
local infoLbl = Instance.new("TextLabel")
infoLbl.Parent = ContentCombat
infoLbl.BackgroundTransparency = 1
infoLbl.Position = UDim2.new(0, 10, 0, 160)
infoLbl.Size = UDim2.new(0, 210, 0, 20)
infoLbl.Font = Enum.Font.Gotham
infoLbl.Text = "Z=Menu | RMB=Aim | CapsLk=Ghost"
infoLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
infoLbl.TextSize = 10

-- ============ ABA OTHERS ============
-- Click TP
local ctpBtn, ctpInd = createToggle(ContentOthers, "Click TP [Q]", 0)

-- TP Players
local tpLabel = Instance.new("TextLabel")
tpLabel.Parent = ContentOthers
tpLabel.BackgroundTransparency = 1
tpLabel.Position = UDim2.new(0, 10, 0, 40)
tpLabel.Size = UDim2.new(0, 210, 0, 18)
tpLabel.Font = Enum.Font.GothamBold
tpLabel.Text = "TP Players:"
tpLabel.TextColor3 = Color3.fromRGB(200, 190, 150)
tpLabel.TextSize = 12
tpLabel.TextXAlignment = Enum.TextXAlignment.Left

local PlayerListScroll = Instance.new("ScrollingFrame")
PlayerListScroll.Parent = ContentOthers
PlayerListScroll.BackgroundColor3 = Color3.fromRGB(45, 40, 35)
PlayerListScroll.Position = UDim2.new(0, 10, 0, 60)
PlayerListScroll.Size = UDim2.new(0, 210, 0, 220)
PlayerListScroll.ScrollBarThickness = 4
PlayerListScroll.BorderSizePixel = 0
PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", PlayerListScroll).CornerRadius = UDim.new(0, 6)

local function updatePlayerList()
    for _, c in pairs(PlayerListScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local y = 4
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local f = Instance.new("Frame")
            f.Parent = PlayerListScroll
            f.BackgroundColor3 = Color3.fromRGB(60, 55, 48)
            f.Position = UDim2.new(0, 4, 0, y)
            f.Size = UDim2.new(1, -8, 0, 36)
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

            local img = Instance.new("ImageLabel")
            img.Parent = f
            img.BackgroundTransparency = 1
            img.Position = UDim2.new(0, 4, 0.5, -14)
            img.Size = UDim2.new(0, 28, 0, 28)
            img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48"
            Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)

            local lbl = Instance.new("TextLabel")
            lbl.Parent = f
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 36, 0, 0)
            lbl.Size = UDim2.new(1, -40, 1, 0)
            lbl.Font = Enum.Font.Gotham
            lbl.Text = plr.Name
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left

            local btn = Instance.new("TextButton")
            btn.Parent = f
            btn.BackgroundTransparency = 1
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.Text = ""
            btn.MouseButton1Click:Connect(function()
                pcall(function()
                    if player.Character and plr.Character then
                        local r = player.Character:FindFirstChild("HumanoidRootPart")
                        local t = plr.Character:FindFirstChild("HumanoidRootPart")
                        if r and t then r.CFrame = t.CFrame * CFrame.new(0, 0, 3) end
                    end
                end)
            end)
            y = y + 40
        end
    end
    PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, y + 4)
end

-- Auto-refresh player list
local lastRefresh = 0
RunService.Heartbeat:Connect(function()
    if ContentOthers.Visible and tick() - lastRefresh > 3 then
        lastRefresh = tick()
        updatePlayerList()
    end
end)

-- ============ TEAM DETECTION ============
local function isEnemy(otherPlayer)
    if not otherPlayer or otherPlayer == player then return false end
    if not otherPlayer.Character or not player.Character then return false end
    if not player.Team or not otherPlayer.Team then return true end
    return player.Team ~= otherPlayer.Team
end

-- ============ ESP ============
local function removeESP(key)
    if espBoxes[key] then
        for _, v in pairs(espBoxes[key]) do pcall(function() v:Destroy() end) end
        espBoxes[key] = nil
    end
    if espConnections[key] then espConnections[key]:Disconnect(); espConnections[key] = nil end
end

local function addESP(plr)
    if plr == player or not espEnabled then return end
    local function create(char)
        if not espEnabled or not char:FindFirstChild("Head") then return end
        pcall(function()
            for _, o in pairs(char:GetChildren()) do if o:IsA("Highlight") then o:Destroy() end end
            local enemy = isEnemy(plr)
            local color = enemy and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(0, 180, 0)
            local hl = Instance.new("Highlight")
            hl.FillColor = color; hl.OutlineColor = color
            hl.FillTransparency = enemy and 0.8 or 0.95
            hl.OutlineTransparency = enemy and 0.4 or 0.85
            hl.Adornee = char; hl.Parent = char
            local bb = Instance.new("BillboardGui")
            bb.Adornee = char.Head; bb.Size = UDim2.new(0, 120, 0, 40)
            bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = char.Head
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1
            l.Text = plr.Name .. (enemy and "" or " [ALLY]")
            l.TextColor3 = color; l.TextTransparency = enemy and 0 or 0.5
            l.TextStrokeTransparency = enemy and 0.3 or 0.8
            l.Font = Enum.Font.GothamBold; l.TextSize = 13; l.Parent = bb
            if not espBoxes[plr] then espBoxes[plr] = {} end
            table.insert(espBoxes[plr], hl); table.insert(espBoxes[plr], bb)
        end)
    end
    if plr.Character then create(plr.Character) end
    espConnections[plr] = plr.CharacterAdded:Connect(function(c) if espEnabled then task.wait(0.3); create(c) end end)
end

local function enableESP()
    for _, p in pairs(Players:GetPlayers()) do addESP(p) end
    espConnections._added = Players.PlayerAdded:Connect(function(p) if espEnabled then task.wait(0.5); addESP(p) end end)
    espConnections._removing = Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
    espConnections._refresh = RunService.Heartbeat:Connect(function()
        if espEnabled and tick() % 2 < 0.016 then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("Head") and (not espBoxes[p] or #espBoxes[p] == 0) then
                    removeESP(p); addESP(p)
                end
            end
        end
    end)
end

local function disableESP()
    for key in pairs(espBoxes) do removeESP(key) end
    for _, conn in pairs(espConnections) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end end
    espConnections = {}
end

-- ============ GHOST TP ============
local function enableGhostMode()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    originalCFrame = player.Character.HumanoidRootPart.CFrame
    local hum = player.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end

    ghostPart = Instance.new("Part")
    ghostPart.Name = "GhostPart"
    ghostPart.Shape = Enum.PartType.Ball
    ghostPart.Size = Vector3.new(4, 4, 4)
    ghostPart.Transparency = 0.3
    ghostPart.Color = Color3.fromRGB(255, 255, 255)
    ghostPart.Material = Enum.Material.Neon
    ghostPart.CanCollide = false
    ghostPart.Anchored = true
    ghostPart.CFrame = originalCFrame
    ghostPart.Parent = workspace

    ghostOverlay = Instance.new("Frame")
    ghostOverlay.Size = UDim2.new(1, 0, 1, 0)
    ghostOverlay.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
    ghostOverlay.BackgroundTransparency = 0.8
    ghostOverlay.BorderSizePixel = 0
    ghostOverlay.ZIndex = -1
    ghostOverlay.Parent = ScreenGui

    workspace.CurrentCamera.CameraSubject = ghostPart

    ghostConnection = RunService.Heartbeat:Connect(function()
        if not ghostEnabled or not ghostPart or not ghostPart.Parent then return end
        if UIS:GetFocusedTextBox() then return end
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = originalCFrame
        end
        local moveDir = Vector3.zero
        local cam = workspace.CurrentCamera
        local spd = ghostSpeed / 60
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then spd = spd * 2 end
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.yAxis end
        if moveDir.Magnitude > 0 then ghostPart.CFrame = ghostPart.CFrame + moveDir.Unit * spd end
    end)
end

local function disableGhostMode(teleport)
    if ghostConnection then ghostConnection:Disconnect(); ghostConnection = nil end
    if ghostOverlay then ghostOverlay:Destroy(); ghostOverlay = nil end
    if player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    end
    if ghostPart then
        local ghostCF = ghostPart.CFrame
        ghostPart:Destroy(); ghostPart = nil
        if teleport and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid")
            player.Character.HumanoidRootPart.CFrame = ghostCF
        end
    end
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
    end
end

-- ============ AIMBOT ============
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(head, enemyChar)
    local cam = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local dir = (head.Position - origin)
    local ignore = {player.Character, enemyChar}
    rayParams.FilterDescendantsInstances = ignore
    local result = workspace:Raycast(origin, dir, rayParams)
    return result == nil
end

local function getClosestEnemy()
    local cam = workspace.CurrentCamera
    local mouse = player:GetMouse()
    local mPos = Vector2.new(mouse.X, mouse.Y)
    local closest, shortest = nil, AIM_FOV
    for _, plr in pairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local head = plr.Character:FindFirstChild("Head")
            if hum and head and hum.Health > 0 then
                local sp, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - mPos).Magnitude
                    if d < shortest and isVisible(head, plr.Character) then
                        shortest = d; closest = head.Position
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled or not rightMouseDown or not player.Character then return end
    local tPos = getClosestEnemy()
    if not tPos then return end
    local cam = workspace.CurrentCamera
    cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + (tPos - cam.CFrame.Position).Unit)
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hrp and hum and hum.AutoRotate then
        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(tPos.X, hrp.Position.Y, tPos.Z))
    end
end)

-- ============ BUTTON EVENTS ============
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espInd.BackgroundColor3 = espEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    if espEnabled then enableESP() else disableESP() end
end)

aimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimInd.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end)

ctpBtn.MouseButton1Click:Connect(function()
    clickTpEnabled = not clickTpEnabled
    ctpInd.BackgroundColor3 = clickTpEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end)

ghostBtn.MouseButton1Click:Connect(function()
    ghostEnabled = not ghostEnabled
    ghostInd.BackgroundColor3 = ghostEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    if ghostEnabled then enableGhostMode() else disableGhostMode(true) end
end)

-- ============ INPUT ============
UIS.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then rightMouseDown = true; return end
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z then
        if ghostEnabled then
            ghostEnabled = false
            disableGhostMode(false)
            ghostInd.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        else
            MainFrame.Visible = not MainFrame.Visible
        end
    elseif input.KeyCode == Enum.KeyCode.CapsLock then
        ghostEnabled = not ghostEnabled
        ghostInd.BackgroundColor3 = ghostEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        if ghostEnabled then enableGhostMode() else disableGhostMode(true) end
    elseif input.KeyCode == Enum.KeyCode.J then
        espEnabled = not espEnabled
        espInd.BackgroundColor3 = espEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        if espEnabled then enableESP() else disableESP() end
    elseif input.KeyCode == Enum.KeyCode.X then
        aimbotEnabled = not aimbotEnabled
        aimInd.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    elseif input.KeyCode == Enum.KeyCode.Q and clickTpEnabled then
        pcall(function()
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local mouse = player:GetMouse()
                if mouse.Target then root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
            end
        end)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then rightMouseDown = false end
end)

-- ============ MOUNT ============
pcall(function() ScreenGui.Parent = guiParent end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

player.CharacterAdded:Connect(function()
    if ghostEnabled then
        ghostEnabled = false
        disableGhostMode(false)
        ghostInd.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end)

print("[WW1] Carregado! Z=Menu | J=ESP X=Aimbot CapsLk=Ghost Q=ClickTP")
