local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAXGEN = workspace:WaitForChild("MAXGEN")
local JOB_POINTS = workspace:WaitForChild("JobPoints")
local VEHICLES = workspace:WaitForChild("Vehicles")

local AUTO_FARM = {}

local WAIT_AT_JOB = 3
local MOVE_TIMEOUT = 15

-- =========================================
-- CHARACTER
-- =========================================
local function getCharacter(player)
	local character = player.Character
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return nil
	end

	return character, humanoid, root
end

-- =========================================
-- MOVE PLAYER
-- =========================================
local function moveTo(player, position)
	local character, humanoid, root = getCharacter(player)
	if not character then return false end

	humanoid:MoveTo(position)

	local start = os.clock()

	while os.clock() - start < MOVE_TIMEOUT do
		if not AUTO_FARM[player] then
			return false
		end

		if not character.Parent then
			return false
		end

		if (root.Position - position).Magnitude <= 6 then
			return true
		end

		task.wait(0.15)
	end

	return false
end

-- =========================================
-- GET JOB POINTS
-- =========================================
local function getJobPoints()
	local points = {}

	for _, obj in ipairs(JOB_POINTS:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(points, obj)
		end
	end

	table.sort(points, function(a, b)
		return a.Name < b.Name
	end)

	return points
end

-- =========================================
-- FIND VEHICLE SEAT
-- =========================================
local function getVehicleSeat(vehicle)
	for _, obj in ipairs(vehicle:GetDescendants()) do
		if obj:IsA("VehicleSeat") then
			return obj
		end
	end

	for _, obj in ipairs(vehicle:GetDescendants()) do
		if obj:IsA("Seat") then
			return obj
		end
	end

	return nil
end

-- =========================================
-- FIND NEAREST VEHICLE
-- =========================================
local function getNearestVehicle(player)
	local character, humanoid, root = getCharacter(player)
	if not character then return nil end

	local nearestVehicle = nil
	local nearestDistance = math.huge

	for _, vehicle in ipairs(VEHICLES:GetChildren()) do
		if vehicle:IsA("Model") then

			local seat = getVehicleSeat(vehicle)

			if seat then
				local distance = (seat.Position - root.Position).Magnitude

				if distance < nearestDistance then
					nearestDistance = distance
					nearestVehicle = vehicle
				end
			end
		end
	end

	return nearestVehicle
end

-- =========================================
-- NAIK KENDARAAN
-- =========================================
local function enterVehicle(player)
	local character, humanoid, root = getCharacter(player)
	if not character then return nil end

	local vehicle = getNearestVehicle(player)

	if not vehicle then
		warn("Kendaraan tidak ditemukan!")
		return nil
	end

	local seat = getVehicleSeat(vehicle)

	if not seat then
		warn("VehicleSeat tidak ditemukan!")
		return nil
	end

	print("Menuju kendaraan...")

	if not moveTo(player, seat.Position) then
		return nil
	end

	task.wait(0.5)

	-- Duduk otomatis
	seat:Sit(humanoid)

	task.wait(1)

	if humanoid.SeatPart == seat then
		print("Berhasil naik kendaraan:", vehicle.Name)
		return vehicle
	end

	warn("Gagal naik kendaraan")
	return nil
end

-- =========================================
-- KELUAR KENDARAAN
-- =========================================
local function exitVehicle(player)
	local character, humanoid = getCharacter(player)
	if not humanoid then return end

	humanoid.Sit = false

	task.wait(1)
end

-- =========================================
-- GERAK KENDARAAN KE POINT
-- =========================================
local function driveTo(player, vehicle, position)
	local character, humanoid, root = getCharacter(player)

	if not character then
		return false
	end

	local seat = getVehicleSeat(vehicle)

	if not seat then
		return false
	end

	if humanoid.SeatPart ~= seat then
		return false
	end

	print("Kendaraan menuju:", position)

	local start = os.clock()

	while os.clock() - start < MOVE_TIMEOUT do

		if not AUTO_FARM[player] then
			return false
		end

		if not vehicle.Parent then
			return false
		end

		local vehicleRoot = vehicle.PrimaryPart or seat

		local distance =
			(vehicleRoot.Position - position).Magnitude

		if distance <= 10 then
			return true
		end

		-- Arah kendaraan ke target
		local direction =
			(position - vehicleRoot.Position).Unit

		seat.Throttle = 1

		local currentCFrame = vehicleRoot.CFrame

		local targetCFrame =
			CFrame.lookAt(
				vehicleRoot.Position,
				vehicleRoot.Position + direction
			)

		vehicleRoot.CFrame =
			currentCFrame:Lerp(targetCFrame, 0.08)

		task.wait(0.1)
	end

	seat.Throttle = 0

	return false
end

-- =========================================
-- AUTO JOB
-- =========================================
local function startAutoJob(player)

	if AUTO_FARM[player] then
		return
	end

	AUTO_FARM[player] = true

	task.spawn(function()

		while AUTO_FARM[player] do

			-- =================================
			-- 1. KE MAXGEN
			-- =================================
			local maxgenPosition

			if MAXGEN:IsA("BasePart") then
				maxgenPosition = MAXGEN.Position
			else
				maxgenPosition = MAXGEN:GetPivot().Position
			end

			print("Menuju MAXGEN...")

			if not moveTo(player, maxgenPosition) then
				break
			end

			task.wait(1)

			if not AUTO_FARM[player] then
				break
			end

			-- =================================
			-- 2. AMBIL JOB
			-- =================================
			print("Mengambil job genset...")

			task.wait(1)

			-- =================================
			-- 3. NAIK KENDARAAN
			-- =================================
			local vehicle = enterVehicle(player)

			if not vehicle then
				warn("Tidak bisa naik kendaraan")
				break
			end

			-- =================================
			-- 4. CARI TITIK KUNING
			-- =================================
			local points = getJobPoints()

			if #points == 0 then
				warn("Tidak ada JobPoints!")
				break
			end

			-- =================================
			-- 5. IKUTI TITIK KUNING
			-- =================================
			for _, point in ipairs(points) do

				if not AUTO_FARM[player] then
					break
				end

				print("Menuju:", point.Name)

				local success =
					driveTo(
						player,
						vehicle,
						point.Position
					)

				if not success then
					break
				end

				-- =================================
				-- 6. TUNGGU DI TUJUAN
				-- =================================
				print("Menunggu pengantaran...")

				local vehicleSeat =
					getVehicleSeat(vehicle)

				if vehicleSeat then
					vehicleSeat.Throttle = 0
				end

				task.wait(WAIT_AT_JOB)
			end

			if not AUTO_FARM[player] then
				break
			end

			-- =================================
			-- 7. TURUN KENDARAAN
			-- =================================
			exitVehicle(player)

			task.wait(1)

			-- =================================
			-- 8. JOB SELESAI
			-- =================================
			print("Job selesai, kembali ke MAXGEN")

			task.wait(1)
		end

		AUTO_FARM[player] = nil
	end)
end

-- =========================================
-- STOP AUTO JOB
-- =========================================
local function stopAutoJob(player)
	AUTO_FARM[player] = nil
end

-- =========================================
-- REMOTE ON / OFF
-- =========================================
local remote = ReplicatedStorage:FindFirstChild("AutoJobRemote")

if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AutoJobRemote"
	remote.Parent = ReplicatedStorage
end

remote.OnServerEvent:Connect(function(player, enabled)

	if enabled then
		startAutoJob(player)
	else
		stopAutoJob(player)
	end

end)

Players.PlayerRemoving:Connect(function(player)
	AUTO_FARM[player] = nil
end)
