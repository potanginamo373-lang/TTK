--[[
    ╔══════════════════════════════════════════╗
  
                    A S T R O              
    
    ╚══════════════════════════════════════════╝
    UI Library : https://raw.githubusercontent.com/deividcomsono/Obsidian/main/
--]]

if not game:IsLoaded() then game.Loaded:Wait() end

local repo         = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options      = Library.Options
local Toggles      = Library.Toggles



local SilentAimSettings = {
    Enabled             = true,
    ToggleKey           = "RightAlt",
    TeamCheck           = false,
    VisibleCheck        = false,
    TargetPart          = "Head",
    FOVRadius           = 150,
    FOVVisible          = true,
    ShowSilentAimTarget = false,
    HitChance           = 100,
}

local ModSettings = {
    RecoilEnabled = true,
    RecoilScale   = 0,
    InfiniteAmmo  = true,
}

local RadarSettings = {
    Enabled       = true,
    Radius        = 110,
    Range         = 300,
    Anchor        = Vector2.new(170, 170),
    Rotate        = true,
    ShowOffscreen = true,
    DotSize       = 4,
    SelfDotSize   = 5,
}

local ESPSettings = {
    Enabled       = false,
    Boxes         = false,
    Names         = false,
    Health        = false,
    Distance      = false,
    Tracers       = false,
    TeamCheck     = false,
    MaxDistance   = 2000,
    TracerOrigin  = "Bottom", -- "Top", "Center", "Bottom"
    BoxColor      = Color3.fromRGB(255, 255, 255),
    NameColor     = Color3.fromRGB(255, 255, 255),
    TracerColor   = Color3.fromRGB(255, 255, 255),
}

local Global = getgenv()
Global.SilentAimSettings = SilentAimSettings
Global.RadarSettings     = RadarSettings
Global.ESPSettings       = ESPSettings

if Global.__astro_cleanup then pcall(Global.__astro_cleanup) end

local State = { Connections = {}, Drawings = {} }
Global.__astro_state   = State
Global.__astro_cleanup = function()
    for _, c in ipairs(State.Connections) do pcall(function() c:Disconnect() end) end
    for _, d in ipairs(State.Drawings)    do pcall(function() d:Remove()      end) end
    pcall(function()
        Lighting.Brightness     = originalBrightness
        Lighting.Ambient        = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.FogEnd         = originalFogEnd
        Lighting.ClockTime      = originalClockTime
    end)
end

local Camera          = workspace.CurrentCamera
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local RS              = game:GetService("ReplicatedStorage")
local LP              = Players.LocalPlayer

local GetPlayers      = Players.GetPlayers
local WTS             = Camera.WorldToScreenPoint
local WTVP            = Camera.WorldToViewportPoint
local FFC             = game.FindFirstChild
local GetMouseLoc     = UIS.GetMouseLocation

local ValidTargetParts = {
    "Head",
	"Closest",
	"Random",
    "UpperTorso",
    "LowerTorso",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
}

local MercFolder = workspace:FindFirstChild("MercPlayers")
if not MercFolder then
    task.spawn(function()
        MercFolder = workspace:WaitForChild("MercPlayers", 30)
    end)
end

local function getMercHitbox(player)
    if not MercFolder then return nil end
    return MercFolder:FindFirstChild("MercHitboxes_" .. player.Name)
end

local function onScreen(pos)
    local v, ok = WTVP(Camera, pos)
    return Vector2.new(v.X, v.Y), ok, v.Z
end

local function mousePos()
    return GetMouseLoc(UIS)
end

local function charRoot(character, player)
    if player then
        local hb = getMercHitbox(player)
        if hb then
            return  hb:FindFirstChildWhichIsA("Head")
            or hb:FindFirstChild("LowerTorso")
                or hb:FindFirstChild("UpperTorso")
                or hb:FindFirstChildWhichIsA("BasePart")
        end
    end
    if not character then return nil end
    return FFC(character, "HumanoidRootPart")
        or FFC(character, "UpperTorso")
        or FFC(character, "Torso")
end

local function getClosestPart(src)
    local best, bestDist = nil, math.huge
    for _, partName in ipairs(ValidTargetParts) do
        if partName == "Random" or partName == "Closest" then continue end
        local part = src:FindFirstChild(partName)
        if part then
            local sp, onScrn = onScreen(part.Position)
            if onScrn then
                local d = (mousePos() - sp).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = part
                end
            end
        end
    end
    return best
end

