-- ==========================================================
-- Blox Fruits Halloween Event Auto Script - Sửa Lỗi Đội Mũ & Melee Attack
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình
getgenv().AutoPumpkin = true
getgenv().TweenSpeed = 300

print("[Halloween Script] Đã cập nhật sửa lỗi Player đội bí ngô & Kích hoạt đòn Melee!")

-- 1. Bật Noclip để bay xuyên địa hình không bị cản
RunService.Stepped:Connect(function()
    if getgenv().AutoPumpkin and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 2. Tự động lấy và cầm Melee (Võ) trên tay
local function equipMelee()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and currentTool.ToolTip == "Melee" then
        return currentTool
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                char.Humanoid:EquipTool(tool)
                return tool
            end
        end
    end
    return nil
end

-- 3. Gửi lệnh kích hoạt đòn đánh thường Melee trực tiếp
local function triggerMeleeAttack()
    pcall(function()
        local melee = equipMelee()
        if melee then
            -- Kích hoạt công cụ Melee trực tiếp
            melee:Activate()
            
            -- Gửi tín hiệu đánh thường qua RemoteEvent (Hỗ trợ tốt nhất cho Blox Fruits)
            local netFolder = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
            if netFolder then
                local registerAttack = netFolder:FindFirstChild("RE/RegisterAttack") or netFolder:FindFirstChild("RegisterAttack")
                if registerAttack then
                    registerAttack:FireServer()
                end
            end
        end
    end)
end

-- 4. Hàm lọc CHÍNH XÁC Pumpkin sự kiện (Loại bỏ triệt để Player đội mũ/phụ kiện bí ngô)
local function getNearestRealPumpkin()
    local nearest = nil
    local shortestDistance = math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name == "Pumpkin" then
            -- Kiểm tra xem đối tượng có thuộc về Player nào không
            local isPlayerAcc = false
            
            -- 1. Nếu là con hoặc cháu của một Character
            if obj:FindFirstAncestorOfClass("Model") and Players:GetPlayerFromCharacter(obj:FindFirstAncestorOfClass("Model")) then
                isPlayerAcc = true
            end
            
            -- 2. Nếu chứa Humanoid (NPC hoặc Player)
            if obj:FindFirstChildOfClass("Humanoid") then
                isPlayerAcc = true
            end

            -- Chỉ chọn nếu ĐÚNG LÀ Pumpkin sự kiện tự do trên bản đồ
            if not isPlayerAcc then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
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
    return nearest
end

-- 5. Vòng lặp kích hoạt đánh Melee siêu nhanh
task.spawn(function()
    while true do
        task.wait(0.01) -- Độ trễ cực nhỏ cho tốc độ xả đòn Melee
        if getgenv().AutoPumpkin then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local pumpkin = getNearestRealPumpkin()
            if hrp and pumpkin then
                local distance = (hrp.Position - pumpkin.Position).Magnitude
                if distance <= 15 then
                    triggerMeleeAttack()
                end
            end
        end
    end
end)

-- 6. Vòng lặp Tween di chuyển đến Pumpkin
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart

                local pumpkin = getNearestRealPumpkin()
                if pumpkin and pumpkin.Parent then
                    local distance = (hrp.Position - pumpkin.Position).Magnitude
                    
                    if distance > 10 then
                        local timeTravel = distance / getgenv().TweenSpeed
                        local tweenInfo = TweenInfo.new(timeTravel, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = pumpkin.CFrame * CFrame.new(0, 2, 0)})
                        tween:Play()

                        while tween.PlaybackState == Enum.PlaybackState.Playing do
                            if not pumpkin or not pumpkin.Parent then
                                tween:Cancel()
                                break
                            end
                            task.wait(0.05)
                        end
                    else
                        hrp.CFrame = pumpkin.CFrame * CFrame.new(0, 2, 0)
                    end
                end
            end)
        end
    end
end)
