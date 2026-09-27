-- Loose Part Controller - Fluent Modded

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-modded/releases/download/Fluent/FluentPro"))()

local isMobile = UserInputService.TouchEnabled
    and not UserInputService.MouseEnabled
    and not UserInputService.KeyboardEnabled

local Window = Fluent:CreateWindow({
    Title = "Loose Part Controller",
    SubTitle = "Physics Controller",
    Version = "1.2",
    TabWidth = isMobile and 130 or 155,
    Size = isMobile and UDim2.fromOffset(480, 500) or UDim2.fromOffset(620, 580),
    Acrylic = true,
    Theme = "Dark",
    Search = true,
    UserInfoTop = true,
    UserInfoTitle = LocalPlayer.DisplayName,
    UserInfoSubtitle = "@" .. LocalPlayer.Name,
    MinimizeKey = Enum.KeyCode.RightControl,
})

local Tabs = {
    Main = Window:AddTab({ Title = "| Main", Icon = "lucide/boxes" }),
    Orbit = Window:AddTab({ Title = "| Orbit", Icon = "lucide/orbit" }),
    Surf = Window:AddTab({ Title = "| Surf", Icon = "lucide/waves" }),
    Target = Window:AddTab({ Title = "| Target", Icon = "lucide/crosshair" }),
    Filters = Window:AddTab({ Title = "| Filters", Icon = "lucide/filter" }),
    Settings = Window:AddTab({ Title = "| Settings", Icon = "lucide/settings" }),
}

local State = {
    Enabled = false,
    Mode = "Orbit",
    TargetPlayer = LocalPlayer,

    ScanRadius = 1000,
    MaxParts = 150,
    MinSize = 0,
    MaxSize = 100,

    OrbitRadius = 12,
    OrbitHeight = 0,
    OrbitSpeed = 2,
    VerticalSpacing = 0,
    WaveHeight = 0,
    WaveSpeed = 2,
    SpinParts = false,
    SpinSpeed = 2,

    SurfWidth = 18,
    SurfLength = 24,
    SurfHeight = -4,
    SurfWaveHeight = 3,
    SurfWaveSpeed = 4,
    SurfWaveFrequency = 0.45,
    SurfForwardOffset = 0,
    SurfSideWave = 0.4,
    SurfFollowRotation = true,
    SurfTiltParts = true,

    PullSpeed = 15,
    TeleportOffset = Vector3.new(0, 0, 0),

    IgnoreCharacters = true,
    IgnoreTools = true,
    IgnoreAccessories = true,

    DisableCollisions = true,
    ZeroVelocity = true,
}

local ControlledParts = {}
local OriginalProperties = {}
local movementClock = 0
local cleanupClock = 0

local function getRoot(player)
    local character = player and player.Character
    if not character then return nil end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function belongsToCharacter(part)
    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
            return true
        end
        current = current.Parent
    end
    return false
end

local function isValidPart(part, origin)
    if not part:IsA("BasePart") or part.Anchored then return false end
    if State.IgnoreCharacters and belongsToCharacter(part) then return false end
    if State.IgnoreTools and part:FindFirstAncestorWhichIsA("Tool") then return false end
    if State.IgnoreAccessories and part:FindFirstAncestorWhichIsA("Accessory") then return false end

    local size = part.Size.Magnitude
    if size < State.MinSize or size > State.MaxSize then return false end
    if origin and (part.Position - origin).Magnitude > State.ScanRadius then return false end

    return true
end

local function savePart(part)
    if OriginalProperties[part] then return end
    OriginalProperties[part] = {
        CanCollide = part.CanCollide,
        CanTouch = part.CanTouch,
        CanQuery = part.CanQuery,
    }
end

local function configurePart(part)
    savePart(part)
    if State.DisableCollisions then
        part.CanCollide = false
        part.CanTouch = false
    end
end

local function restorePart(part)
    local original = OriginalProperties[part]
    if not original or not part.Parent then return end

    part.CanCollide = original.CanCollide
    part.CanTouch = original.CanTouch
    part.CanQuery = original.CanQuery
end

local function clearParts()
    for _, part in ipairs(ControlledParts) do
        restorePart(part)
    end
    table.clear(ControlledParts)
    table.clear(OriginalProperties)
end

