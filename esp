-- esp.lua
--// Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}

local bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

--// Settings
local ESP_SETTINGS = {
    BoxOutlineColor = Color3.new(0, 0, 0),
    BoxColor = Color3.new(1, 1, 1),
    NameColor = Color3.new(1, 1, 1),
    HealthOutlineColor = Color3.new(0, 0, 0),
    HealthHighColor = Color3.new(0, 1, 0),
    HealthLowColor = Color3.new(1, 0, 0),
    CharSize = Vector2.new(4, 6),
    Teamcheck = false,
    WallCheck = false,
    Enabled = false,
    ShowBox = false,
    BoxType = "3D", -- Изменено с "2D" на "3D"
    ShowName = false,
    ShowHealth = false,
    ShowDistance = false,
    ShowSkeletons = false,
    ShowTracer = false,
    TracerColor = Color3.new(1, 1, 1), 
    TracerThickness = 2,
    SkeletonsColor = Color3.new(1, 1, 1),
    TracerPosition = "Bottom",
}

local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local function createEsp(player)
    local esp = {
        tracer = create("Line", {
            Thickness = ESP_SETTINGS.TracerThickness,
            Color = ESP_SETTINGS.TracerColor,
            Transparency = 0.5
        }),
        name = create("Text", {
            Color = ESP_SETTINGS.NameColor,
            Outline = true,
            Center = true,
            Size = 13
        }),
        healthOutline = create("Line", {
            Thickness = 3,
            Color = ESP_SETTINGS.HealthOutlineColor
        }),
        health = create("Line", {
            Thickness = 1
        }),
        distance = create("Text", {
            Color = Color3.new(1, 1, 1),
            Size = 12,
            Outline = true,
            Center = true
        }),
        tracer = create("Line", {
            Thickness = ESP_SETTINGS.TracerThickness,
            Color = ESP_SETTINGS.TracerColor,
            Transparency = 1
        }),
        boxLines = {}, -- Для 3D box
    }

    -- Создаем линии для 3D box
    for i = 1, 12 do
        esp.boxLines[i] = create("Line", {
            Thickness = 1,
            Color = ESP_SETTINGS.BoxColor,
            Transparency = 1
        })
    end

    cache[player] = esp
    cache[player]["skeletonlines"] = {}
end

local function isPlayerBehindWall(player)
    local character = player.Character
    if not character then
        return false
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end

    local ray = Ray.new(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position).Unit * (rootPart.Position - camera.CFrame.Position).Magnitude)
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})
    
    return hit and hit:IsA("Part")
end

local function removeEsp(player)
    local esp = cache[player]
    if not esp then return end

    for _, drawing in pairs(esp) do
        if typeof(drawing) == "table" then
            for _, line in ipairs(drawing) do
                line:Remove()
            end
        else
            drawing:Remove()
        end
    end

    cache[player] = nil
end

