-- esp.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}

-- Упрощенный список костей для скелета
local bones = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

-- Настройки ESP
local ESP_SETTINGS = {
	BoxColor = Color3.new(1, 1, 1),
	NameColor = Color3.new(1, 1, 1),
	HealthHighColor = Color3.new(0, 1, 0),
	HealthLowColor = Color3.new(1, 0, 0),
	Teamcheck = false,
	WallCheck = false,
	Enabled = false,
	ShowBox = false,
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

-- Функция для создания Drawing объектов
local function create(class, properties)
	local drawing = Drawing.new(class)
	for property, value in pairs(properties) do
		drawing[property] = value
	end
	return drawing
end

-- Создание ESP для игрока
local function createEsp(player)
	local esp = {
		name = create("Text", {
			Color = ESP_SETTINGS.NameColor,
			Outline = true,
			Center = true,
			Size = 13,
			Visible = false
		}),
		health = create("Line", {
			Thickness = 1,
			Visible = false
		}),
		distance = create("Text", {
			Color = Color3.new(1, 1, 1),
			Size = 12,
			Outline = true,
			Center = true,
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

	-- Создаем 12 линий для 3D бокса
	for i = 1, 12 do
		esp.boxLines[i] = create("Line", {
			Thickness = 1,
			Color = ESP_SETTINGS.BoxColor,
			Transparency = 1,
			Visible = false
		})
	end

	cache[player] = esp
end

-- Проверка, находится ли игрок за стеной
local function isPlayerBehindWall(player)
	if not ESP_SETTINGS.WallCheck then return false end

	local character = player.Character
	if not character then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	local ray = Ray.new(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position).Unit * (rootPart.Position - camera.CFrame.Position).Magnitude)
	local hit = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})

	return hit and hit:IsA("Part")
end

-- Удаление ESP для игрока
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

-- Обновление 3D бокса
local function update3DBox(esp, character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Получаем реальные размеры персонажа
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	-- Базовые размеры (можно настроить под вашу игру)
	local width = 2.2  -- Ширина (X)
	local height = humanoid.HipHeight * 2  -- Высота (Y)
	local depth = 2.0  -- Глубина (Z)

	-- Корректируем размеры для разных типов персонажей
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		height = 5.0
	elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
		height = 5.5
	end

	local size = Vector3.new(width, height, depth)

	local corners = {
		Vector3.new(-size.X, -size.Y, -size.Z), -- 1: Нижний-задний-левый
		Vector3.new(size.X, -size.Y, -size.Z),  -- 2: Нижний-задний-правый
		Vector3.new(size.X, -size.Y, size.Z),   -- 3: Нижний-передний-правый
		Vector3.new(-size.X, -size.Y, size.Z),  -- 4: Нижний-передний-левый
		Vector3.new(-size.X, size.Y, -size.Z),  -- 5: Верхний-задний-левый
		Vector3.new(size.X, size.Y, -size.Z),   -- 6: Верхний-задний-правый
		Vector3.new(size.X, size.Y, size.Z),    -- 7: Верхний-передний-правый
		Vector3.new(-size.X, size.Y, size.Z)   -- 8: Верхний-передний-левый
	}

	local cf = rootPart.CFrame
	local screenCorners = {}
	local allVisible = true

	-- Преобразуем углы в экранные координаты
	for i, corner in ipairs(corners) do
		local worldPos = (cf * CFrame.new(corner)).Position
		local screenPos, visible = camera:WorldToViewportPoint(worldPos)
		if not visible then allVisible = false end
		screenCorners[i] = Vector2.new(screenPos.X, screenPos.Y)
	end

	if not allVisible then return false end

	-- Нижняя плоскость
	esp.boxLines[1].From = screenCorners[1]; esp.boxLines[1].To = screenCorners[2]
	esp.boxLines[2].From = screenCorners[2]; esp.boxLines[2].To = screenCorners[3]
	esp.boxLines[3].From = screenCorners[3]; esp.boxLines[3].To = screenCorners[4]
	esp.boxLines[4].From = screenCorners[4]; esp.boxLines[4].To = screenCorners[1]

	-- Верхняя плоскость
	esp.boxLines[5].From = screenCorners[5]; esp.boxLines[5].To = screenCorners[6]
	esp.boxLines[6].From = screenCorners[6]; esp.boxLines[6].To = screenCorners[7]
	esp.boxLines[7].From = screenCorners[7]; esp.boxLines[7].To = screenCorners[8]
	esp.boxLines[8].From = screenCorners[8]; esp.boxLines[8].To = screenCorners[5]

	-- Вертикальные линии
	esp.boxLines[9].From = screenCorners[1]; esp.boxLines[9].To = screenCorners[5]
	esp.boxLines[10].From = screenCorners[2]; esp.boxLines[10].To = screenCorners[6]
	esp.boxLines[11].From = screenCorners[3]; esp.boxLines[11].To = screenCorners[7]
	esp.boxLines[12].From = screenCorners[4]; esp.boxLines[12].To = screenCorners[8]

	for i = 1, 12 do
		esp.boxLines[i].Visible = true
		esp.boxLines[i].Color = ESP_SETTINGS.BoxColor
	end

	return true
end

-- Обновление скелета
local function updateSkeleton(esp, character)
	-- Удаляем старые линии скелета
	for _, line in ipairs(esp.skeletonLines) do
		line:Remove()
	end
	esp.skeletonLines = {}

	-- Создаем новые линии скелета
	for _, bonePair in ipairs(bones) do
		local parentBone, childBone = bonePair[1], bonePair[2]

		local parentPart = character:FindFirstChild(parentBone)
		local childPart = character:FindFirstChild(childBone)

		if parentPart and childPart then
			local parentPos, parentVisible = camera:WorldToViewportPoint(parentPart.Position)
			local childPos, childVisible = camera:WorldToViewportPoint(childPart.Position)

			if parentVisible and childVisible then
				local skeletonLine = create("Line", {
					Thickness = 1,
					Color = ESP_SETTINGS.SkeletonsColor,
					Transparency = 1
				})
				skeletonLine.From = Vector2.new(parentPos.X, parentPos.Y)
				skeletonLine.To = Vector2.new(childPos.X, childPos.Y)
				skeletonLine.Visible = true

				table.insert(esp.skeletonLines, skeletonLine)
			end
		end
	end
end

-- Основная функция обновления ESP
local function updateEsp()
	for player, esp in pairs(cache) do
		-- Проверяем, нужно ли показывать ESP для этого игрока
		local character = player.Character
		local shouldShow = character and 
			(not ESP_SETTINGS.Teamcheck or player.Team ~= localPlayer.Team) and
			(not isPlayerBehindWall(player)) and
			ESP_SETTINGS.Enabled

		if shouldShow then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChild("Humanoid")

			if rootPart and humanoid then
				local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)

				if onScreen then
					-- Обновляем позицию и размеры
					local hrp2D = Vector2.new(position.X, position.Y)
					local boxSize = Vector2.new(50, 80) -- Фиксированный размер для упрощения
					local boxPosition = Vector2.new(hrp2D.X - boxSize.X / 2, hrp2D.Y - boxSize.Y / 2)

					-- Имя игрока
					if ESP_SETTINGS.ShowName then
						esp.name.Text = player.Name
						esp.name.Position = Vector2.new(hrp2D.X, boxPosition.Y - 20)
						esp.name.Visible = true
					else
						esp.name.Visible = false
					end

					-- 3D Бокс
					if ESP_SETTINGS.ShowBox then
						local boxVisible = update3DBox(esp, character)
						if not boxVisible then
							for i = 1, 12 do
								esp.boxLines[i].Visible = false
							end
						end
					else
						for i = 1, 12 do
							esp.boxLines[i].Visible = false
						end
					end

					-- Здоровье
					if ESP_SETTINGS.ShowHealth and humanoid then
						local healthPercentage = humanoid.Health / humanoid.MaxHealth
						local healthColor = ESP_SETTINGS.HealthLowColor:Lerp(ESP_SETTINGS.HealthHighColor, healthPercentage)

						esp.health.From = Vector2.new(boxPosition.X - 8, boxPosition.Y + boxSize.Y)
						esp.health.To = Vector2.new(esp.health.From.X, esp.health.From.Y - boxSize.Y * healthPercentage)
						esp.health.Color = healthColor
						esp.health.Visible = true
					else
						esp.health.Visible = false
					end

					-- Дистанция
					if ESP_SETTINGS.ShowDistance then
						local distance = (camera.CFrame.p - rootPart.Position).Magnitude
						esp.distance.Text = string.format("%.1f studs", distance)
						esp.distance.Position = Vector2.new(hrp2D.X, boxPosition.Y + boxSize.Y + 5)
						esp.distance.Visible = true
					else
						esp.distance.Visible = false
					end

					-- Скелет
					if ESP_SETTINGS.ShowSkeletons then
						updateSkeleton(esp, character)
					else
						for _, line in ipairs(esp.skeletonLines) do
							line:Remove()
						end
						esp.skeletonLines = {}
					end

					-- Трассер
					if ESP_SETTINGS.ShowTracer then
						local tracerY = ESP_SETTINGS.TracerPosition == "Top" and 0 or
							ESP_SETTINGS.TracerPosition == "Middle" and camera.ViewportSize.Y / 2 or
							camera.ViewportSize.Y

						esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, tracerY)
						esp.tracer.To = hrp2D
						esp.tracer.Visible = true
					else
						esp.tracer.Visible = false
					end
				else
					-- Игрок не на экране - скрываем все
					for _, drawing in pairs(esp) do
						if typeof(drawing) == "table" then
							for _, line in ipairs(drawing) do
								line.Visible = false
							end
						else
							drawing.Visible = false
						end
					end
				end
			else
				-- Нет rootPart или humanoid - скрываем все
				for _, drawing in pairs(esp) do
					if typeof(drawing) == "table" then
						for _, line in ipairs(drawing) do
							line.Visible = false
						end
					else
						drawing.Visible = false
					end
				end
			end
		else
			-- Не нужно показывать ESP - скрываем все
			for _, drawing in pairs(esp) do
				if typeof(drawing) == "table" then
					for _, line in ipairs(drawing) do
						line.Visible = false
					end
				else
					drawing.Visible = false
				end
			end
		end
	end
end

-- Инициализация ESP для существующих игроков
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		createEsp(player)
	end
end

-- Обработчики новых и уходящих игроков
Players.PlayerAdded:Connect(function(player)
	if player ~= localPlayer then
		createEsp(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removeEsp(player)
end)

-- Основной цикл обновления
RunService.RenderStepped:Connect(updateEsp)

return ESP_SETTINGS
