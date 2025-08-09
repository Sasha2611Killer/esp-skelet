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
    Teamcheck = false,
    WallCheck = false,
    Enabled = false,
    ShowBox = false,
    BoxType = "2D",
    ShowName = false,
    ShowHealth = false,
    ShowDistance = false,
    ShowSkeletons = false,
    ShowTracer = false,
    TracerColor = Color3.new(1, 1, 1), 
    TracerThickness = 2,
    SkeletonsColor = Color3.new(1, 1, 1),
    TracerPosition = "Bottom",
    TextOutline = true,
    TextSize = 14,
}

--// Utility Functions
local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local function destroyDrawings(tbl)
    for _, v in pairs(tbl) do
        if typeof(v) == "table" then
            destroyDrawings(v)
        elseif v.Remove then
            v:Remove()
        end
    end
end

--// 3D Box Calculation
local function calculate3DCorners(cframe, size)
    local corners = {}
    local sx, sy, sz = size.X/2, size.Y/2, size.Z/2
    
    corners[1] = cframe * CFrame.new(sx, sy, sz)
    corners[2] = cframe * CFrame.new(-sx, sy, sz)
    corners[3] = cframe * CFrame.new(-sx, -sy, sz)
    corners[4] = cframe * CFrame.new(sx, -sy, sz)
    corners[5] = cframe * CFrame.new(sx, sy, -sz)
    corners[6] = cframe * CFrame.new(-sx, sy, -sz)
    corners[7] = cframe * CFrame.new(-sx, -sy, -sz)
    corners[8] = cframe * CFrame.new(sx, -sy, -sz)
    
    return corners
end

local function isPointBehindCamera(point)
    local cameraPoint = camera.CFrame:PointToObjectSpace(point)
    return cameraPoint.Z > 0
end

local function createEsp(player)
    local esp = {
        boxOutline = create("Square", {
            Color = ESP_SETTINGS.BoxOutlineColor,
            Thickness = 3,
            Filled = false,
            Visible = false
        }),
        box = create("Square", {
            Color = ESP_SETTINGS.BoxColor,
            Thickness = 1,
            Filled = false,
            Visible = false
        }),
        infoText = create("Text", {
            Color = ESP_SETTINGS.NameColor,
            Outline = ESP_SETTINGS.TextOutline,
            Center = true,
            Size = ESP_SETTINGS.TextSize,
            Visible = false
        }),
        healthOutline = create("Line", {
            Thickness = 3,
            Color = ESP_SETTINGS.HealthOutlineColor,
            Visible = false
        }),
        health = create("Line", {
            Thickness = 1,
            Visible = false
        }),
        tracer = create("Line", {
            Thickness = ESP_SETTINGS.TracerThickness,
            Color = ESP_SETTINGS.TracerColor,
            Transparency = 1,
            Visible = false
        }),
        boxLines = {},
        skeletonLines = {}
    }
    
    cache[player] = esp
end

local function isPlayerBehindWall(player)
    if not ESP_SETTINGS.WallCheck then return false end
    
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local origin = camera.CFrame.Position
    local direction = (rootPart.Position - origin).Unit * (rootPart.Position - origin).Magnitude
    local ray = Ray.new(origin, direction)
    
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})
    return hit and hit:IsA("BasePart")
end

local function removeEsp(player)
    local esp = cache[player]
    if not esp then return end
    
    destroyDrawings(esp)
    cache[player] = nil
end