local function update3DBox(esp, character, boxPosition, boxSize)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local size = Vector3.new(4, 6, 4) -- Размер 3D box
    local corners = {
        Vector3.new(-size.X, -size.Y, -size.Z),
        Vector3.new(size.X, -size.Y, -size.Z),
        Vector3.new(size.X, -size.Y, size.Z),
        Vector3.new(-size.X, -size.Y, size.Z),
        Vector3.new(-size.X, size.Y, -size.Z),
        Vector3.new(size.X, size.Y, -size.Z),
        Vector3.new(size.X, size.Y, size.Z),
        Vector3.new(-size.X, size.Y, size.Z)
    }

    local cf = rootPart.CFrame
    local worldCorners = {}
    for i, corner in ipairs(corners) do
        worldCorners[i] = (cf * CFrame.new(corner)).Position
    end

    local screenCorners = {}
    for i, corner in ipairs(worldCorners) do
        local screenPos, visible = camera:WorldToViewportPoint(corner)
        if not visible then return end
        screenCorners[i] = Vector2.new(screenPos.X, screenPos.Y)
    end

    -- Нижняя плоскость
    esp.boxLines[1].From = screenCorners[1]
    esp.boxLines[1].To = screenCorners[2]
    esp.boxLines[2].From = screenCorners[2]
    esp.boxLines[2].To = screenCorners[3]
    esp.boxLines[3].From = screenCorners[3]
    esp.boxLines[3].To = screenCorners[4]
    esp.boxLines[4].From = screenCorners[4]
    esp.boxLines[4].To = screenCorners[1]

    -- Верхняя плоскость
    esp.boxLines[5].From = screenCorners[5]
    esp.boxLines[5].To = screenCorners[6]
    esp.boxLines[6].From = screenCorners[6]
    esp.boxLines[6].To = screenCorners[7]
    esp.boxLines[7].From = screenCorners[7]
    esp.boxLines[7].To = screenCorners[8]
    esp.boxLines[8].From = screenCorners[8]
    esp.boxLines[8].To = screenCorners[5]

    -- Вертикальные линии
    esp.boxLines[9].From = screenCorners[1]
    esp.boxLines[9].To = screenCorners[5]
    esp.boxLines[10].From = screenCorners[2]
    esp.boxLines[10].To = screenCorners[6]
    esp.boxLines[11].From = screenCorners[3]
    esp.boxLines[11].To = screenCorners[7]
    esp.boxLines[12].From = screenCorners[4]
    esp.boxLines[12].To = screenCorners[8]

    for i = 1, 12 do
        esp.boxLines[i].Visible = true
        esp.boxLines[i].Color = ESP_SETTINGS.BoxColor
    end
end

