-- ==========================================================
-- Blox Fruits Halloween Script - Quét Jack O' & Khóa Bay Lơ Lửng
-- Hỗ trợ: Delta Executor | Chống Rơi 100% + Auto Team + Fast Attack
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

getgenv().AutoPumpkin = true
getgenv().TweenSpeed = 300

print("[Halloween Script] Đã kích hoạt hệ thống Lơ Lửng + Quét Jack O' Chuẩn!")

-- 1. Tự động chọn phe Hải Tặc
local function autoSelectPirates()
    pcall(function()
        local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer("SetTeam", "Pirates")
        end
    end)
end
autoSelectPirates()

-- 2. Hệ thống Noclip & ĐÓNG BĂNG LƠ LỬNG TRÊN KHÔNG (Chống Rơi 100%)
local hoverVelocity = nil

RunService.Stepped:Connect(function()
    if getgenv().AutoPumpkin and LocalPlayer.Character then
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")

            if char and hrp then
                -- Vô hiệu hóa va chạm với địa hình
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

                -- Khóa trọng lực để nhân vật giữ nguyên độ cao lơ lửng
                if not hrp:FindFirstChild("PumpkinHoverForce") then
                    hoverVelocity = Instance.new("BodyVelocity")
                    hoverVelocity.Name = "PumpkinHoverForce"
                    hoverVelocity.Velocity = Vector3.new(0, 0, 0)
                    hoverVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                    hoverVelocity.Parent = hrp
                end

                if humanoid then
                    humanoid.PlatformStand = true -- Tránh hoạt ảnh té ngã/rơi
                end
            end
        end)
    else
        -- Xóa khóa trọng lực khi tắt script
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:FindFirstChild("PumpkinHoverForce") then
                hrp.PumpkinHoverForce:Destroy()
            end
        end)
    end
end)

-- 3. Tự động trang bị Melee / Sword
local function autoScanAndEquipWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        return currentTool
    end
    
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

-- 4. Kích hoạt đòn đánh nhanh (Fast Attack)
local function forceAttack()
    pcall(function()
        local tool = autoScanAndEquipWeapon()
        if tool then
            tool:Activate()
        end
        
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        
        local netFolder = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if netFolder then
            local regAttack = netFolder:FindFirstChild("RE/RegisterAttack") or netFolder:FindFirstChild("RegisterAttack")
            if regAttack then
                regAttack:FireServer()
            end
        end
    end)
end

-- 5. QUÉT CHUẨN XÁC QUÁI JACK O' (Quét siêu rộng không bị lỗi)
local function getActiveJackMob()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearestMob = nil
    local shortestDist = 150 -- Bán kính phát hiện quái Jack xung quanh

    pcall(function()
        -- Lọc trong thư mục Enemies và Workspace
        local searchFolders = {Workspace:FindFirstChild("Enemies"), Workspace}
        
        for _, folder in pairs(searchFolders) do
            if folder then
                for _, enemy in pairs(folder:GetChildren()) do
                    if enemy:IsA("Model") then
                        local name = enemy.Name:lower()
                        -- Nhận diện các từ khóa của quái Jack O'
                        if name:find("jack") or name:find("lantern") or name:find("halloween") then
                            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                            local enemyHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
                            
                            if humanoid and enemyHrp and humanoid.Health > 0 then
                                local dist = (hrp.Position - enemyHrp.Position).Magnitude
                                if dist < shortestDist then
                                    shortestDist = dist
                                    nearestMob = enemyHrp
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return nearestMob
end

-- 6. Quét lọc vị trí Pumpkin chuẩn
local function scanMapForPumpkin()
    local nearest = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj and obj.Name == "Pumpkin" then
                local isPlayerOrNPC = false
                local ancestorModel = obj:FindFirstAncestorOfClass("Model")
                
                if ancestorModel then
                    if Players:GetPlayerFromCharacter(ancestorModel) or ancestorModel:FindFirstChildOfClass("Humanoid") then
                        isPlayerOrNPC = true
                    end
                end

                if not isPlayerOrNPC then
                    local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                    if part and part.Parent then
                        local dist = (hrp.Position - part.Position).Magnitude
                        if dist < shortestDistance then
                            shortestDistance = dist
                            nearest = part
                        end
                    end
                end
            end
        end
    end)
    
    return nearest
end

-- 7. Luồng Tấn công (Ưu tiên diệt quái Jack O' trước)
task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local jackMob = getActiveJackMob()
                if jackMob then
                    -- Nếu phát hiện quái Jack O', giữ khoảng cách lơ lửng và xả đòn
                    if (hrp.Position - jackMob.Position).Magnitude <= 30 then
                        forceAttack()
                    end
                else
                    -- Nếu không có quái, tiếp tục đánh Pumpkin
                    local pumpkin = scanMapForPumpkin()
                    if pumpkin and (hrp.Position - pumpkin.Position).Magnitude <= 20 then
                        forceAttack()
                    end
                end
            end)
        end
    end
end)

-- 8. Luồng Bay (Tween) Lơ Lửng
task.spawn(function()
    local currentTween = nil
    
    while task.wait(0.15) do
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    autoSelectPirates()
                    return
                end
                local hrp = char.HumanoidRootPart

                -- Ưu tiên 1: Bay đến quái Jack O' và lơ lửng trên đầu quái 6 studs
                local targetPart = getActiveJackMob()
                local targetCFrame = nil

                if targetPart then
                    targetCFrame = targetPart.CFrame * CFrame.new(0, 6, 0)
                else
                    -- Ưu tiên 2: Bay đến Pumpkin lơ lửng phía trên 3 studs
                    local pumpkin = scanMapForPumpkin()
                    if pumpkin then
                        targetCFrame = pumpkin.CFrame * CFrame.new(0, 3, 0)
                    end
                end

                if targetCFrame then
                    local distance = (hrp.Position - targetCFrame.Position).Magnitude

                    if distance > 5 then
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
                end
            end)
        else
            if currentTween then currentTween:Cancel() end
        end
    end
end)
