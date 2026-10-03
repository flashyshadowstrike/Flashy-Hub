local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet(
    "https://github.com/StyearX/Fluent-modded/releases/download/Fluent/FluentPro"
))()

local isMobile =
    UserInputService.TouchEnabled
    and not UserInputService.MouseEnabled
    and not UserInputService.KeyboardEnabled

local Window = Fluent:CreateWindow({
    Title = "Bring Parts",
    SubTitle = "Universal Physics Controller",
    Version = "2.2",
    TabWidth = isMobile and 130 or 155,
    Size = isMobile
        and UDim2.fromOffset(480, 500)
        or UDim2.fromOffset(620, 580),
    Acrylic = true,
    Theme = "Dark",
    Search = true,
    UserInfoTop = true,
    UserInfoTitle = LocalPlayer.DisplayName,
    UserInfoSubtitle = "@" .. LocalPlayer.Name,
    MinimizeKey = Enum.KeyCode.K,
})

local Tabs = {
    Main = Window:AddTab({
        Title = "| Main",
        Icon = "lucide/boxes",
    }),

    Orbit = Window:AddTab({
        Title = "| Orbit",
        Icon = "lucide/orbit",
    }),

    Surf = Window:AddTab({
        Title = "| Surf",
        Icon = "lucide/waves",
    }),

    Tornado = Window:AddTab({
        Title = "| Tornado",
        Icon = "lucide/wind",
    }),

    Target = Window:AddTab({
        Title = "| Target",
        Icon = "lucide/crosshair",
    }),

    Filters = Window:AddTab({
        Title = "| Filters",
        Icon = "lucide/filter",
    }),

    Settings = Window:AddTab({
        Title = "| Settings",
        Icon = "lucide/settings",
    }),
}

local State = {
    Enabled = false,
    Mode = "Orbit",
    TargetPlayer = LocalPlayer,

    ScanRadius = 1000,
    MinSize = 0,
    MaxSize = 100,

    OrbitRadius = 12,
    OrbitHeight = 0,
    OrbitSpeed = 2,
    OrbitWaveHeight = 0,
    OrbitWaveSpeed = 2,
    OrbitSpin = false,
    OrbitSpinSpeed = 2,

    SurfWidth = 18,
    SurfLength = 24,
    SurfHeight = -3.5,
    SurfWaveHeight = 3,
    SurfWaveSpeed = 4,
    SurfWaveFrequency = 0.45,
    SurfSideWave = 0.4,
    SurfForwardOffset = 0,
    SurfFollowRotation = true,
    SurfTilt = true,
    SurfCollisions = true,

    TornadoHeight = 45,
    TornadoRadius = 18,
    TornadoBaseRadius = 3,
    TornadoSpeed = 4,
    TornadoVerticalWave = 2,
    TornadoVerticalWaveSpeed = 3,
    TornadoSpinParts = true,
    TornadoPartSpinSpeed = 5,

    PullSpeed = 30,

    SphereRadius = 12,
    SphereSpeed = 2,

    LineSpacing = 4,
    StackSpacing = 0.25,

    Offset = Vector3.new(0, 0, 0),

    IgnoreCharacters = true,
    IgnoreTools = true,
    IgnoreAccessories = true,
    IgnoreHandles = true,

    DisableCollision = true,

    NetworkVelocity = Vector3.new(
        14.46262424,
        14.46262424,
        14.46262424
    ),

    Responsiveness = 200,
    MaxVelocity = 100000,

    UIVisible = true,
}

local RuntimeFolder =
    Workspace:FindFirstChild("__FlashyBringParts")

if RuntimeFolder then
    RuntimeFolder:Destroy()
end

RuntimeFolder = Instance.new("Folder")
RuntimeFolder.Name = "__FlashyBringParts"
RuntimeFolder.Parent = Workspace

local ControlledParts = {}
local PartData = {}

local movementClock = 0
local cleanupClock = 0

local function getRoot(player)
    if not player then
        return nil
    end

    local character = player.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function getTargetRoot()
    return getRoot(State.TargetPlayer or LocalPlayer)
end

local function belongsToCharacter(part)
    local current = part

    while current and current ~= Workspace do
        if current:IsA("Model")
            and Players:GetPlayerFromCharacter(current)
        then
            return true
        end

        current = current.Parent
    end

    return false
end