local function scanParts()
    clearParts()

    local root = getRoot(LocalPlayer)
    if not root then
        Fluent:Notify({
            Title = "Scan Failed",
            Content = "Character root not found.",
            Type = "Error",
            Duration = 3,
        })
        return
    end

    local found = {}

    for _, object in ipairs(Workspace:GetDescendants()) do
        if #found >= State.MaxParts then break end

        if isValidPart(object, root.Position) then
            table.insert(found, object)
            configurePart(object)
        end
    end

    ControlledParts = found

    Fluent:Notify({
        Title = "Part Scan",
        Content = "Found " .. tostring(#ControlledParts) .. " loose parts.",
        Type = "Success",
        Duration = 3,
    })
end

local function findPlayer(text)
    text = string.lower(text or "")
    if text == "" then return LocalPlayer end

    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == text or string.lower(player.DisplayName) == text then
            return player
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local username = string.lower(player.Name)
        local display = string.lower(player.DisplayName)

        if string.sub(username, 1, #text) == text
            or string.sub(display, 1, #text) == text then
            return player
        end
    end

    return nil
end

local function getHorizontalCFrame(root)
    local look = root.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)

    if flatLook.Magnitude < 0.01 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end

    return CFrame.lookAt(root.Position, root.Position + flatLook)
end

local function stopVelocity(part)
    if not State.ZeroVelocity then return end
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
end

local function orbitParts(root, dt)
    local count = #ControlledParts
    if count == 0 then return end

    movementClock += dt * State.OrbitSpeed

    for index, part in ipairs(ControlledParts) do
        if not part.Parent then continue end

        local fraction = (index - 1) / count
        local angle = movementClock + fraction * math.pi * 2
        local wave = math.sin(movementClock * State.WaveSpeed + fraction * math.pi * 4) * State.WaveHeight
        local vertical = ((index - 1) - ((count - 1) / 2)) * State.VerticalSpacing

        local position = root.Position + Vector3.new(
            math.cos(angle) * State.OrbitRadius,
            State.OrbitHeight + wave + vertical,
            math.sin(angle) * State.OrbitRadius
        )

        stopVelocity(part)

        local rotation = CFrame.new()
        if State.SpinParts then
            rotation = CFrame.Angles(
                movementClock * State.SpinSpeed,
                movementClock * State.SpinSpeed,
                0
            )
        end

        part.CFrame = CFrame.new(position) * rotation
    end
end

local function surfParts(root, dt)
    local count = #ControlledParts
    if count == 0 then return end

    movementClock += dt * State.SurfWaveSpeed

    local columns = math.max(1, math.ceil(math.sqrt(count * 1.5)))
    local rows = math.max(1, math.ceil(count / columns))
    local base = State.SurfFollowRotation and getHorizontalCFrame(root) or CFrame.new(root.Position)

    for index, part in ipairs(ControlledParts) do
        if not part.Parent then continue end

        local i = index - 1
        local column = i % columns
        local row = math.floor(i / columns)

        local xPercent = columns > 1 and (column / (columns - 1) - 0.5) or 0
        local zPercent = rows > 1 and (row / (rows - 1) - 0.5) or 0

        local x = xPercent * State.SurfWidth
        local z = zPercent * State.SurfLength + State.SurfForwardOffset

        local phase = z * State.SurfWaveFrequency - movementClock
        local wave = math.sin(phase) * State.SurfWaveHeight
        local sideWave = math.sin(x * 0.35 + movementClock * 0.6) * State.SurfSideWave

        local centerStability = 0.55 + math.abs(xPercent) * 0.45
        wave *= centerStability

        local y = State.SurfHeight + wave + sideWave
        local target = base * CFrame.new(x, y, z)
        local rotation = CFrame.new()

        if State.SurfTiltParts then
            local slope = math.cos(phase) * State.SurfWaveHeight * State.SurfWaveFrequency
            rotation = CFrame.Angles(-math.atan(slope), 0, 0)
        end

        stopVelocity(part)
        part.CFrame = target * rotation
    end
end

local function teleportParts(root)
    local position = root.Position + State.TeleportOffset
    for _, part in ipairs(ControlledParts) do
        if part.Parent then
            stopVelocity(part)
            part.CFrame = CFrame.new(position)
        end
    end
end

local function pullParts(root, dt)
    for _, part in ipairs(ControlledParts) do
        if not part.Parent then continue end

        local difference = root.Position - part.Position
        local distance = difference.Magnitude

        if distance > 0.1 then
            local step = math.min(distance, State.PullSpeed * dt)
            stopVelocity(part)
            part.CFrame = CFrame.new(part.Position + difference.Unit * step)
        end
    end
end

local function sphereParts(root, dt)
    local count = #ControlledParts
    if count == 0 then return end

    movementClock += dt * State.OrbitSpeed
    local goldenAngle = math.pi * (3 - math.sqrt(5))

    for index, part in ipairs(ControlledParts) do
        if not part.Parent then continue end

        local i = index - 1
        local y = 1 - (i / math.max(count - 1, 1)) * 2
        local radius = math.sqrt(math.max(0, 1 - y * y))
        local theta = goldenAngle * i + movementClock

        local offset = Vector3.new(
            math.cos(theta) * radius,
            y,
            math.sin(theta) * radius
        ) * State.OrbitRadius

        stopVelocity(part)
        part.CFrame = CFrame.new(root.Position + offset + Vector3.new(0, State.OrbitHeight, 0))
    end
end

local function stackParts(root)
    local height = 0

    for _, part in ipairs(ControlledParts) do
        if part.Parent then
            height += math.max(part.Size.Y, 1)
            stopVelocity(part)
            part.CFrame = CFrame.new(root.Position + Vector3.new(
                State.TeleportOffset.X,
                State.TeleportOffset.Y + height,
                State.TeleportOffset.Z
            ))
        end
    end
end

local function lineParts(root)
    local count = #ControlledParts
    local spacing = 4

    for index, part in ipairs(ControlledParts) do
        if not part.Parent then continue end

        local offset = root.CFrame.RightVector * (((index - 1) - (count - 1) / 2) * spacing)
        stopVelocity(part)
        part.CFrame = CFrame.new(root.Position + offset + Vector3.new(0, State.OrbitHeight, 0))
    end
end

RunService.Heartbeat:Connect(function(dt)
    if not State.Enabled then return end

    cleanupClock += dt
    if cleanupClock >= 2 then
        cleanupClock = 0

        for index = #ControlledParts, 1, -1 do
            local part = ControlledParts[index]
            if not part or not part.Parent or part.Anchored then
                table.remove(ControlledParts, index)
            end
        end
    end

    local root = getRoot(State.TargetPlayer or LocalPlayer)
    if not root then return end

    if State.Mode == "Orbit" then
        orbitParts(root, dt)
    elseif State.Mode == "Surf" then
        surfParts(root, dt)
    elseif State.Mode == "Teleport" then
        teleportParts(root)
    elseif State.Mode == "Pull" then
        pullParts(root, dt)
    elseif State.Mode == "Sphere" then
        sphereParts(root, dt)
    elseif State.Mode == "Stack" then
        stackParts(root)
    elseif State.Mode == "Line" then
        lineParts(root)
    end
end)

local MainSection = Tabs.Main:AddSection("Controller", "lucide/boxes")

MainSection:AddToggle("PartControllerEnabled", {
    Title = "Enable Part Controller",
    Description = "Control the currently scanned loose parts.",
    Default = false,
    Callback = function(value)
        State.Enabled = value

        if value and #ControlledParts == 0 then
            scanParts()
        end

        for _, part in ipairs(ControlledParts) do
            if value then configurePart(part) else restorePart(part) end
        end
    end,
})

MainSection:AddDropdown("MovementMode", {
    Title = "Movement Mode",
    Values = { "Orbit", "Surf", "Teleport", "Pull", "Sphere", "Stack", "Line" },
    Default = "Orbit",
    Multi = false,
    Animated = true,
    Description = "Choose how loose parts move.",
    Callback = function(value)
        State.Mode = value
        movementClock = 0
    end,
})

MainSection:AddButton({
    Title = "Scan Loose Parts",
    Icon = "lucide/scan-search",
    Description = "Find nearby unanchored parts.",
    Callback = scanParts,
})

MainSection:AddButton({
    Title = "Release All Parts",
    Icon = "lucide/unlink",
    Callback = function()
        State.Enabled = false
        clearParts()
    end,
})

local OrbitSection = Tabs.Orbit:AddSection("Orbit Configuration", "lucide/orbit")

OrbitSection:AddSlider("OrbitRadius", {
    Title = "Radius", Min = 2, Max = 100, Default = State.OrbitRadius, Rounding = 0,
    Callback = function(v) State.OrbitRadius = v end,
})

OrbitSection:AddSlider("OrbitSpeed", {
    Title = "Orbit Speed", Min = -10, Max = 10, Default = State.OrbitSpeed, Rounding = 1,
    Callback = function(v) State.OrbitSpeed = v end,
})

OrbitSection:AddSlider("OrbitHeight", {
    Title = "Height", Min = -50, Max = 50, Default = State.OrbitHeight, Rounding = 1,
    Callback = function(v) State.OrbitHeight = v end,
})

OrbitSection:AddSlider("VerticalSpacing", {
    Title = "Vertical Spacing", Min = 0, Max = 5, Default = State.VerticalSpacing, Rounding = 1,
    Callback = function(v) State.VerticalSpacing = v end,
})

local OrbitEffects = Tabs.Orbit:AddCollapsibleSection("Orbit Effects", "lucide/sparkles", false)

OrbitEffects:AddSlider("OrbitWaveHeight", {
    Title = "Wave Height", Min = 0, Max = 20, Default = State.WaveHeight, Rounding = 1,
    Callback = function(v) State.WaveHeight = v end,
})

OrbitEffects:AddSlider("OrbitWaveSpeed", {
    Title = "Wave Speed", Min = 0, Max = 10, Default = State.WaveSpeed, Rounding = 1,
    Callback = function(v) State.WaveSpeed = v end,
})

OrbitEffects:AddToggle("SpinParts", {
    Title = "Spin Parts", Default = State.SpinParts,
    Callback = function(v) State.SpinParts = v end,
})

OrbitEffects:AddSlider("SpinSpeed", {
    Title = "Spin Speed", Min = 0, Max = 10, Default = State.SpinSpeed, Rounding = 1,
    Callback = function(v) State.SpinSpeed = v end,
})

local SurfShape = Tabs.Surf:AddSection("Surf Platform", "lucide/waves")

SurfShape:AddParagraph({
    Title = "Surf Mode",
    Content = "Loose parts form a traveling wave underneath the target player.",
})

SurfShape:AddSlider("SurfWidth", {
    Title = "Wave Width", Min = 4, Max = 60, Default = State.SurfWidth, Rounding = 0,
    Callback = function(v) State.SurfWidth = v end,
})

SurfShape:AddSlider("SurfLength", {
    Title = "Wave Length", Min = 4, Max = 80, Default = State.SurfLength, Rounding = 0,
    Callback = function(v) State.SurfLength = v end,
})

SurfShape:AddSlider("SurfHeight", {
    Title = "Height Relative to Player", Min = -15, Max = 5, Default = State.SurfHeight, Rounding = 1,
    Callback = function(v) State.SurfHeight = v end,
})

SurfShape:AddSlider("SurfForwardOffset", {
    Title = "Forward / Back Offset", Min = -30, Max = 30, Default = State.SurfForwardOffset, Rounding = 1,
    Callback = function(v) State.SurfForwardOffset = v end,
})

local SurfWave = Tabs.Surf:AddSection("Wave Animation", "lucide/activity")

SurfWave:AddSlider("SurfWaveHeight", {
    Title = "Wave Height", Min = 0, Max = 12, Default = State.SurfWaveHeight, Rounding = 1,
    Callback = function(v) State.SurfWaveHeight = v end,
})

SurfWave:AddSlider("SurfWaveSpeed", {
    Title = "Wave Speed", Min = -15, Max = 15, Default = State.SurfWaveSpeed, Rounding = 1,
    Callback = function(v) State.SurfWaveSpeed = v end,
})

SurfWave:AddSlider("SurfWaveFrequency", {
    Title = "Wave Frequency", Min = 0.05, Max = 2, Default = State.SurfWaveFrequency, Rounding = 2,
    Callback = function(v) State.SurfWaveFrequency = v end,
})

SurfWave:AddSlider("SurfSideWave", {
    Title = "Side Wave", Min = 0, Max = 5, Default = State.SurfSideWave, Rounding = 1,
    Callback = function(v) State.SurfSideWave = v end,
})

local SurfBehavior = Tabs.Surf:AddSection("Behavior", "lucide/settings-2")

SurfBehavior:AddToggle("SurfFollowRotation", {
    Title = "Follow Player Direction", Default = State.SurfFollowRotation,
    Callback = function(v) State.SurfFollowRotation = v end,
})

SurfBehavior:AddToggle("SurfTiltParts", {
    Title = "Tilt Along Wave", Default = State.SurfTiltParts,
    Callback = function(v) State.SurfTiltParts = v end,
})

local TargetSection = Tabs.Target:AddSection("Target Player", "lucide/user-round-search")

TargetSection:AddInput("TargetPlayerInput", {
    Title = "Player",
    Placeholder = "Username / display name",
    Default = LocalPlayer.Name,
    Callback = function(value)
        local found = findPlayer(value)

        if found then
            State.TargetPlayer = found
            Fluent:Notify({
                Title = "Target Changed",
                Content = "Target: " .. found.DisplayName .. " (@" .. found.Name .. ")",
                Type = "Success",
                Duration = 3,
            })
        else
            Fluent:Notify({
                Title = "Player Not Found",
                Content = tostring(value),
                Type = "Error",
                Duration = 3,
            })
        end
    end,
})

TargetSection:AddButton({
    Title = "Target Yourself",
    Icon = "lucide/user",
    Callback = function()
        State.TargetPlayer = LocalPlayer
    end,
})

local OffsetSection = Tabs.Target:AddCollapsibleSection("Teleport Offset", "lucide/move-3d", false)

local offsetX, offsetY, offsetZ = 0, 0, 0

local function updateOffset()
    State.TeleportOffset = Vector3.new(offsetX, offsetY, offsetZ)
end

OffsetSection:AddSlider("OffsetX", {
    Title = "X Offset", Min = -50, Max = 50, Default = 0, Rounding = 1,
    Callback = function(v) offsetX = v updateOffset() end,
})

OffsetSection:AddSlider("OffsetY", {
    Title = "Y Offset", Min = -50, Max = 50, Default = 0, Rounding = 1,
    Callback = function(v) offsetY = v updateOffset() end,
})

OffsetSection:AddSlider("OffsetZ", {
    Title = "Z Offset", Min = -50, Max = 50, Default = 0, Rounding = 1,
    Callback = function(v) offsetZ = v updateOffset() end,
})

local ScanSection = Tabs.Filters:AddSection("Part Scanner", "lucide/radar")

ScanSection:AddSlider("ScanRadius", {
    Title = "Scan Radius", Min = 25, Max = 5000, Default = State.ScanRadius, Rounding = 0,
    Callback = function(v) State.ScanRadius = v end,
})

ScanSection:AddSlider("MaxParts", {
    Title = "Maximum Parts", Min = 1, Max = 500, Default = State.MaxParts, Rounding = 0,
    Callback = function(v) State.MaxParts = v end,
})

ScanSection:AddSlider("MaxPartSize", {
    Title = "Maximum Part Size", Min = 1, Max = 300, Default = State.MaxSize, Rounding = 0,
    Callback = function(v) State.MaxSize = v end,
})

local IgnoreSection = Tabs.Filters:AddSection("Ignore", "lucide/eye-off")

IgnoreSection:AddToggle("IgnoreCharacters", {
    Title = "Ignore Character Parts", Default = State.IgnoreCharacters,
    Callback = function(v) State.IgnoreCharacters = v end,
})

IgnoreSection:AddToggle("IgnoreTools", {
    Title = "Ignore Tools", Default = State.IgnoreTools,
    Callback = function(v) State.IgnoreTools = v end,
})

IgnoreSection:AddToggle("IgnoreAccessories", {
    Title = "Ignore Accessories", Default = State.IgnoreAccessories,
    Callback = function(v) State.IgnoreAccessories = v end,
})

local PhysicsSection = Tabs.Settings:AddSection("Physics", "lucide/gauge")

PhysicsSection:AddToggle("DisableCollisions", {
    Title = "Disable Part Collisions",
    Default = State.DisableCollisions,
    Callback = function(value)
        State.DisableCollisions = value

        for _, part in ipairs(ControlledParts) do
            if value then configurePart(part) else restorePart(part) end
        end
    end,
})

PhysicsSection:AddToggle("ZeroVelocity", {
    Title = "Zero Velocity", Default = State.ZeroVelocity,
    Callback = function(v) State.ZeroVelocity = v end,
})

PhysicsSection:AddSlider("PullSpeed", {
    Title = "Pull Speed", Min = 1, Max = 200, Default = State.PullSpeed, Rounding = 0,
    Callback = function(v) State.PullSpeed = v end,
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Loose Part Controller",
    Content = "Loaded successfully.",
    SubContent = "Scan loose parts, select a mode, then enable the controller.",
    Type = "Success",
    Duration = 4,
})
