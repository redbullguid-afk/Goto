-- ==========================================================
-- Blox Fruits Halloween Special - Săn Pumpkin Snowman + Debug Console
-- Tính năng: In tên & tọa độ ra Console Delta, Server Hop 5s, Auto Re-execute
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

getgenv().AutoSpecialPumpkin = true
getgenv().TweenSpeed = 300

local noTargetTime = 0
local lastLoggedTarget = nil -- Biến tránh spam log trùng lặp liên tục

print("[Halloween Special] Đã kích hoạt Script Săn Pumpkin Snowman + Debug Console!")

-- 1. QUEUE ON TELEPORT (Tự động kích hoạt lại khi đổi server)
local queueOnTeleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport or qut
if queueOnTeleport then
    pcall(function()
        queueOnTeleport([[
            task.wait(3)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/redbullguid-afk/Goto/main/Moteblox.lua"))()
        ]])
    end)
end

-- 2. Tự động chọn phe Hải Tặc khi vào game
local function autoSelectPirates()
    pcall(function()
        local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer("SetTeam", "Pirates")
        end
    end)
end
autoSelectPirates()

-- 3. Hàm Server Hop
local function serverHop()
    print("[Server Hop] Không tìm thấy Pumpkin Snowman trong 5s. Đang đổi server...")
    pcall(function()
        local placeId = game.PlaceId
        local servers = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/0?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(req)
        
        if data and data.data then
            for _, v in pairs(data.data) do
                if v.playing ~= v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
        end
        
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
        else
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

-- 4. Hệ thống Noclip & Lơ Lửng (Anti-Fall)
RunService.Stepped:Connect(function()
    if getgenv().AutoSpecialPumpkin and LocalPlayer.Character then
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")

            if char and hrp then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

                if not hrp:FindFirstChild("SpecialHoverForce") then
                    local hover = Instance.new("BodyVelocity")
                    hover.Name = "SpecialHoverForce"
                    hover.Velocity = Vector3.new(0, 0, 0)
                    hover.MaxForce = Vector3.new(0, math.huge, 0)
                    hover.Parent = hrp
                end

                if humanoid then
                    humanoid.PlatformStand = true
                end
            end
        end)
    end
end)

-- 5. Tự động trang bị vũ khí Melee / Sword
local function autoScanAndEquipWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then return currentTool end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local toolType = tool.ToolTip
                if toolType == "Melee" or toolType == "Sword" or tool:FindFirstChild("Combat") or tool:FindFirstChild("Weapon") then
                    char.Humanoid:EquipTool(tool)
                    return tool
                end
            end
        end
        local firstTool = backpack:FindFirstChildOfClass("Tool")
        if firstTool then
            char.Humanoid:EquipTool(firstTool)
            return firstTool
        end
    end
    return nil
end

-- 6. Fast Attack
local function forceAttack()
    pcall(function()
        local tool = autoScanAndEquipWeapon()
        if tool then tool:Activate() end
        
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        
        local netFolder = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if netFolder then
            local regAttack = netFolder:FindFirstChild("RE/RegisterAttack") or netFolder:FindFirstChild("RegisterAttack")
            if regAttack then regAttack:FireServer() end
        end
    end)
end

-- 7. HÀM QUÉT CHÍNH XÁC + IN THÔNG BÁO DEBUG MỖI KHI TÌM THẤY
local function getPumpkinSnowmanTarget()
    local nearest = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    pcall(function()
        local searchFolders = {Workspace:FindFirstChild("Enemies"), Workspace}
        
        for _, folder in pairs(searchFolders) do
            if folder then
                for _, obj in pairs(folder:GetChildren()) do
                    if obj:IsA("Model") then
                        local name = obj.Name:lower()
                        
                        -- Lọc đúng Pumpkin Snowman
                        if name:find("pumpkin") and name:find("snowman") then
                            local humanoid = obj:FindFirstChildOfClass("Humanoid")
                            local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")

                            if humanoid and humanoid.Health > 0 and primaryPart then
                                local dist = (hrp.Position - primaryPart.Position).Magnitude
                                if dist < shortestDistance then
                                    shortestDistance = dist
                                    nearest = primaryPart
                                    
                                    -- In thông báo Debug ra Console Delta (chỉ in 1 lần mỗi khi phát hiện con mới)
                                    if lastLoggedTarget ~= obj then
                                        lastLoggedTarget = obj
                                        local pos = primaryPart.Position
                                        print("========================================")
                                        print("[FOUND] Phát hiện Pumpkin Snowman!")
                                        print(" Tên Model: " .. obj.Name)
                                        print(" Máu (HP): " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth))
                                        print(string.format(" Tọa độ (XYZ): X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z))
                                        print(" Khoảng cách: " .. math.floor(dist) .. " studs")
                                        print("========================================")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return nearest
end

-- 8. Luồng Tấn Công
task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().AutoSpecialPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local target = getPumpkinSnowmanTarget()
                if target then
                    local distance = (hrp.Position - target.Position).Magnitude
                    if distance <= 25 then
                        forceAttack()
                    end
                end
            end)
        end
    end
end)

-- 9. Luồng Bay (Tween) & Kiểm Soát Server Hop (5s)
task.spawn(function()
    local currentTween = nil
    
    while task.wait(0.5) do
        if getgenv().AutoSpecialPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    autoSelectPirates()
                    return
                end
                local hrp = char.HumanoidRootPart

                local target = getPumpkinSnowmanTarget()
                if target and target.Parent then
                    noTargetTime = 0
                    
                    local targetCFrame = target.CFrame * CFrame.new(0, 5, 0)
                    local distance = (hrp.Position - targetCFrame.Position).Magnitude

                    if distance > 6 then
                        if currentTween then currentTween:Cancel() end
                        local timeTravel = distance / getgenv().TweenSpeed
                        local tweenInfo = TweenInfo.new(timeTravel, Enum.EasingStyle.Linear)
                        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                        currentTween:Play()
                    else
                        if currentTween then currentTween:Cancel() end
                        hrp.CFrame = targetCFrame
                    end
                else
                    if currentTween then currentTween:Cancel() end
                    lastLoggedTarget = nil -- Reset biến log khi mục tiêu bị tiêu diệt
                    noTargetTime = noTargetTime + 0.5
                    print("[Server Hop Tracker] Đang tìm Pumpkin Snowman: " .. noTargetTime .. "/5s")

                    if noTargetTime >= 5 then
                        serverHop()
                    end
                end
            end)
        end
    end
end)