local function isValidPart(part, origin)
    if not part:IsA("BasePart") then
        return false
    end

    if part.Anchored then
        return false
    end

    if part:IsDescendantOf(RuntimeFolder) then
        return false
    end

    if State.IgnoreCharacters and belongsToCharacter(part) then
        return false
    end

    if State.IgnoreTools
        and part:FindFirstAncestorWhichIsA("Tool")
    then
        return false
    end

    if State.IgnoreAccessories
        and part:FindFirstAncestorWhichIsA("Accessory")
    then
        return false
    end

    if State.IgnoreHandles
        and part.Name == "Handle"
    then
        return false
    end

    local magnitude = part.Size.Magnitude

    if magnitude < State.MinSize then
        return false
    end

    if magnitude > State.MaxSize then
        return false
    end

    if origin
        and (part.Position - origin).Magnitude > State.ScanRadius
    then
        return false
    end

    return true
end

local function enableNetworkControl()
    pcall(function()
        LocalPlayer.ReplicationFocus = Workspace
    end)

    if sethiddenproperty then
        pcall(function()
            sethiddenproperty(
                LocalPlayer,
                "SimulationRadius",
                math.huge
            )
        end)
    end
end

local function createController(part)
    if PartData[part] then
        return
    end

    local targetPart = Instance.new("Part")

    targetPart.Name = "Target"
    targetPart.Size = Vector3.new(0.1, 0.1, 0.1)
    targetPart.Transparency = 1
    targetPart.Anchored = true
    targetPart.CanCollide = false
    targetPart.CanTouch = false
    targetPart.CanQuery = false
    targetPart.CFrame = part.CFrame
    targetPart.Parent = RuntimeFolder

    local targetAttachment = Instance.new("Attachment")
    targetAttachment.Name = "__BringTarget"
    targetAttachment.Parent = targetPart

    local attachment = Instance.new("Attachment")
    attachment.Name = "__BringAttachment"
    attachment.Parent = part

    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Name = "__BringPosition"
    alignPosition.Attachment0 = attachment
    alignPosition.Attachment1 = targetAttachment
    alignPosition.MaxForce = math.huge
    alignPosition.MaxVelocity = State.MaxVelocity
    alignPosition.Responsiveness = State.Responsiveness
    alignPosition.ApplyAtCenterOfMass = true
    alignPosition.RigidityEnabled = false
    alignPosition.Parent = part

    local alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Name = "__BringOrientation"
    alignOrientation.Attachment0 = attachment
    alignOrientation.Attachment1 = targetAttachment
    alignOrientation.MaxTorque = math.huge
    alignOrientation.MaxAngularVelocity = math.huge
    alignOrientation.Responsiveness = State.Responsiveness
    alignOrientation.RigidityEnabled = false
    alignOrientation.Parent = part

    local torque = Instance.new("Torque")
    torque.Name = "__BringTorque"
    torque.Attachment0 = attachment
    torque.Torque = Vector3.zero
    torque.RelativeTo = Enum.ActuatorRelativeTo.World
    torque.Parent = part

    PartData[part] = {
        OriginalCanCollide = part.CanCollide,
        OriginalCanTouch = part.CanTouch,
        OriginalCanQuery = part.CanQuery,
        OriginalPhysicalProperties = part.CustomPhysicalProperties,

        TargetPart = targetPart,
        TargetAttachment = targetAttachment,
        Attachment = attachment,
        AlignPosition = alignPosition,
        AlignOrientation = alignOrientation,
        Torque = torque,
    }

    pcall(function()
        part.CustomPhysicalProperties =
            PhysicalProperties.new(
                0.01,
                0,
                0,
                0,
                0
            )
    end)
end

local function removeController(part)
    local data = PartData[part]

    if not data then
        return
    end

    if part.Parent then
        pcall(function()
            part.CanCollide =
                data.OriginalCanCollide

            part.CanTouch =
                data.OriginalCanTouch

            part.CanQuery =
                data.OriginalCanQuery

            part.CustomPhysicalProperties =
                data.OriginalPhysicalProperties
        end)
    end

    if data.AlignPosition then
        data.AlignPosition:Destroy()
    end

    if data.AlignOrientation then
        data.AlignOrientation:Destroy()
    end

    if data.Torque then
        data.Torque:Destroy()
    end

    if data.Attachment then
        data.Attachment:Destroy()
    end

    if data.TargetPart then
        data.TargetPart:Destroy()
    end

    PartData[part] = nil
end

