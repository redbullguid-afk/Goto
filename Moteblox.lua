-- ==========================================================
-- Blox Fruits Halloween Script - Auto Team (Pirates) & Auto Pumpkin
-- Hỗ trợ: Delta Executor | Tự động chọn Hải Tặc + Fast Attack + Noclip
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

print("[Halloween Script] Đã khởi động: Auto Chọn Hải Tặc + Săn Bí Ngô!")

-- 1. TỰ ĐỘNG CHỌN PHE HẢI TẶC (PIRATES) KHI VỪA VÀO SERVER
local function autoSelectPirates()
    pcall(function()
        -- Gửi Remote chọn phe Hải Tặc trực tiếp đến Server
        local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer("SetTeam", "Pirates")
        end
    end)
end

-- Gọi chọn phe ngay lập tức khi chạy script
autoSelectPirates()

-- 2. Noclip xuyên địa hình giúp bay không bị cản
RunService.Stepped:Connect(function()
    if getgenv().AutoPumpkin and LocalPlayer.Character then
        pcall(function()
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

-- 3. Tự động Quét và Cầm vũ khí cận chiến (Melee / Sword)
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

-- 4. Kích hoạt đòn đánh thường liên tục
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

-- 5. Quét lọc vị trí Pumpkin thật (Không nhầm Player/NPC)
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

-- 6. Luồng Tấn công xả đòn
task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local pumpkin = scanMapForPumpkin()
                
                if hrp and pumpkin then
                    local distance = (hrp.Position - pumpkin.Position).Magnitude
                    if distance <= 20 then
                        forceAttack()
                    end
                end
            end)
        end
    end
end)

-- 7. Luồng Bay (Tween) đến Bí Ngô
task.spawn(function()
    local currentTween = nil
    
    while task.wait(0.15) do
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    -- Nếu chưa load xong nhân vật (đang ở màn hình chọn phe), gửi lại lệnh chọn phe
                    autoSelectPirates()
                    return
                end
                local hrp = char.HumanoidRootPart

                local pumpkin = scanMapForPumpkin()
                if pumpkin and pumpkin.Parent then
                    local distance = (hrp.Position - pumpkin.Position).Magnitude

                    if distance > 6 then
                        if currentTween then currentTween:Cancel() end
                        
                        local timeTravel = distance / getgenv().TweenSpeed
                        local tweenInfo = TweenInfo.new(timeTravel, Enum.EasingStyle.Linear)
                        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = pumpkin.CFrame * CFrame.new(0, 2, 0)})
                        currentTween:Play()
                    else
                        if currentTween then currentTween:Cancel() end
                        hrp.CFrame = pumpkin.CFrame * CFrame.new(0, 2, 0)
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