local function updateEsp()
    for player, esp in pairs(cache) do
        local character, team = player.Character, player.Team
        if character and (not ESP_SETTINGS.Teamcheck or (team and team ~= localPlayer.Team)) then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChild("Humanoid")
            local isBehindWall = ESP_SETTINGS.WallCheck and isPlayerBehindWall(player)
            local shouldShow = not isBehindWall and ESP_SETTINGS.Enabled
            if rootPart and head and humanoid and shouldShow then
                local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local hrp2D = camera:WorldToViewportPoint(rootPart.Position)
                    local charSize = (camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.6, 0)).Y) / 2
                    local boxSize = Vector2.new(math.floor(charSize * 1.8), math.floor(charSize * 1.9))
                    local boxPosition = Vector2.new(math.floor(hrp2D.X - charSize * 1.8 / 2), math.floor(hrp2D.Y - charSize * 1.6 / 2))

                    if ESP_SETTINGS.ShowName and ESP_SETTINGS.Enabled then
                        esp.name.Visible = true
                        esp.name.Text = string.lower(player.Name)
                        esp.name.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y - 16)
                        esp.name.Color = ESP_SETTINGS.NameColor
                    else
                        esp.name.Visible = false
                    end

                    if ESP_SETTINGS.ShowBox and ESP_SETTINGS.Enabled then
                        if ESP_SETTINGS.BoxType == "3D" then
                            update3DBox(esp, character, boxPosition, boxSize)
                        end
                    else
                        for i = 1, 12 do
                            esp.boxLines[i].Visible = false
                        end
                    end

                    if ESP_SETTINGS.ShowHealth and ESP_SETTINGS.Enabled then
                        esp.healthOutline.Visible = true
                        esp.health.Visible = true
                        local healthPercentage = player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth
                        esp.healthOutline.From = Vector2.new(boxPosition.X - 6, boxPosition.Y + boxSize.Y)
                        esp.healthOutline.To = Vector2.new(esp.healthOutline.From.X, esp.healthOutline.From.Y - boxSize.Y)
                        esp.health.From = Vector2.new((boxPosition.X - 5), boxPosition.Y + boxSize.Y)
                        esp.health.To = Vector2.new(esp.health.From.X, esp.health.From.Y - (player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth) * boxSize.Y)
                        esp.health.Color = ESP_SETTINGS.HealthLowColor:Lerp(ESP_SETTINGS.HealthHighColor, healthPercentage)
                    else
                        esp.healthOutline.Visible = false
                        esp.health.Visible = false
                    end

                    if ESP_SETTINGS.ShowDistance and ESP_SETTINGS.Enabled then
                        local distance = (camera.CFrame.p - rootPart.Position).Magnitude
                        esp.distance.Text = string.format("%.1f studs", distance)
                        esp.distance.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 5)
                        esp.distance.Visible = true
                    else
                        esp.distance.Visible = false
                    end

                    if ESP_SETTINGS.ShowSkeletons and ESP_SETTINGS.Enabled then
                        if #esp["skeletonlines"] == 0 then
                            for _, bonePair in ipairs(bones) do
                                local parentBone, childBone = bonePair[1], bonePair[2]
                                
                                if player.Character and player.Character[parentBone] and player.Character[childBone] then
                                    local skeletonLine = create("Line", {
                                        Thickness = 1,
                                        Color = ESP_SETTINGS.SkeletonsColor,
                                        Transparency = 1
                                    })
                                    esp["skeletonlines"][#esp["skeletonlines"] + 1] = {skeletonLine, parentBone, childBone}
                                end
                            end
                        end
                    
                        for _, lineData in ipairs(esp["skeletonlines"]) do
                            local skeletonLine = lineData[1]
                            local parentBone, childBone = lineData[2], lineData[3]
                    
                            if player.Character and player.Character[parentBone] and player.Character[childBone] then
                                local parentPosition = camera:WorldToViewportPoint(player.Character[parentBone].Position)
                                local childPosition = camera:WorldToViewportPoint(player.Character[childBone].Position)
                    
                                skeletonLine.From = Vector2.new(parentPosition.X, parentPosition.Y)
                                skeletonLine.To = Vector2.new(childPosition.X, childPosition.Y)
                                skeletonLine.Color = ESP_SETTINGS.SkeletonsColor
                                skeletonLine.Visible = true
                            else
                                skeletonLine:Remove()
                            end
                        end
                    else
                        for _, lineData in ipairs(esp["skeletonlines"]) do
                            local skeletonLine = lineData[1]
                            skeletonLine:Remove()
                        end
                        esp["skeletonlines"] = {}
                    end                    

                    if ESP_SETTINGS.ShowTracer and ESP_SETTINGS.Enabled then
                        local tracerY
                        if ESP_SETTINGS.TracerPosition == "Top" then
                            tracerY = 0
                        elseif ESP_SETTINGS.TracerPosition == "Middle" then
                            tracerY = camera.ViewportSize.Y / 2
                        else
                            tracerY = camera.ViewportSize.Y
                        end
                        if ESP_SETTINGS.Teamcheck and player.TeamColor == localPlayer.TeamColor then
                            esp.tracer.Visible = false
                        else
                            esp.tracer.Visible = true
                            esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, tracerY)
                            esp.tracer.To = Vector2.new(hrp2D.X, hrp2D.Y)            
                        end
                    else
                        esp.tracer.Visible = false
                    end
                else
                    for _, drawing in pairs(esp) do
                        if typeof(drawing) == "table" then
                            for _, line in ipairs(drawing) do
                                line.Visible = false
                            end
                        else
                            drawing.Visible = false
                        end
                    end
                    for _, lineData in ipairs(esp["skeletonlines"]) do
                        local skeletonLine = lineData[1]
                        skeletonLine:Remove()
                    end
                    esp["skeletonlines"] = {}
                end
            else
                for _, drawing in pairs(esp) do
                    if typeof(drawing) == "table" then
                        for _, line in ipairs(drawing) do
                            line.Visible = false
                        end
                    else
                        drawing.Visible = false
                    end
                end
                for _, lineData in ipairs(esp["skeletonlines"]) do
                    local skeletonLine = lineData[1]
                    skeletonLine:Remove()
                end
                esp["skeletonlines"] = {}
            end
        else
            for _, drawing in pairs(esp) do
                if typeof(drawing) == "table" then
                    for _, line in ipairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            for _, lineData in ipairs(esp["skeletonlines"]) do
                local skeletonLine = lineData[1]
                skeletonLine:Remove()
            end
            esp["skeletonlines"] = {}
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createEsp(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        createEsp(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end)

RunService.RenderStepped:Connect(updateEsp)
return ESP_SETTINGS