local fov_circle      = Drawing.new("Circle")
fov_circle.Thickness  = 1.5
fov_circle.NumSides   = 120
fov_circle.Radius     = SilentAimSettings.FOVRadius
fov_circle.Filled     = false
fov_circle.Visible    = SilentAimSettings.FOVVisible
fov_circle.ZIndex     = 999
fov_circle.Transparency = 1
fov_circle.Color      = Color3.fromRGB(54, 57, 241)
table.insert(State.Drawings, fov_circle)

local mouse_box       = Drawing.new("Square")
mouse_box.ZIndex      = 999
mouse_box.Color       = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness   = 2
mouse_box.Size        = Vector2.new(18, 18)
mouse_box.Filled      = false
mouse_box.Visible     = false
table.insert(State.Drawings, mouse_box)

-- Radar Drawings Setup
local radar_bg      = Drawing.new("Circle")
radar_bg.Filled     = true
radar_bg.NumSides   = 100
radar_bg.Radius     = RadarSettings.Radius
radar_bg.Color      = Color3.fromRGB(14, 14, 20)
radar_bg.Transparency = 0.7
radar_bg.Visible    = RadarSettings.Enabled
radar_bg.ZIndex     = 990
table.insert(State.Drawings, radar_bg)

local radar_ring      = Drawing.new("Circle")
radar_ring.Filled     = false
radar_ring.Thickness  = 1
radar_ring.NumSides   = 100
radar_ring.Radius     = RadarSettings.Radius
radar_ring.Color      = Color3.fromRGB(80, 82, 110)
radar_ring.Transparency = 1
radar_ring.Visible    = RadarSettings.Enabled
radar_ring.ZIndex     = 991
table.insert(State.Drawings, radar_ring)

local radar_ch      = Drawing.new("Line")
radar_ch.Thickness  = 1
radar_ch.Color      = Color3.fromRGB(60, 62, 85)
radar_ch.Transparency = 0.7
radar_ch.Visible    = RadarSettings.Enabled
radar_ch.ZIndex     = 991
table.insert(State.Drawings, radar_ch)

local radar_cv      = Drawing.new("Line")
radar_cv.Thickness  = 1
radar_cv.Color      = Color3.fromRGB(60, 62, 85)
radar_cv.Transparency = 0.7
radar_cv.Visible    = RadarSettings.Enabled
radar_cv.ZIndex     = 991
table.insert(State.Drawings, radar_cv)

local radar_self      = Drawing.new("Circle")
radar_self.Filled     = true
radar_self.NumSides   = 60
radar_self.Radius     = RadarSettings.SelfDotSize
radar_self.Color      = Color3.fromRGB(245, 245, 245)
radar_self.Transparency = 1
radar_self.Visible    = RadarSettings.Enabled
radar_self.ZIndex     = 992
table.insert(State.Drawings, radar_self)

local radar_dots = {}

local esp_drawings = {}

local function createESP(player)
    local esp = {}
    
    esp.BoxOutline = Drawing.new("Square")
    esp.BoxOutline.Thickness = 3
    esp.BoxOutline.Filled = false
    esp.BoxOutline.Color = Color3.new(0, 0, 0)
    esp.BoxOutline.ZIndex = 1
    table.insert(State.Drawings, esp.BoxOutline)

    esp.Box = Drawing.new("Square")
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Box.ZIndex = 2
    table.insert(State.Drawings, esp.Box)

    esp.HealthOutline = Drawing.new("Line")
    esp.HealthOutline.Thickness = 3
    esp.HealthOutline.Color = Color3.new(0, 0, 0)
    esp.HealthOutline.ZIndex = 1
    table.insert(State.Drawings, esp.HealthOutline)

    esp.Health = Drawing.new("Line")
    esp.Health.Thickness = 1
    esp.Health.ZIndex = 2
    table.insert(State.Drawings, esp.Health)

    esp.Name = Drawing.new("Text")
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Size = 13
    esp.Name.Font = 2
    esp.Name.ZIndex = 3
    table.insert(State.Drawings, esp.Name)

    esp.Distance = Drawing.new("Text")
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Size = 13
    esp.Distance.Font = 2
    esp.Distance.ZIndex = 3
    table.insert(State.Drawings, esp.Distance)

    esp.Tracer = Drawing.new("Line")
    esp.Tracer.Thickness = 1
    esp.Tracer.ZIndex = 1
    table.insert(State.Drawings, esp.Tracer)

    esp_drawings[player] = esp
    return esp
end