local function updateEsp()
    for player, esp in pairs(cache) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        -- Check if ESP should be visible
        local shouldShow = ESP_SETTINGS.Enabled and character and humanoid and humanoid.Health > 0 and rootPart
        local teamCheckPassed = not ESP_SETTINGS.Teamcheck or (player.Team ~= localPlayer.Team)
        local wallCheckPassed = not isPlayerBehindWall(player)
        
        shouldShow = shouldShow and teamCheckPassed and wallCheckPassed
        
        if shouldShow then
            local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                -- Calculate character dimensions
                local charSize = (camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0)).Y - 
                                camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.6, 0)).Y) / 2
                local boxSize = Vector2.new(math.floor(charSize * 1.8), math.floor(charSize * 1.9))
                local boxPosition = Vector2.new(math.floor(position.X - charSize * 1.8 / 2), math.floor(position.Y - charSize * 1.6 / 2))
                
                -- Combined name and distance text
                if ESP_SETTINGS.ShowName or ESP_SETTINGS.ShowDistance then
                    local text = ""
                    if ESP_SETTINGS.ShowName then
                        text = string.lower(player.Name)
                    end
                    if ESP_SETTINGS.ShowDistance then
                        local distance = (rootPart.Position - camera.CFrame.Position).Magnitude
                        if text ~= "" then
                            text = text .. " | "
                        end
                        text = text .. string.format("%.1f studs", distance)
                    end
                    
                    esp.infoText.Text = text
                    esp.infoText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y - 20)
                    esp.infoText.Color = ESP_SETTINGS.NameColor
                    esp.infoText.Visible = true
                else
                    esp.infoText.Visible = false
                end
                
                -- Box ESP
                if ESP_SETTINGS.ShowBox then
                    if ESP_SETTINGS.BoxType == "2D" then
                        esp.boxOutline.Size = boxSize
                        esp.boxOutline.Position = boxPosition
                        esp.boxOutline.Visible = true
                        
                        esp.box.Size = boxSize
                        esp.box.Position = boxPosition
                        esp.box.Color = ESP_SETTINGS.BoxColor
                        esp.box.Visible = true
                        
                        -- Clean up 3D box lines if they exist
                        for _, line in ipairs(esp.boxLines) do
                            line:Remove()
                        end
                        esp.boxLines = {}
                    elseif ESP_SETTINGS.BoxType == "3D" then
                        -- Hide 2D boxes
                        esp.boxOutline.Visible = false
                        esp.box.Visible = false
                        
                        -- Create 3D box lines if they don't exist
                        if #esp.boxLines == 0 then
                            for i = 1, 12 do -- 12 edges in a 3D box
                                esp.boxLines[i] = create("Line", {
                                    Thickness = 1,
                                    Color = ESP_SETTINGS.BoxColor,
                                    Transparency = 1
                                })
                            end
                        end
                        
                        -- Calculate 3D box corners
                        local rootCFrame = rootPart.CFrame
                        local boxSize3D = Vector3.new(4, 6, 4) -- Adjust these values as needed
                        local corners = calculate3DCorners(rootCFrame, boxSize3D)
                        
                        -- Define edges (pairs of corner indices)
                        local edges = {
                            {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- Front face
                            {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- Back face
                            {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- Connecting edges
                        }
                        
                        -- Update 3D box lines
                        for i, edge in ipairs(edges) do
                            local fromCorner = corners[edge[1]]
                            local toCorner = corners[edge[2]]
                            
                            if not isPointBehindCamera(fromCorner.Position) and not isPointBehindCamera(toCorner.Position) then
                                local fromPos = camera:WorldToViewportPoint(fromCorner.Position)
                                local toPos = camera:WorldToViewportPoint(toCorner.Position)
                                
                                esp.boxLines[i].From = Vector2.new(fromPos.X, fromPos.Y)
                                esp.boxLines[i].To = Vector2.new(toPos.X, toPos.Y)
                                esp.boxLines[i].Color = ESP_SETTINGS.BoxColor
                                esp.boxLines[i].Visible = true
                            else
                                esp.boxLines[i].Visible = false
                            end
                        end
                    end
                else
                    esp.boxOutline.Visible = false
                    esp.box.Visible = false
                    
                    -- Clean up 3D box lines
                    for _, line in ipairs(esp.boxLines) do
                        line:Remove()
                    end
                    esp.boxLines = {}
                end
                
                -- Health bar
                if ESP_SETTINGS.ShowHealth and humanoid then
                    local healthPercentage = humanoid.Health / humanoid.MaxHealth
                    
                    esp.healthOutline.From = Vector2.new(boxPosition.X - 6, boxPosition.Y + boxSize.Y)
                    esp.healthOutline.To = Vector2.new(esp.healthOutline.From.X, esp.healthOutline.From.Y - boxSize.Y)
                    esp.healthOutline.Visible = true
                    
                    esp.health.From = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y)
                    esp.health.To = Vector2.new(esp.health.From.X, esp.health.From.Y - healthPercentage * boxSize.Y)
                    esp.health.Color = ESP_SETTINGS.HealthLowColor:Lerp(ESP_SETTINGS.HealthHighColor, healthPercentage)
                    esp.health.Visible = true
                else
                    esp.healthOutline.Visible = false
                    esp.health.Visible = false
                end
                
                -- Skeleton ESP
                if ESP_SETTINGS.ShowSkeletons then
                    -- Create skeleton lines if they don't exist
                    if #esp.skeletonLines == 0 then
                        for _, bonePair in ipairs(bones) do
                            local line = create("Line", {
                                Thickness = 1,
                                Color = ESP_SETTINGS.SkeletonsColor,
                                Transparency = 1
                            })
                            table.insert(esp.skeletonLines, {
                                line = line,
                                parentBone = bonePair[1],
                                childBone = bonePair[2]
                            })
                        end
                    end
                    
                    -- Update skeleton lines
                    for _, boneData in ipairs(esp.skeletonLines) do
                        local parentPart = character:FindFirstChild(boneData.parentBone)
                        local childPart = character:FindFirstChild(boneData.childBone)
                        
                        if parentPart and childPart then
                            local parentPos = camera:WorldToViewportPoint(parentPart.Position)
                            local childPos = camera:WorldToViewportPoint(childPart.Position)
                            
                            if parentPos.Z > 0 and childPos.Z > 0 then
                                boneData.line.From = Vector2.new(parentPos.X, parentPos.Y)
                                boneData.line.To = Vector2.new(childPos.X, childPos.Y)
                                boneData.line.Color = ESP_SETTINGS.SkeletonsColor
                                boneData.line.Visible = true
                            else
                                boneData.line.Visible = false
                            end
                        else
                            boneData.line.Visible = false
                        end
                    end
                else
                    -- Clean up skeleton lines
                    for _, boneData in ipairs(esp.skeletonLines) do
                        boneData.line:Remove()
                    end
                    esp.skeletonLines = {}
                end
                
                -- Tracer
                if ESP_SETTINGS.ShowTracer then
                    local tracerY
                    if ESP_SETTINGS.TracerPosition == "Top" then
                        tracerY = 0
                    elseif ESP_SETTINGS.TracerPosition == "Middle" then
                        tracerY = camera.ViewportSize.Y / 2
                    else
                        tracerY = camera.ViewportSize.Y
                    end
                    
                    esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, tracerY)
                    esp.tracer.To = Vector2.new(position.X, position.Y)
                    esp.tracer.Color = ESP_SETTINGS.TracerColor
                    esp.tracer.Visible = true
                else
                    esp.tracer.Visible = false
                end
            else
                -- Off screen - hide all drawings
                for _, drawing in pairs(esp) do
                    if drawing.Visible ~= nil then
                        drawing.Visible = false
                    end
                end
                
                -- Clean up temporary drawings
                for _, line in ipairs(esp.boxLines) do
                    line:Remove()
                end
                esp.boxLines = {}
                
                for _, boneData in ipairs(esp.skeletonLines) do
                    boneData.line:Remove()
                end
                esp.skeletonLines = {}
            end
        else
            -- ESP shouldn't be shown - hide all drawings
            for _, drawing in pairs(esp) do
                if drawing.Visible ~= nil then
                    drawing.Visible = false
                end
            end
            
            -- Clean up temporary drawings
            for _, line in ipairs(esp.boxLines) do
                line:Remove()
            end
            esp.boxLines = {}
            
            for _, boneData in ipairs(esp.skeletonLines) do
                boneData.line:Remove()
            end
            esp.skeletonLines = {}
        end
    end
end

--// Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createEsp(player)
    end
end

--// Player connection handlers
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        createEsp(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end)

--// Main loop
RunService.RenderStepped:Connect(updateEsp)

return ESP_SETTINGS
