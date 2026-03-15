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
local noclipEnabled = false
local noclipCollisions = {}
local perfEnabled = false
local ultraEnabled = false
local originalLighting = {}
local originalEffects = {}
local originalTextures = {}
local ultraEffects = {}
local rainEmitter = nil

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WW1Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 25)
MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 310)
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

-- Info
local infoLbl = Instance.new("TextLabel")
infoLbl.Parent = ContentCombat
infoLbl.BackgroundTransparency = 1
infoLbl.Position = UDim2.new(0, 10, 0, 123)
infoLbl.Size = UDim2.new(0, 210, 0, 20)
infoLbl.Font = Enum.Font.Gotham
infoLbl.Text = "Z=Menu | RMB=Aim"
infoLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
infoLbl.TextSize = 10

-- ============ ABA OTHERS ============
local noclipBtn, noclipInd = createToggle(ContentOthers, "Noclip [N]", 0)
local perfBtn, perfInd = createToggle(ContentOthers, "Performance", 35)
local ultraBtn, ultraInd = createToggle(ContentOthers, "Ultra GFX", 70)

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

-- ============ PERFORMANCE / ULTRA ============
local Lighting = game:GetService("Lighting")

local function enablePerformance()
    if ultraEnabled then return end
    originalLighting = {
        Brightness = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }
    Lighting.GlobalShadows = false
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("ColorCorrectionEffect") then
            originalEffects[obj] = obj.Enabled
            obj.Enabled = false
        end
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail") then
                if not (player.Character and obj:IsDescendantOf(player.Character)) then
                    originalTextures[obj] = {Enabled = obj.Enabled}
                    obj.Enabled = false
                end
            elseif obj:IsA("MeshPart") then
                if not game.Players:GetPlayerFromCharacter(obj.Parent) and not (obj.Parent and game.Players:GetPlayerFromCharacter(obj.Parent.Parent)) then
                    originalTextures[obj] = {TextureID = obj.TextureID}
                    obj.TextureID = ""
                end
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                local par = obj.Parent
                if par and not game.Players:GetPlayerFromCharacter(par.Parent) then
                    originalTextures[obj] = {Transparency = obj.Transparency}
                    obj.Transparency = 1
                end
            end
        end)
    end
end

local function disablePerformance()
    pcall(function()
        Lighting.GlobalShadows = originalLighting.GlobalShadows or true
        Lighting.EnvironmentDiffuseScale = originalLighting.EnvironmentDiffuseScale or 1
        Lighting.EnvironmentSpecularScale = originalLighting.EnvironmentSpecularScale or 1
    end)
    for obj, enabled in pairs(originalEffects) do
        pcall(function() obj.Enabled = enabled end)
    end
    originalEffects = {}
    for obj, data in pairs(originalTextures) do
        pcall(function()
            if data.Enabled ~= nil then obj.Enabled = data.Enabled
            elseif data.TextureID then obj.TextureID = data.TextureID
            elseif data.Transparency then obj.Transparency = data.Transparency end
        end)
    end
    originalTextures = {}
    originalLighting = {}
end