local function removePlayerDrawings(player)
    local d = radar_dots[player]
    if d then
        radar_dots[player] = nil
        local i = table.find(State.Drawings, d)
        if i then table.remove(State.Drawings, i) end
        pcall(function() d:Remove() end)
    end
    local esp = esp_drawings[player]
    if esp then
        esp_drawings[player] = nil
        for _, drawObj in pairs(esp) do
            local i = table.find(State.Drawings, drawObj)
            if i then table.remove(State.Drawings, i) end
            pcall(function() drawObj:Remove() end)
        end
    end
end

table.insert(State.Connections, Players.PlayerRemoving:Connect(removePlayerDrawings))

local function updateRadar()
    local show = RadarSettings.Enabled
    radar_bg.Visible   = show
    radar_ring.Visible = show
    radar_ch.Visible   = show
    radar_cv.Visible   = show
    radar_self.Visible = show

    if not show then
        for _, d in pairs(radar_dots) do d.Visible = false end
        return
    end

    local char = LP.Character
    local root = charRoot(char)
    if not root then
        for _, d in pairs(radar_dots) do d.Visible = false end
        return
    end

    local r      = RadarSettings.Radius
    local cx     = RadarSettings.Anchor.X
    local cy     = Camera.ViewportSize.Y - RadarSettings.Anchor.Y
    local center = Vector2.new(cx, cy)
    local look   = Camera.CFrame.LookVector
    local yaw    = math.atan2(look.X, look.Z)
    local sinY   = math.sin(-yaw)
    local cosY   = math.cos(-yaw)

    radar_bg.Position   = center  radar_bg.Radius   = r
    radar_ring.Position = center  radar_ring.Radius = r
    radar_ch.From = Vector2.new(cx - r, cy)  radar_ch.To = Vector2.new(cx + r, cy)
    radar_cv.From = Vector2.new(cx, cy - r)  radar_cv.To = Vector2.new(cx, cy + r)
    radar_self.Position = center  radar_self.Radius = RadarSettings.SelfDotSize

    local localTeam = LP.Team
    local localPos  = root.Position

    for _, player in ipairs(GetPlayers(Players)) do
        if player == LP then continue end
        local dot = radar_dots[player]
        if not dot then
            dot = Drawing.new("Circle")
            dot.Filled = true  dot.NumSides = 60  dot.Radius = RadarSettings.DotSize
            dot.Transparency = 1  dot.Visible = false  dot.ZIndex = 992
            radar_dots[player] = dot
            table.insert(State.Drawings, dot)
        end

        local pch = player.Character
        local hb  = getMercHitbox(player)
        local tr  = charRoot(pch, player)
        if not tr then dot.Visible = false continue end

        if not hb then
            local hum = pch and FFC(pch, "Humanoid")
            if not hum or hum.Health <= 0 then dot.Visible = false continue end
        end

        if SilentAimSettings.TeamCheck and localTeam and player.Team == localTeam then
            dot.Visible = false  continue
        end

        local delta = tr.Position - localPos
        local rel   = Vector2.new(delta.X, -delta.Z)
        if RadarSettings.Rotate then
            rel = Vector2.new(
                rel.X * cosY - rel.Y * sinY,
                rel.X * sinY + rel.Y * cosY
            )
        end

        local dist = rel.Magnitude
        if dist <= 0 then dot.Visible = false  continue end
        if dist > RadarSettings.Range then
            if not RadarSettings.ShowOffscreen then dot.Visible = false  continue end
            rel = rel.Unit * RadarSettings.Range
        end

        local isTeam = localTeam and player.Team == localTeam
        dot.Position     = center + (rel / RadarSettings.Range) * r
        dot.Radius       = RadarSettings.DotSize
        dot.Color        = isTeam and Color3.fromRGB(54, 57, 241) or Color3.fromRGB(235, 75, 75)
        dot.Transparency = 1
        dot.Visible      = true
    end
end