local function updateCollision(part)
    local data = PartData[part]

    if not data
        or not part.Parent
    then
        return
    end

    if State.Mode == "Surf"
        and State.SurfCollisions
    then
        part.CanCollide = true
        part.CanTouch = true

    elseif State.DisableCollision then
        part.CanCollide = false
        part.CanTouch = false

    else
        part.CanCollide =
            data.OriginalCanCollide

        part.CanTouch =
            data.OriginalCanTouch
    end
end

local function updateAllCollisions()
    for _, part in ipairs(ControlledParts) do
        updateCollision(part)
    end
end

local function releaseParts()
    State.Enabled = false

    for _, part in ipairs(ControlledParts) do
        removeController(part)
    end

    table.clear(ControlledParts)

    for part in pairs(PartData) do
        removeController(part)
    end

    table.clear(PartData)
end

local function scanParts()
    releaseParts()

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

    enableNetworkControl()

    local found = {}

    for _, object in ipairs(
        Workspace:GetDescendants()
    ) do
        if isValidPart(
            object,
            root.Position
        ) then
            table.insert(
                found,
                object
            )

            createController(
                object
            )
        end
    end

    ControlledParts = found

    updateAllCollisions()

    Fluent:Notify({
        Title = "Part Scan",
        Content =
            "Found "
            .. tostring(#ControlledParts)
            .. " loose parts.",

        SubContent = "No part-count limit is enabled.",

        Type = "Success",
        Duration = 4,
    })
end

local function findPlayer(text)
    text = string.lower(text or "")

    if text == "" then
        return LocalPlayer
    end

    for _, player in ipairs(
        Players:GetPlayers()
    ) do
        if string.lower(player.Name) == text then
            return player
        end

        if string.lower(player.DisplayName) == text then
            return player
        end
    end

    for _, player in ipairs(
        Players:GetPlayers()
    ) do
        local username =
            string.lower(
                player.Name
            )

        local display =
            string.lower(
                player.DisplayName
            )

        if string.find(
            username,
            text,
            1,
            true
        ) then
            return player
        end

        if string.find(
            display,
            text,
            1,
            true
        ) then
            return player
        end
    end

    return nil
end

local function getHorizontalCFrame(root)
    local look =
        root.CFrame.LookVector

    local flatLook =
        Vector3.new(
            look.X,
            0,
            look.Z
        )

    if flatLook.Magnitude < 0.01 then
        flatLook =
            Vector3.new(
                0,
                0,
                -1
            )
    else
        flatLook =
            flatLook.Unit
    end

    return CFrame.lookAt(
        root.Position,
        root.Position + flatLook
    )
end

local function setPartTarget(part, cf)
    local data =
        PartData[part]

    if not data
        or not data.TargetPart
    then
        return
    end

    data.TargetPart.CFrame = cf
end

local function orbitParts(root, dt)
    local count =
        #ControlledParts

    if count == 0 then
        return
    end

    movementClock +=
        dt * State.OrbitSpeed

    for index, part in ipairs(
        ControlledParts
    ) do
        if not part.Parent then
            continue
        end

        local fraction =
            (index - 1) / count

        local angle =
            movementClock
            + fraction
            * math.pi
            * 2

        local wave =
            math.sin(
                movementClock
                    * State.OrbitWaveSpeed
                + fraction
                    * math.pi
                    * 4
            )
            * State.OrbitWaveHeight

        local position =
            root.Position
            + Vector3.new(
                math.cos(angle)
                    * State.OrbitRadius,

                State.OrbitHeight
                    + wave,

                math.sin(angle)
                    * State.OrbitRadius
            )

        local rotation =
            CFrame.new()

        if State.OrbitSpin then
            rotation =
                CFrame.Angles(
                    movementClock
                        * State.OrbitSpinSpeed,

                    movementClock
                        * State.OrbitSpinSpeed,

                    0
                )
        end

        setPartTarget(
            part,
            CFrame.new(position)
                * rotation
        )
    end
end

local function surfParts(root, dt)
    local count =
        #ControlledParts

    if count == 0 then
        return
    end

    movementClock +=
        dt * State.SurfWaveSpeed

    local columns =
        math.max(
            1,
            math.ceil(
                math.sqrt(
                    count * 1.7
                )
            )
        )

    local rows =
        math.max(
            1,
            math.ceil(
                count / columns
            )
        )

    local base =
        State.SurfFollowRotation
        and getHorizontalCFrame(root)
        or CFrame.new(root.Position)

    for index, part in ipairs(
        ControlledParts
    ) do
        if not part.Parent then
            continue
        end

        local i = index - 1

        local column =
            i % columns

        local row =
            math.floor(
                i / columns
            )

        local xPercent =
            columns > 1
            and column
                / (columns - 1)
                - 0.5
            or 0

        local zPercent =
            rows > 1
            and row
                / (rows - 1)
                - 0.5
            or 0

        local x =
            xPercent
            * State.SurfWidth

        local z =
            zPercent
            * State.SurfLength
            + State.SurfForwardOffset

        local phase =
            z
            * State.SurfWaveFrequency
            - movementClock

        local centerDistance =
            math.sqrt(
                xPercent * xPercent
                + zPercent * zPercent
            )

        local stability =
            math.clamp(
                centerDistance
                    * 1.35,
                0.3,
                1
            )

        local wave =
            math.sin(phase)
            * State.SurfWaveHeight
            * stability

        local sideWave =
            math.sin(
                x * 0.3
                + movementClock
                    * 0.55
            )
            * State.SurfSideWave
            * stability

        local y =
            State.SurfHeight
            + wave
            + sideWave

        local rotation =
            CFrame.new()

        if State.SurfTilt then
            local slope =
                math.cos(phase)
                * State.SurfWaveHeight
                * State.SurfWaveFrequency
                * stability

            rotation =
                CFrame.Angles(
                    -math.atan(slope),
                    0,
                    0
                )
        end

        setPartTarget(
            part,
            base
                * CFrame.new(
                    x,
                    y,
                    z
                )
                * rotation
        )
    end
end

local function tornadoParts(root, dt)
    local count =
        #ControlledParts

    if count == 0 then
        return
    end

    movementClock +=
        dt * State.TornadoSpeed

    for index, part in ipairs(
        ControlledParts
    ) do
        if not part.Parent then
            continue
        end

        local fraction =
            count > 1
            and (index - 1)
                / (count - 1)
            or 0

        local height =
            fraction
            * State.TornadoHeight

        local radius =
            State.TornadoBaseRadius
            + fraction
                * (
                    State.TornadoRadius
                    - State.TornadoBaseRadius
                )

        local turns =
            math.max(
                4,
                math.sqrt(count)
            )

        local angle =
            movementClock
            + fraction
                * math.pi
                * 2
                * turns

        local verticalWave =
            math.sin(
                movementClock
                    * State.TornadoVerticalWaveSpeed
                + fraction
                    * math.pi
                    * 8
            )
            * State.TornadoVerticalWave

        local x =
            math.cos(angle)
            * radius

        local z =
            math.sin(angle)
            * radius

        local y =
            height
            + verticalWave

        local target =
            CFrame.new(
                root.Position
                + State.Offset
                + Vector3.new(
                    x,
                    y,
                    z
                )
            )

        if State.TornadoSpinParts then
            target *=
                CFrame.Angles(
                    movementClock
                        * State.TornadoPartSpinSpeed,

                    angle,

                    movementClock
                        * State.TornadoPartSpinSpeed
                )
        else
            target *=
                CFrame.Angles(
                    0,
                    -angle,
                    0
                )
        end

        setPartTarget(
            part,
            target
        )
    end
end

local function teleportParts(root)
    local target =
        CFrame.new(
            root.Position
            + State.Offset
        )

    for _, part in ipairs(
        ControlledParts
    ) do
        if part.Parent then
            setPartTarget(
                part,
                target
            )
        end
    end
end

local function pullParts(root, dt)
    for _, part in ipairs(
        ControlledParts
    ) do
        if not part.Parent then
            continue
        end

        local data =
            PartData[part]

        if not data
            or not data.TargetPart
        then
            continue
        end

        local current =
            data.TargetPart.Position

        local target =
            root.Position
            + State.Offset

        local difference =
            target - current

        local distance =
            difference.Magnitude

        if distance > 0.05 then
            local step =
                math.min(
                    distance,
                    State.PullSpeed * dt
                )

            local nextPosition =
                current
                + difference.Unit * step

            setPartTarget(
                part,
                CFrame.new(nextPosition)
            )
        end
    end
end

local function sphereParts(root, dt)
    local count =
        #ControlledParts

    if count == 0 then
        return
    end

    movementClock +=
        dt * State.SphereSpeed

    local goldenAngle =
        math.pi
        * (
            3
            - math.sqrt(5)
        )

    for index, part in ipairs(
        ControlledParts
    ) do
        if not part.Parent then
            continue
        end

        local i =
            index - 1

        local y =
            1
            - (
                i
                / math.max(
                    count - 1,
                    1
                )
            )
            * 2

        local radiusAtHeight =
            math.sqrt(
                math.max(
                    0,
                    1 - y * y
                )
            )

        local theta =
            goldenAngle * i
            + movementClock

        local offset =
            Vector3.new(
                math.cos(theta)
                    * radiusAtHeight,

                y,

                math.sin(theta)
                    * radiusAtHeight
            )
            * State.SphereRadius

        setPartTarget(
            part,
            CFrame.new(
                root.Position
                + offset
            )
        )
    end
end

local function stackParts(root)
    local height =
        State.Offset.Y

    for _, part in ipairs(
        ControlledParts
    ) do
        if not part.Parent then
            continue
        end

        local partHeight =
            math.max(
                part.Size.Y,
                0.5
            )

        height +=
            partHeight / 2

        setPartTarget(
            part,
            CFrame.new(
                root.Position
                + Vector3.new(
                    State.Offset.X,
                    height,
                    State.Offset.Z
                )
            )
        )

        height +=
            partHeight / 2
            + State.StackSpacing
    end
end

local function lineParts(root)
    local count =
        #ControlledParts

    local base =
        getHorizontalCFrame(root)

    for index, part in ipairs(
        ControlledParts
    ) do
        if not part.Parent then
            continue
        end

        local position =
            (
                index - 1
                - (count - 1) / 2
            )
            * State.LineSpacing

        setPartTarget(
            part,
            base
                * CFrame.new(
                    position,
                    State.Offset.Y,
                    State.Offset.Z
                )
        )
    end
end

RunService.Heartbeat:Connect(function(dt)
    enableNetworkControl()

    for _, part in ipairs(
        ControlledParts
    ) do
        if part and part.Parent then
            pcall(function()
                part.AssemblyLinearVelocity =
                    State.NetworkVelocity
            end)
        end
    end

    if not State.Enabled then
        return
    end

    cleanupClock += dt

    if cleanupClock >= 1 then
        cleanupClock = 0

        for index =
            #ControlledParts,
            1,
            -1
        do
            local part =
                ControlledParts[index]

            if not part
                or not part.Parent
                or part.Anchored
            then
                if part then
                    removeController(
                        part
                    )
                end

                table.remove(
                    ControlledParts,
                    index
                )
            end
        end
    end

    local root =
        getTargetRoot()

    if not root then
        return
    end

    if State.Mode == "Orbit" then
        orbitParts(root, dt)

    elseif State.Mode == "Surf" then
        surfParts(root, dt)

    elseif State.Mode == "Tornado" then
        tornadoParts(root, dt)

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

local MainSection =
    Tabs.Main:AddSection(
        "Controller",
        "lucide/boxes"
    )

MainSection:AddToggle(
    "ControllerEnabled",
    {
        Title = "Enable Bring Parts",
        Description =
            "Starts moving all scanned loose parts.",
        Default = false,

        Callback = function(value)
            if value
                and #ControlledParts == 0
            then
                scanParts()
            end

            State.Enabled = value

            updateAllCollisions()
        end,
    }
)

MainSection:AddDropdown(
    "MovementMode",
    {
        Title = "Movement Mode",

        Values = {
            "Orbit",
            "Surf",
            "Tornado",
            "Teleport",
            "Pull",
            "Sphere",
            "Stack",
            "Line",
        },

        Default = "Orbit",
        Multi = false,
        Animated = true,

        Callback = function(value)
            State.Mode = value

            movementClock = 0

            updateAllCollisions()

            Fluent:Notify({
                Title = "Movement Mode",
                Content = value,
                Type = "Info",
                Duration = 2,
            })
        end,
    }
)

MainSection:AddButton({
    Title = "Scan All Loose Parts",
    Icon = "lucide/scan-search",
    Description =
        "Scans every valid loose part within the selected radius.",

    Callback = scanParts,
})

MainSection:AddButton({
    Title = "Release All Parts",
    Icon = "lucide/unlink",

    Callback = function()
        releaseParts()
    end,
})

local OrbitSection =
    Tabs.Orbit:AddSection(
        "Orbit",
        "lucide/orbit"
    )

OrbitSection:AddSlider("OrbitRadius", {
    Title = "Radius",
    Min = 2,
    Max = 100,
    Default = State.OrbitRadius,
    Rounding = 0,
    Callback = function(v)
        State.OrbitRadius = v
    end,
})

OrbitSection:AddSlider("OrbitHeight", {
    Title = "Height",
    Min = -50,
    Max = 50,
    Default = State.OrbitHeight,
    Rounding = 1,
    Callback = function(v)
        State.OrbitHeight = v
    end,
})

OrbitSection:AddSlider("OrbitSpeed", {
    Title = "Speed",
    Min = -15,
    Max = 15,
    Default = State.OrbitSpeed,
    Rounding = 1,
    Callback = function(v)
        State.OrbitSpeed = v
    end,
})

OrbitSection:AddSlider("OrbitWaveHeight", {
    Title = "Wave Height",
    Min = 0,
    Max = 20,
    Default = State.OrbitWaveHeight,
    Rounding = 1,
    Callback = function(v)
        State.OrbitWaveHeight = v
    end,
})

OrbitSection:AddSlider("OrbitWaveSpeed", {
    Title = "Wave Speed",
    Min = 0,
    Max = 15,
    Default = State.OrbitWaveSpeed,
    Rounding = 1,
    Callback = function(v)
        State.OrbitWaveSpeed = v
    end,
})

OrbitSection:AddToggle("OrbitSpin", {
    Title = "Spin Parts",
    Default = State.OrbitSpin,
    Callback = function(v)
        State.OrbitSpin = v
    end,
})

OrbitSection:AddSlider("OrbitSpinSpeed", {
    Title = "Part Spin Speed",
    Min = 0,
    Max = 15,
    Default = State.OrbitSpinSpeed,
    Rounding = 1,
    Callback = function(v)
        State.OrbitSpinSpeed = v
    end,
})

local SurfPlatform =
    Tabs.Surf:AddSection(
        "Surf Platform",
        "lucide/waves"
    )

SurfPlatform:AddSlider("SurfWidth", {
    Title = "Width",
    Min = 4,
    Max = 60,
    Default = State.SurfWidth,
    Rounding = 0,
    Callback = function(v)
        State.SurfWidth = v
    end,
})

SurfPlatform:AddSlider("SurfLength", {
    Title = "Length",
    Min = 4,
    Max = 80,
    Default = State.SurfLength,
    Rounding = 0,
    Callback = function(v)
        State.SurfLength = v
    end,
})

SurfPlatform:AddSlider("SurfHeight", {
    Title = "Height Under Player",
    Min = -15,
    Max = 5,
    Default = State.SurfHeight,
    Rounding = 1,
    Callback = function(v)
        State.SurfHeight = v
    end,
})

SurfPlatform:AddSlider("SurfForwardOffset", {
    Title = "Forward Offset",
    Min = -30,
    Max = 30,
    Default = State.SurfForwardOffset,
    Rounding = 1,
    Callback = function(v)
        State.SurfForwardOffset = v
    end,
})

local SurfWave =
    Tabs.Surf:AddSection(
        "Wave",
        "lucide/activity"
    )

SurfWave:AddSlider("SurfWaveHeight", {
    Title = "Wave Height",
    Min = 0,
    Max = 12,
    Default = State.SurfWaveHeight,
    Rounding = 1,
    Callback = function(v)
        State.SurfWaveHeight = v
    end,
})

SurfWave:AddSlider("SurfWaveSpeed", {
    Title = "Wave Speed",
    Min = -15,
    Max = 15,
    Default = State.SurfWaveSpeed,
    Rounding = 1,
    Callback = function(v)
        State.SurfWaveSpeed = v
    end,
})

SurfWave:AddSlider("SurfWaveFrequency", {
    Title = "Wave Frequency",
    Min = 0.05,
    Max = 2,
    Default = State.SurfWaveFrequency,
    Rounding = 2,
    Callback = function(v)
        State.SurfWaveFrequency = v
    end,
})

SurfWave:AddSlider("SurfSideWave", {
    Title = "Side Wave",
    Min = 0,
    Max = 5,
    Default = State.SurfSideWave,
    Rounding = 1,
    Callback = function(v)
        State.SurfSideWave = v
    end,
})

local SurfBehavior =
    Tabs.Surf:AddSection(
        "Behavior",
        "lucide/settings-2"
    )

SurfBehavior:AddToggle(
    "SurfFollowRotation",
    {
        Title = "Follow Player Direction",
        Default = State.SurfFollowRotation,
        Callback = function(v)
            State.SurfFollowRotation = v
        end,
    }
)

SurfBehavior:AddToggle(
    "SurfTilt",
    {
        Title = "Tilt Along Wave",
        Default = State.SurfTilt,
        Callback = function(v)
            State.SurfTilt = v
        end,
    }
)

SurfBehavior:AddToggle(
    "SurfCollisions",
    {
        Title = "Surfable Collision",
        Default = State.SurfCollisions,

        Callback = function(v)
            State.SurfCollisions = v
            updateAllCollisions()
        end,
    }
)

local TornadoShape =
    Tabs.Tornado:AddSection(
        "Tornado Shape",
        "lucide/wind"
    )

TornadoShape:AddSlider(
    "TornadoHeight",
    {
        Title = "Tornado Height",
        Min = 5,
        Max = 150,
        Default = State.TornadoHeight,
        Rounding = 0,

        Callback = function(v)
            State.TornadoHeight = v
        end,
    }
)

TornadoShape:AddSlider(
    "TornadoRadius",
    {
        Title = "Top Radius",
        Min = 2,
        Max = 75,
        Default = State.TornadoRadius,
        Rounding = 1,

        Callback = function(v)
            State.TornadoRadius = v
        end,
    }
)

TornadoShape:AddSlider(
    "TornadoBaseRadius",
    {
        Title = "Base Radius",
        Min = 0,
        Max = 30,
        Default = State.TornadoBaseRadius,
        Rounding = 1,

        Callback = function(v)
            State.TornadoBaseRadius = v
        end,
    }
)

local TornadoMovement =
    Tabs.Tornado:AddSection(
        "Tornado Movement",
        "lucide/refresh-cw"
    )

TornadoMovement:AddSlider(
    "TornadoSpeed",
    {
        Title = "Rotation Speed",
        Min = -15,
        Max = 15,
        Default = State.TornadoSpeed,
        Rounding = 1,

        Callback = function(v)
            State.TornadoSpeed = v
        end,
    }
)

TornadoMovement:AddSlider(
    "TornadoVerticalWave",
    {
        Title = "Vertical Turbulence",
        Min = 0,
        Max = 15,
        Default = State.TornadoVerticalWave,
        Rounding = 1,

        Callback = function(v)
            State.TornadoVerticalWave = v
        end,
    }
)

TornadoMovement:AddSlider(
    "TornadoVerticalWaveSpeed",
    {
        Title = "Turbulence Speed",
        Min = 0,
        Max = 15,
        Default = State.TornadoVerticalWaveSpeed,
        Rounding = 1,

        Callback = function(v)
            State.TornadoVerticalWaveSpeed = v
        end,
    }
)

TornadoMovement:AddToggle(
    "TornadoSpinParts",
    {
        Title = "Spin Individual Parts",
        Default = State.TornadoSpinParts,

        Callback = function(v)
            State.TornadoSpinParts = v
        end,
    }
)

TornadoMovement:AddSlider(
    "TornadoPartSpinSpeed",
    {
        Title = "Part Spin Speed",
        Min = 0,
        Max = 20,
        Default = State.TornadoPartSpinSpeed,
        Rounding = 1,

        Callback = function(v)
            State.TornadoPartSpinSpeed = v
        end,
    }
)

local TargetSection =
    Tabs.Target:AddSection(
        "Target",
        "lucide/user-round-search"
    )

TargetSection:AddInput(
    "TargetPlayer",
    {
        Title = "Player",
        Placeholder = "Username or display name",
        Default = LocalPlayer.Name,

        Callback = function(value)
            local player =
                findPlayer(value)

            if player then
                State.TargetPlayer =
                    player

                Fluent:Notify({
                    Title = "Target Changed",

                    Content =
                        player.DisplayName
                        .. " (@"
                        .. player.Name
                        .. ")",

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
    }
)

TargetSection:AddButton({
    Title = "Target Yourself",

    Callback = function()
        State.TargetPlayer =
            LocalPlayer
    end,
})

local OffsetSection =
    Tabs.Target:AddCollapsibleSection(
        "Position Offset",
        "lucide/move-3d",
        false
    )

local offsetX = 0
local offsetY = 0
local offsetZ = 0

local function updateOffset()
    State.Offset =
        Vector3.new(
            offsetX,
            offsetY,
            offsetZ
        )
end

OffsetSection:AddSlider("OffsetX", {
    Title = "X",
    Min = -50,
    Max = 50,
    Default = 0,
    Rounding = 1,

    Callback = function(v)
        offsetX = v
        updateOffset()
    end,
})

OffsetSection:AddSlider("OffsetY", {
    Title = "Y",
    Min = -50,
    Max = 50,
    Default = 0,
    Rounding = 1,

    Callback = function(v)
        offsetY = v
        updateOffset()
    end,
})

OffsetSection:AddSlider("OffsetZ", {
    Title = "Z",
    Min = -50,
    Max = 50,
    Default = 0,
    Rounding = 1,

    Callback = function(v)
        offsetZ = v
        updateOffset()
    end,
})

local FilterSection =
    Tabs.Filters:AddSection(
        "Scanner",
        "lucide/radar"
    )

FilterSection:AddSlider(
    "ScanRadius",
    {
        Title = "Scan Radius",

        Min = 25,
        Max = 100000,

        Default =
            State.ScanRadius,

        Rounding = 0,

        Callback = function(v)
            State.ScanRadius = v
        end,
    }
)

FilterSection:AddSlider(
    "MaxSize",
    {
        Title = "Maximum Part Size",

        Min = 1,
        Max = 1000,

        Default =
            State.MaxSize,

        Rounding = 0,

        Callback = function(v)
            State.MaxSize = v
        end,
    }
)

FilterSection:AddToggle(
    "IgnoreCharacters",
    {
        Title = "Ignore Characters",
        Default = true,

        Callback = function(v)
            State.IgnoreCharacters = v
        end,
    }
)

FilterSection:AddToggle(
    "IgnoreTools",
    {
        Title = "Ignore Tools",
        Default = true,

        Callback = function(v)
            State.IgnoreTools = v
        end,
    }
)

FilterSection:AddToggle(
    "IgnoreAccessories",
    {
        Title = "Ignore Accessories",
        Default = true,

        Callback = function(v)
            State.IgnoreAccessories = v
        end,
    }
)

FilterSection:AddToggle(
    "IgnoreHandles",
    {
        Title = "Ignore Handles",
        Default = true,

        Callback = function(v)
            State.IgnoreHandles = v
        end,
    }
)

local GeneralSettings =
    Tabs.Settings:AddSection(
        "General",
        "lucide/settings"
    )

GeneralSettings:AddParagraph({
    Title = "Part Limit",
    Content =
        "No part-count limit is enabled. Every valid loose part found by the scanner can be controlled.",
})

GeneralSettings:AddKeybind(
    "UIToggleKey",
    {
        Title = "UI Toggle",

        Description =
            "Press this key to hide or show the UI.",

        Default = "K",
        Mode = "Always",

        Callback = function()
            State.UIVisible =
                not State.UIVisible

            if State.UIVisible then
                Window:Show()
            else
                Window:Hide()
            end
        end,
    }
)

local PhysicsSection =
    Tabs.Settings:AddSection(
        "Physics",
        "lucide/gauge"
    )

PhysicsSection:AddToggle(
    "DisableCollision",
    {
        Title = "Disable Collision",
        Default = State.DisableCollision,

        Callback = function(v)
            State.DisableCollision = v
            updateAllCollisions()
        end,
    }
)

PhysicsSection:AddSlider(
    "Responsiveness",
    {
        Title = "Responsiveness",

        Min = 10,
        Max = 200,

        Default =
            State.Responsiveness,

        Rounding = 0,

        Callback = function(value)
            State.Responsiveness =
                value

            for _, data in pairs(
                PartData
            ) do
                data.AlignPosition.Responsiveness =
                    value

                data.AlignOrientation.Responsiveness =
                    value
            end
        end,
    }
)

PhysicsSection:AddSlider(
    "PullSpeed",
    {
        Title = "Pull Speed",
        Min = 1,
        Max = 200,
        Default = State.PullSpeed,
        Rounding = 0,

        Callback = function(v)
            State.PullSpeed = v
        end,
    }
)

PhysicsSection:AddSlider(
    "SphereRadius",
    {
        Title = "Sphere Radius",
        Min = 2,
        Max = 100,
        Default = State.SphereRadius,
        Rounding = 0,

        Callback = function(v)
            State.SphereRadius = v
        end,
    }
)

PhysicsSection:AddSlider(
    "SphereSpeed",
    {
        Title = "Sphere Speed",
        Min = -15,
        Max = 15,
        Default = State.SphereSpeed,
        Rounding = 1,

        Callback = function(v)
            State.SphereSpeed = v
        end,
    }
)

PhysicsSection:AddSlider(
    "LineSpacing",
    {
        Title = "Line Spacing",
        Min = 1,
        Max = 20,
        Default = State.LineSpacing,
        Rounding = 1,

        Callback = function(v)
            State.LineSpacing = v
        end,
    }
)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Bring Parts",
    Content = "Loaded successfully.",
    SubContent =
        "No part-count limit. Press K to hide or show the UI.",
    Type = "Success",
    Duration = 4,
})