local function enableUltra()
    if perfEnabled then return end
    originalLighting = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
    }

    -- Desabilitar efeitos originais pra não conflitar
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
            originalEffects[obj] = pcall(function() return obj.Enabled end) and obj.Enabled or true
            pcall(function() obj.Enabled = false end)
        end
    end

    -- === LIGHTING BASE — clima sombrio WW1 ===
    Lighting.GlobalShadows = true
    Lighting.Brightness = 0.8
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
    Lighting.ExposureCompensation = 0.5
    Lighting.Ambient = Color3.fromRGB(20, 22, 30)
    Lighting.OutdoorAmbient = Color3.fromRGB(45, 50, 60)
    Lighting.ColorShift_Top = Color3.fromRGB(180, 170, 155)
    Lighting.ColorShift_Bottom = Color3.fromRGB(35, 40, 55)
    Lighting.FogColor = Color3.fromRGB(120, 125, 135)
    Lighting.FogEnd = 3000
    Lighting.FogStart = 100

    -- === ATMOSPHERE — névoa densa de trincheira ===
    local atm = Instance.new("Atmosphere")
    atm.Name = "UltraAtm"
    atm.Density = 0.4
    atm.Offset = 0.25
    atm.Color = Color3.fromRGB(145, 150, 170)
    atm.Decay = Color3.fromRGB(115, 120, 140)
    atm.Glare = 0.1
    atm.Haze = 8
    atm.Parent = Lighting
    table.insert(ultraEffects, atm)

    -- === BLOOM — brilho cinematográfico suave ===
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "UltraBloom"
    bloom.Intensity = 0.8
    bloom.Size = 56
    bloom.Threshold = 0.75
    bloom.Parent = Lighting
    table.insert(ultraEffects, bloom)

    -- === COLOR CORRECTION 1 — tom sépia/frio de guerra ===
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "UltraCC"
    cc.Brightness = 0.04
    cc.Contrast = 0.25
    cc.Saturation = -0.2
    cc.TintColor = Color3.fromRGB(230, 218, 200)
    cc.Parent = Lighting
    table.insert(ultraEffects, cc)

    -- === COLOR CORRECTION 2 — profundidade nas sombras ===
    local cc2 = Instance.new("ColorCorrectionEffect")
    cc2.Name = "UltraCC2"
    cc2.Brightness = -0.03
    cc2.Contrast = 0.12
    cc2.Saturation = 0.08
    cc2.TintColor = Color3.fromRGB(245, 240, 255)
    cc2.Parent = Lighting
    table.insert(ultraEffects, cc2)

    -- === SUN RAYS — raios volumétricos entre nuvens ===
    local sun = Instance.new("SunRaysEffect")
    sun.Name = "UltraSun"
    sun.Intensity = 0.18
    sun.Spread = 1
    sun.Parent = Lighting
    table.insert(ultraEffects, sun)

    -- === DEPTH OF FIELD — foco cinematográfico ===
    local dof = Instance.new("DepthOfFieldEffect")
    dof.Name = "UltraDOF"
    dof.FarIntensity = 0.2
    dof.FocusDistance = 40
    dof.InFocusRadius = 50
    dof.NearIntensity = 0.15
    dof.Parent = Lighting
    table.insert(ultraEffects, dof)

    -- === BLUR — suavização leve ===
    local blur = Instance.new("BlurEffect")
    blur.Name = "UltraBlur"
    blur.Size = 3
    blur.Parent = Lighting
    table.insert(ultraEffects, blur)

    -- === SKY — céu dramático nublado ===
    local sky = Instance.new("Sky")
    sky.Name = "UltraSky"
    sky.CelestialBodiesShown = true
    sky.StarCount = 0
    sky.SkyboxBk = "rbxassetid://1012890"
    sky.SkyboxDn = "rbxassetid://1012891"
    sky.SkyboxFt = "rbxassetid://1012887"
    sky.SkyboxLf = "rbxassetid://1012889"
    sky.SkyboxRt = "rbxassetid://1012888"
    sky.SkyboxUp = "rbxassetid://1012890"
    sky.SunAngularSize = 12
    sky.MoonAngularSize = 6
    sky.Parent = Lighting
    table.insert(ultraEffects, sky)

    pcall(function()
        -- === CHUVA PESADA ===
        local att = Instance.new("Attachment")
        att.Name = "RainAtt"
        att.Parent = workspace.Terrain

        local rain = Instance.new("ParticleEmitter")
        rain.Name = "UltraRain"
        rain.Texture = "rbxassetid://241876428"
        rain.Rate = 2000
        rain.Lifetime = NumberRange.new(0.5, 0.9)
        rain.Speed = NumberRange.new(120, 180)
        rain.SpreadAngle = Vector2.new(12, 12)
        rain.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.04), NumberSequenceKeypoint.new(1, 0.01)})
        rain.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1)})
        rain.Color = ColorSequence.new(Color3.fromRGB(185, 195, 215))
        rain.LightEmission = 0.03
        rain.EmissionDirection = Enum.NormalId.Bottom
        rain.Drag = 0.5
        rain.Parent = att
        rainEmitter = rain
        table.insert(ultraEffects, att)

        -- === RESPINGOS NO CHÃO ===
        local att2 = Instance.new("Attachment")
        att2.Name = "SplashAtt"
        att2.Parent = workspace.Terrain

        local splash = Instance.new("ParticleEmitter")
        splash.Name = "UltraSplash"
        splash.Texture = "rbxassetid://241876428"
        splash.Rate = 400
        splash.Lifetime = NumberRange.new(0.08, 0.25)
        splash.Speed = NumberRange.new(1, 4)
        splash.SpreadAngle = Vector2.new(180, 180)
        splash.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(1, 0.25)})
        splash.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
        splash.Color = ColorSequence.new(Color3.fromRGB(160, 170, 195))
        splash.LightEmission = 0.01
        splash.EmissionDirection = Enum.NormalId.Top
        splash.Parent = att2
        table.insert(ultraEffects, att2)

        -- === NÉVOA BAIXA (fumaça de guerra) ===
        local att3 = Instance.new("Attachment")
        att3.Name = "FogAtt"
        att3.Parent = workspace.Terrain

        local fog = Instance.new("ParticleEmitter")
        fog.Name = "UltraFog"
        fog.Texture = "rbxassetid://1084981"  -- nuvem/fumaça
        fog.Rate = 8
        fog.Lifetime = NumberRange.new(12, 20)
        fog.Speed = NumberRange.new(2, 6)
        fog.SpreadAngle = Vector2.new(360, 30)
        fog.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 20), NumberSequenceKeypoint.new(0.5, 50), NumberSequenceKeypoint.new(1, 30)})
        fog.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.7), NumberSequenceKeypoint.new(0.8, 0.75), NumberSequenceKeypoint.new(1, 1)})
        fog.Color = ColorSequence.new(Color3.fromRGB(130, 135, 145))
        fog.LightEmission = 0.02
        fog.Rotation = NumberRange.new(0, 360)
        fog.RotSpeed = NumberRange.new(-5, 5)
        fog.EmissionDirection = Enum.NormalId.Right
        fog.Parent = att3
        table.insert(ultraEffects, att3)
    end)

    -- === VINHETA ESCURA — bordas cinematográficas ===
    local vignette = Instance.new("ImageLabel")
    vignette.Name = "UltraVignette"
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundTransparency = 1
    vignette.Image = "rbxassetid://115642383"
    vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
    vignette.ImageTransparency = 0.5
    vignette.ScaleType = Enum.ScaleType.Stretch
    vignette.ZIndex = -2
    vignette.Parent = ScreenGui
    table.insert(ultraEffects, vignette)

    -- === GRAIN/NOISE — textura de filme antigo ===
    local grain = Instance.new("ImageLabel")
    grain.Name = "UltraGrain"
    grain.Size = UDim2.new(1, 0, 1, 0)
    grain.BackgroundTransparency = 1
    grain.Image = "rbxassetid://2700826735"
    grain.ImageColor3 = Color3.fromRGB(255, 255, 255)
    grain.ImageTransparency = 0.92
    grain.ScaleType = Enum.ScaleType.Tile
    grain.TileSize = UDim2.new(0, 512, 0, 512)
    grain.ZIndex = -2
    grain.Parent = ScreenGui
    table.insert(ultraEffects, grain)