local function updateESP()
    for _, player in ipairs(GetPlayers(Players)) do
        if player == LP then continue end
        
        local esp = esp_drawings[player] or createESP(player)
        local isTeam = (LP.Team and player.Team == LP.Team)
        
        local function hideESP()
            for _, d in pairs(esp) do d.Visible = false end
        end

        if not ESPSettings.Enabled or (ESPSettings.TeamCheck and isTeam) then
            hideESP()
            continue
        end

        local pch = player.Character
        local tr = charRoot(pch, player)
        local hum = pch and FFC(pch, "Humanoid")
        
        if not tr or (not getMercHitbox(player) and (not hum or hum.Health <= 0)) then 
            hideESP()
            continue 
        end

        local dist = (Camera.CFrame.Position - tr.Position).Magnitude
        if dist > ESPSettings.MaxDistance then
            hideESP()
            continue
        end

        local topPos = tr.Position + Vector3.new(0, 3, 0)
        local botPos = tr.Position - Vector3.new(0, 3.5, 0)
        
        local topScreen, topVis, topZ = onScreen(topPos)
        local botScreen, botVis, botZ = onScreen(botPos)

        if not (topVis and botVis) then
            hideESP()
            continue
        end

        local height = math.abs(topScreen.Y - botScreen.Y)
        local width = height / 2
        local boxSize = Vector2.new(width, height)
        local boxPos = Vector2.new(topScreen.X - width / 2, topScreen.Y)

        if ESPSettings.Boxes then
            esp.Box.Size = boxSize
            esp.Box.Position = boxPos
            esp.Box.Color = ESPSettings.BoxColor
            esp.Box.Visible = true

            esp.BoxOutline.Size = boxSize
            esp.BoxOutline.Position = boxPos
            esp.BoxOutline.Visible = true
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
        end

        if ESPSettings.Health and hum then
            local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local healthColor = Color3.fromHSV(healthPct * 0.3, 1, 1)
            local barHeight = height * healthPct
            
            local hx = boxPos.X - 5
            esp.HealthOutline.From = Vector2.new(hx, boxPos.Y - 1)
            esp.HealthOutline.To = Vector2.new(hx, boxPos.Y + height + 1)
            esp.HealthOutline.Visible = true

            esp.Health.From = Vector2.new(hx, boxPos.Y + height)
            esp.Health.To = Vector2.new(hx, boxPos.Y + height - barHeight)
            esp.Health.Color = healthColor
            esp.Health.Visible = true
        else
            esp.Health.Visible = false
            esp.HealthOutline.Visible = false
        end

        if ESPSettings.Names then
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(topScreen.X, topScreen.Y - 16)
            esp.Name.Color = ESPSettings.NameColor
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end

        if ESPSettings.Distance then
            esp.Distance.Text = math.floor(dist) .. "s"
            esp.Distance.Position = Vector2.new(botScreen.X, botScreen.Y + 2)
            esp.Distance.Color = ESPSettings.NameColor
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end

        if ESPSettings.Tracers then
            local traceOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            if ESPSettings.TracerOrigin == "Center" then
                traceOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            elseif ESPSettings.TracerOrigin == "Top" then
                traceOrigin = Vector2.new(Camera.ViewportSize.X / 2, 0)
            end
            
            esp.Tracer.From = traceOrigin
            esp.Tracer.To = Vector2.new(botScreen.X, botScreen.Y)
            esp.Tracer.Color = ESPSettings.TracerColor
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end
    end
end

local function syncDrawings()
    mouse_box.Visible  = SilentAimSettings.Enabled and SilentAimSettings.ShowSilentAimTarget
    fov_circle.Visible = SilentAimSettings.FOVVisible
    fov_circle.Radius  = SilentAimSettings.FOVRadius
end

table.insert(State.Connections, UIS.InputBegan:Connect(function(inp, gp)
    if Global.__astro_state ~= State then return end
    if gp or inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = Enum.KeyCode[SilentAimSettings.ToggleKey]
    if key and inp.KeyCode == key then
        SilentAimSettings.Enabled = not SilentAimSettings.Enabled
        local t = Toggles["SA_Enabled"]
        if t then t:SetValue(SilentAimSettings.Enabled) end
        syncDrawings()
    end
end))

