-- ==========================================================
-- Blox Fruits Halloween Event Auto Script - Chỉ Auto Pumpkin
-- Tính năng: Chỉ tìm Pumpkin thật, Fast Attack siêu nhanh, Noclip
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình
getgenv().AutoPumpkin = true
getgenv().TweenSpeed = 300

print("[Halloween Script] Đã cài đặt chế độ CHỈ SĂN PUMPKIN!")

-- 1. Bật Noclip xuyên tường/địa hình
RunService.Stepped:Connect(function()
    if getgenv().AutoPumpkin and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 2. Tự động cầm vũ khí
local function autoEquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    
    if not char:FindFirstChildOfClass("Tool") then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or tool.ToolTip == "Blox Fruit") then
                    char.Humanoid:EquipTool(tool)
                    break
                end
            end
        end
    end
end

-- 3. Fast Attack liên tục
local function fastAttack()
    pcall(function()
        autoEquipWeapon()
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

-- 4. Hàm chỉ lọc DUY NHẤT vật phẩm "Pumpkin"
local function getNearestPumpkin()
    local nearest = nil
    local shortestDistance = math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- Quét chính xác các vật thể tên "Pumpkin" ngoài Workspace
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name == "Pumpkin" and not obj:FindFirstChild("Humanoid") then
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
    return nearest
end

-- 5. Vòng lặp Fast Attack (Chạy siêu tốc 0.01s)
task.spawn(function()
    while true do
        task.wait(0.01)
        if getgenv().AutoPumpkin then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local pumpkin = getNearestPumpkin()
            if hrp and pumpkin then
                local distance = (hrp.Position - pumpkin.Position).Magnitude
                if distance <= 15 then
                    fastAttack()
                end
            end
        end
    end
end)

-- 6. Vòng lặp di chuyển Tween Bay
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart

                local pumpkin = getNearestPumpkin()
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