end

local function disableUltra()
    for _, obj in pairs(ultraEffects) do
        pcall(function() obj:Destroy() end)
    end
    ultraEffects = {}
    rainEmitter = nil
    -- Restaurar efeitos originais do jogo
    for obj, enabled in pairs(originalEffects) do
        pcall(function() obj.Enabled = enabled end)
    end
    originalEffects = {}
    pcall(function()
        Lighting.Brightness = originalLighting.Brightness or 1
        Lighting.Ambient = originalLighting.Ambient or Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(70, 70, 70)
        Lighting.EnvironmentDiffuseScale = originalLighting.EnvironmentDiffuseScale or 1
        Lighting.EnvironmentSpecularScale = originalLighting.EnvironmentSpecularScale or 1
        Lighting.GlobalShadows = originalLighting.GlobalShadows or true
        Lighting.ExposureCompensation = originalLighting.ExposureCompensation or 0
        Lighting.ColorShift_Top = originalLighting.ColorShift_Top or Color3.new(0, 0, 0)
        Lighting.ColorShift_Bottom = originalLighting.ColorShift_Bottom or Color3.new(0, 0, 0)
        Lighting.FogColor = originalLighting.FogColor or Color3.fromRGB(192, 192, 192)
        Lighting.FogEnd = originalLighting.FogEnd or 100000
        Lighting.FogStart = originalLighting.FogStart or 0
    end)
    originalLighting = {}
end

-- ============ NOCLIP ============
RunService.Stepped:Connect(function()
    if not player.Character then return end
    pcall(function()
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipEnabled then
                    if noclipCollisions[part] == nil then
                        noclipCollisions[part] = part.CanCollide
                    end
                    part.CanCollide = false
                else
                    if noclipCollisions[part] ~= nil then
                        part.CanCollide = noclipCollisions[part]
                        noclipCollisions[part] = nil
                    end
                end
            end
        end
    end)
end)

-- ============ AIMBOT ============
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(head, enemyChar)
    local origin = workspace.CurrentCamera.CFrame.Position
    local dir = (head.Position - origin)
    rayParams.FilterDescendantsInstances = {player.Character, enemyChar}
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

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipInd.BackgroundColor3 = noclipEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end)

perfBtn.MouseButton1Click:Connect(function()
    if ultraEnabled then return end
    perfEnabled = not perfEnabled
    perfInd.BackgroundColor3 = perfEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    if perfEnabled then enablePerformance() else disablePerformance() end
end)

ultraBtn.MouseButton1Click:Connect(function()
    if perfEnabled then return end
    ultraEnabled = not ultraEnabled
    ultraInd.BackgroundColor3 = ultraEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    if ultraEnabled then enableUltra() else disableUltra() end
end)

-- ============ INPUT ============
UIS.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then rightMouseDown = true; return end
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z then
        MainFrame.Visible = not MainFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.J then
        espEnabled = not espEnabled
        espInd.BackgroundColor3 = espEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        if espEnabled then enableESP() else disableESP() end
    elseif input.KeyCode == Enum.KeyCode.X then
        aimbotEnabled = not aimbotEnabled
        aimInd.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    elseif input.KeyCode == Enum.KeyCode.N then
        noclipEnabled = not noclipEnabled
        noclipInd.BackgroundColor3 = noclipEnabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then rightMouseDown = false end
end)

-- ============ MOUNT ============
pcall(function() ScreenGui.Parent = guiParent end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

print("[WW1] Carregado! Z=Menu | J=ESP X=Aimbot N=Noclip")