coroutine.resume(coroutine.create(function()
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        if Global.__astro_state ~= State then return end

local function getClosestPlayer()
    local closest, bestDist = nil, nil
    for _, player in next, GetPlayers(Players) do
        if player == LP then continue end
        if SilentAimSettings.TeamCheck and player.Team == LP.Team then continue end

        local hb  = getMercHitbox(player)
        local src = hb or player.Character
        if not src then continue end

        if not hb then
            local hum = FFC(src, "Humanoid")
            if not hum or hum.Health <= 0 then continue end
        end

        local rootPart = hb and (
            hb:FindFirstChild("Head") or
            hb:FindFirstChild("LowerTorso") or
            hb:FindFirstChild("UpperTorso") or
            hb:FindFirstChildWhichIsA("BasePart")
        ) or FFC(src, "HumanoidRootPart")

        if not rootPart then continue end

        local sp, onScrn = onScreen(rootPart.Position)
        if not onScrn then continue end

        local dist = (mousePos() - sp).Magnitude
        local fov  = SilentAimSettings.FOVRadius or 2000
        if dist <= (bestDist or fov) then
            local tpn = SilentAimSettings.TargetPart
            local resolved
            if tpn == "Random" then
                resolved = src:FindFirstChild(
                    ValidTargetParts[math.random(1, #ValidTargetParts - 2)]
                )
            elseif tpn == "Closest" then
                resolved = getClosestPart(src)
            else
                resolved = src:FindFirstChild(tpn)
            end
            resolved = resolved or src:FindFirstChild("Head") or src:FindFirstChildWhichIsA("BasePart")

            if resolved then
                closest  = resolved
                bestDist = dist
            end
        end
    end
    return closest
end

        local closest = getClosestPlayer()
        if SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled and closest then
            local ref = closest.Parent and closest.Parent.PrimaryPart or closest
            local vp, vis = WTVP(Camera, ref.Position)
            mouse_box.Visible  = vis
            mouse_box.Position = Vector2.new(vp.X, vp.Y)
        else
            mouse_box.Visible = false
        end

        fov_circle.Visible = SilentAimSettings.FOVVisible
        if SilentAimSettings.FOVVisible then
            fov_circle.Position = mousePos()
        end

        updateRadar()
        updateESP()
    end))
end))

task.spawn(function()
    local ok, BC = pcall(function()
        return require(RS.Modules.Client.Controllers.BulletController)
    end)
    if not ok or type(BC) ~= "table" or type(BC.Discharge) ~= "function" then
        return warn("[SilentAim] BulletController unavailable")
    end

    local orig = BC.Discharge
    BC.Discharge = newcclosure(function(self, weaponId, origin, dir, ...)
        if SilentAimSettings.Enabled then
            local chance = SilentAimSettings.HitChance
            if chance >= 100 or math.random(100) <= chance then
local t = nil
local bestDist = SilentAimSettings.FOVRadius
for _, player in next, GetPlayers(Players) do
    if player == LP or (SilentAimSettings.TeamCheck and player.Team == LP.Team) then continue end
    
    local hb   = getMercHitbox(player)
    local src  = hb or player.Character
    if not src then continue end

    if not hb then
        local hum = FFC(src, "Humanoid")
        if not hum or hum.Health <= 0 then continue end
    end

    local rootPart = charRoot(player.Character, player)
    if not rootPart then continue end

    local sp, onScrn = onScreen(rootPart.Position)
    if not onScrn then continue end

    local d = (mousePos() - sp).Magnitude
    if d <= bestDist then
       local tpn = SilentAimSettings.TargetPart
local resolved
if tpn == "Random" then
    resolved = src:FindFirstChild(
        ValidTargetParts[math.random(1, #ValidTargetParts - 2)] -- exclude Random/Closest entries
    )
elseif tpn == "Closest" then
    resolved = getClosestPart(src)
else
    resolved = src:FindFirstChild(tpn)
end
resolved = resolved or src:FindFirstChild("Head") or src:FindFirstChildWhichIsA("BasePart")
        
        if resolved then
            t = resolved
            bestDist = d
        end
    end
end

if t then dir = (t.Position - origin).Unit end
            end
        end
        return orig(self, weaponId, origin, dir, ...)
    end)
end)

task.spawn(function()
    local ok, GC = pcall(function()
        return require(RS.Modules.Client.Controllers.GunController)
    end)
    if ok and type(GC) == "table" and type(GC.ApplyRecoil) == "function" then
        local orig = GC.ApplyRecoil
        GC.ApplyRecoil = newcclosure(function(self, ...)
            orig(self, ...)
            if not ModSettings.RecoilEnabled then return end
            local s = ModSettings.RecoilScale
            local springs = {
                self.RecoilSpring, self.RecoilPushSpring,
                self.RecoilShakeSpring, self.RecoilTiltSpring,
            }
            for _, sp in ipairs(springs) do
                if sp then
                    sp.p = sp.p * s
                    sp.v = sp.v * s
                end
            end
        end)
    end

    local ok2, CC = pcall(function()
        return require(RS.Modules.Client.Controllers.CameraController)
    end)
    if ok2 and type(CC) == "table" and type(CC.Recoil) == "function" then
        local orig2 = CC.Recoil
        CC.Recoil = newcclosure(function(self, ...)
            if not ModSettings.RecoilEnabled then return orig2(self, ...) end
            local args  = { ... }
            local scale = ModSettings.RecoilScale
            for i = 1, 3 do
                if type(args[i]) == "number" then args[i] = args[i] * scale end
            end
            return orig2(self, table.unpack(args))
        end)
    end
end)

task.spawn(function()
    local ok, GC = pcall(function()
        return require(RS.Modules.Client.Controllers.GunController)
    end)
    if ok and type(GC) == "table" and type(GC.FireWeapon) == "function" then
        local orig = GC.FireWeapon
        GC.FireWeapon = newcclosure(function(self, ...)
            local res = orig(self, ...)
            if ModSettings.InfiniteAmmo and self.Weapon and self.Weapon.MagAmmo ~= nil then
                self.Weapon.MagAmmo = self.Weapon.MaxMagSize + 1
            end
            return res
        end)
    end
end)

local Window = Library:CreateWindow({
    Title            = "Astro",
    Footer           = "discord.gg/MPpUNATuV8",
    NotifySide       = "Right",
    ShowCustomCursor = true,
    Center           = true,
    AutoShow         = true,
})

local Tabs = {
    SA       = Window:AddTab("Silent Aim", "crosshair"),
    ESP      = Window:AddTab("ESP Visuals", "eye"),
    Mods     = Window:AddTab("Mods",       "zap"),
    Radar    = Window:AddTab("Radar",      "radar"),
    Settings = Window:AddTab("UI Settings","settings"),
}

local SAL = Tabs.SA:AddLeftGroupbox("Silent Aim",  "crosshair")
local SAR = Tabs.SA:AddRightGroupbox("Targeting",  "target")

SAL:AddToggle("SA_Enabled", {
    Text    = "Silent Aim",
    Default = SilentAimSettings.Enabled,
    Risky   = true,
    Tooltip = "Redirect bullets to the nearest player within FOV",
    Callback = function(v)
        SilentAimSettings.Enabled = v
        syncDrawings()
    end,
})

SAL:AddLabel("Toggle Keybind"):AddKeyPicker("SA_ToggleKey", {
    Default          = "RightAlt",
    Text             = "Silent Aim key",
    Mode             = "Toggle",
    Tooltip          = "Press this key in-game to toggle Silent Aim on/off",
    ChangedCallback  = function(new)
        SilentAimSettings.ToggleKey = new.Name
    end,
})

SAL:AddDivider()
SAL:AddToggle("SA_TeamCheck", { Text = "Team Check", Default = SilentAimSettings.TeamCheck, Callback = function(v) SilentAimSettings.TeamCheck = v end })
SAL:AddToggle("SA_VisibleCheck", { Text = "Visible Check", Default = SilentAimSettings.VisibleCheck, Callback = function(v) SilentAimSettings.VisibleCheck = v end })
SAL:AddDivider()
SAL:AddToggle("SA_FOVVisible", { Text = "Show FOV Circle", Default = SilentAimSettings.FOVVisible, Callback = function(v) SilentAimSettings.FOVVisible = v; fov_circle.Visible = v end })
SAL:AddSlider("SA_FOVRadius", { Text = "FOV Radius", Default = SilentAimSettings.FOVRadius, Min = 10, Max = 700, Rounding = 0, Callback = function(v) SilentAimSettings.FOVRadius = v; fov_circle.Radius = v end })

SAR:AddDropdown("SA_TargetPart", {
    Values   = ValidTargetParts,
    Default  = 1,
    Text     = "Target Part",
    Tooltip  = "Body part bullets are redirected toward",
    Callback = function(v) SilentAimSettings.TargetPart = v end,
})
SAR:AddSlider("SA_HitChance", { Text = "Hit Chance (%)", Default = SilentAimSettings.HitChance, Min = 1, Max = 100, Rounding = 0, Callback = function(v) SilentAimSettings.HitChance = v end })
SAR:AddDivider()
SAR:AddToggle("SA_ShowTarget", { Text = "Show Target Box", Default = SilentAimSettings.ShowSilentAimTarget, Callback = function(v) SilentAimSettings.ShowSilentAimTarget = v; syncDrawings() end })

local ESPL = Tabs.ESP:AddLeftGroupbox("ESP Toggles", "eye")
local ESPR = Tabs.ESP:AddRightGroupbox("ESP Settings", "sliders")

ESPL:AddToggle("ESP_Enabled", { Text = "Master ESP Enable", Default = ESPSettings.Enabled, Callback = function(v) ESPSettings.Enabled = v end })
ESPL:AddToggle("ESP_TeamCheck", { Text = "Team Check", Default = ESPSettings.TeamCheck, Callback = function(v) ESPSettings.TeamCheck = v end })
ESPL:AddDivider()

ESPL:AddToggle("ESP_Boxes", { Text = "Draw Boxes", Default = ESPSettings.Boxes, Callback = function(v) ESPSettings.Boxes = v end })
    :AddColorPicker("ESP_BoxColor", { Default = ESPSettings.BoxColor, Title = "Box Color", Transparency = 0, Callback = function(c) ESPSettings.BoxColor = c end })

ESPL:AddToggle("ESP_Names", { Text = "Draw Names", Default = ESPSettings.Names, Callback = function(v) ESPSettings.Names = v end })
    :AddColorPicker("ESP_NameColor", { Default = ESPSettings.NameColor, Title = "Text Color", Transparency = 0, Callback = function(c) ESPSettings.NameColor = c end })

ESPL:AddToggle("ESP_Health", { Text = "Draw Health Bars", Default = ESPSettings.Health, Callback = function(v) ESPSettings.Health = v end })
ESPL:AddToggle("ESP_Distance", { Text = "Draw Distance", Default = ESPSettings.Distance, Callback = function(v) ESPSettings.Distance = v end })

ESPL:AddToggle("ESP_Tracers", { Text = "Draw Tracers", Default = ESPSettings.Tracers, Callback = function(v) ESPSettings.Tracers = v end })
    :AddColorPicker("ESP_TracerColor", { Default = ESPSettings.TracerColor, Title = "Tracer Color", Transparency = 0, Callback = function(c) ESPSettings.TracerColor = c end })

ESPR:AddSlider("ESP_MaxDistance", {
    Text     = "Max Render Distance",
    Default  = ESPSettings.MaxDistance,
    Min      = 50,
    Max      = 5000,
    Rounding = 0,
    Callback = function(v) ESPSettings.MaxDistance = v end,
})

ESPR:AddDropdown("ESP_TracerOrigin", {
    Values   = { "Bottom", "Center", "Top" },
    Default  = 1,
    Text     = "Tracer Origin",
    Callback = function(v) ESPSettings.TracerOrigin = v end,
})

local ModL = Tabs.Mods:AddLeftGroupbox("Recoil",       "move-down-right")
local ModR = Tabs.Mods:AddRightGroupbox("Ammo",        "package")

ModL:AddToggle("Mod_RecoilEnable", { Text = "Recoil Reduction", Default = ModSettings.RecoilEnabled, Risky = true, Callback = function(v) ModSettings.RecoilEnabled = v end })
ModL:AddSlider("Mod_RecoilScale", { Text = "Recoil Scale", Default = ModSettings.RecoilScale, Min = 0, Max = 1, Rounding = 2, Callback = function(v) ModSettings.RecoilScale = v end })
ModR:AddToggle("Mod_InfiniteAmmo", { Text = "Infinite Ammo", Default = ModSettings.InfiniteAmmo, Risky = true, Callback = function(v) ModSettings.InfiniteAmmo = v end })

local Lighting = game:GetService("Lighting")

local originalBrightness    = Lighting.Brightness
local originalAmbient       = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogEnd        = Lighting.FogEnd
local originalClockTime     = Lighting.ClockTime

local function setFullbright(enabled)
    if enabled then
        Lighting.Brightness        = 2
        Lighting.Ambient           = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient    = Color3.fromRGB(178, 178, 178)
        Lighting.FogEnd            = 100000
        Lighting.ClockTime         = 14
    else
        Lighting.Brightness        = originalBrightness
        Lighting.Ambient           = originalAmbient
        Lighting.OutdoorAmbient    = originalOutdoorAmbient
        Lighting.FogEnd            = originalFogEnd
        Lighting.ClockTime         = originalClockTime
    end
end

ModR:AddToggle("Mod_Fullbright", {
    Text     = "Fullbright",
    Default  = false,
    Tooltip  = "Removes dark lighting and fog",
    Callback = function(v)
        setFullbright(v)
    end,
})

local RadL = Tabs.Radar:AddLeftGroupbox("Radar",        "radar")
local RadR = Tabs.Radar:AddRightGroupbox("Dot Settings","circle")

RadL:AddToggle("Radar_Enabled", { Text = "Radar", Default = RadarSettings.Enabled, Callback = function(v) RadarSettings.Enabled = v end })
RadL:AddSlider("Radar_Radius", { Text = "Display Radius (px)", Default = RadarSettings.Radius, Min = 40, Max = 300, Rounding = 0, Callback = function(v) RadarSettings.Radius = v end })
RadL:AddSlider("Radar_Range", { Text = "World Range (studs)", Default = RadarSettings.Range, Min = 50, Max = 1500, Rounding = 0, Callback = function(v) RadarSettings.Range = v end })
RadL:AddDivider()
RadL:AddToggle("Radar_Rotate", { Text = "Rotate with Camera", Default = RadarSettings.Rotate, Callback = function(v) RadarSettings.Rotate = v end })
RadL:AddToggle("Radar_ShowOffscreen", { Text = "Clamp Offscreen Dots", Default = RadarSettings.ShowOffscreen, Callback = function(v) RadarSettings.ShowOffscreen = v end })

RadR:AddSlider("Radar_DotSize", { Text = "Enemy Dot Size", Default = RadarSettings.DotSize, Min = 1, Max = 12, Rounding = 0, Callback = function(v) RadarSettings.DotSize = v end })
RadR:AddSlider("Radar_SelfDotSize", { Text = "Self Dot Size", Default = RadarSettings.SelfDotSize, Min = 1, Max = 12, Rounding = 0, Callback = function(v) RadarSettings.SelfDotSize = v end })

local SettingsL = Tabs.Settings:AddLeftGroupbox("Menu Controls", "menu")
local SettingsR = Tabs.Settings:AddRightGroupbox("Script Info",  "info")

-- ── Menu keybind ───────────────────────────────────────────────
SettingsL:AddLabel("Menu Bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI    = false,
    Text    = "Menu Toggle",
})
Library.ToggleKeybind = Options.MenuKeybind

SettingsL:AddDivider()

SettingsL:AddToggle("UI_Watermark", {
    Text     = "Show Watermark",
    Default  = true,
    Tooltip  = "Toggle the top-left watermark",
    Callback = function(v)
        Library:SetWatermarkVisibility(v)
    end,
})

SettingsL:AddToggle("UI_CustomCursor", {
    Text     = "Custom Cursor",
    Default  = true,
    Tooltip  = "Use the library cursor while the menu is open",
    Callback = function(v)
        Library.ShowCustomCursor = v
    end,
})

SettingsL:AddDivider()

SettingsL:AddButton({
    Text        = "Unload Script",
    DoubleClick = true,
    Tooltip     = "Double-click to fully unload Astro",
    Func        = function()
        Library:Notify("Astro", "Unloading...", 2)
        task.delay(0.5, function()
            pcall(Global.__astro_cleanup)
            Library:Unload()
        end)
    end,
})

SettingsR:AddLabel("Astro | v1.0")
SettingsR:AddLabel("Game: TTK")
SettingsR:AddLabel("discord.gg/NtBMqWXySm")
SettingsR:AddDivider()
SettingsR:AddLabel("— Feature Status —")

local lbl_SA     = SettingsR:AddLabel("Silent Aim:   ON")
local lbl_ESP    = SettingsR:AddLabel("ESP:          OFF")
local lbl_Radar  = SettingsR:AddLabel("Radar:        ON")
local lbl_Ammo   = SettingsR:AddLabel("Inf Ammo:     ON")
local lbl_Recoil = SettingsR:AddLabel("Recoil Scale: 0")

task.spawn(function()
    while task.wait(0.5) do
        if not Library then break end
        pcall(function()
            lbl_SA    :SetText("Silent Aim:   " .. (SilentAimSettings.Enabled  and "ON" or "OFF"))
            lbl_ESP   :SetText("ESP:          " .. (ESPSettings.Enabled        and "ON" or "OFF"))
            lbl_Radar :SetText("Radar:        " .. (RadarSettings.Enabled      and "ON" or "OFF"))
            lbl_Ammo  :SetText("Inf Ammo:     " .. (ModSettings.InfiniteAmmo   and "ON" or "OFF"))
            lbl_Recoil:SetText("Recoil Scale: " .. ModSettings.RecoilScale)
        end)
    end
end)

Library:SetWatermark("Astro[BETA] | V1.0")
Library:SetWatermarkVisibility(true)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:SetFolder("Astro/configs")

ThemeManager:ApplyToGroupbox(SettingsL)

SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify("Astro", "Loaded successfully.\nPress RightShift to hide UI.", 5)
