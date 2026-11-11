-- ==========================================================
-- Blox Fruits Halloween Event Auto Script - Phần 1 (Chỉ Đánh Thường)
-- Tính năng: Auto Equip, Auto Click thường 100%, Anti-Giật Bay
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình
getgenv().AutoPumpkin = true
getgenv().TweenSpeed = 280

print("[Halloween Script] Đã chuyển sang chế độ chỉ Auto Đánh Thường (Không dùng Skill)!")

-- 1. Hàm tự động cầm Vũ khí trên tay (Melee / Sword)
local function autoEquipWeapon()
    pcall(function()
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
    end)
end

-- 2. Hàm chỉ thực hiện đánh thường (Click chuột trái / Swing) liên tục
local function autoBasicAttack()
    pcall(function()
        autoEquipWeapon()
        
        -- Dùng VirtualInputManager giả lập click chuột trái để đánh thường
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

-- 3. Hàm tìm Pumpkin gần nhất trong Workspace
local function getNearestPumpkin()
    local nearest = nil
    local shortestDistance = math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("pumpkin") or obj.Name:lower():find("candy") then
            local part = obj:IsA("Model") and obj.PrimaryPart or (obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart"))
            if part then
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

-- 4. Vòng lặp chính xử lý Bay và Đánh thường
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                local hrp = char.HumanoidRootPart

                local pumpkin = getNearestPumpkin()
                if pumpkin then
                    local distance = (hrp.Position - pumpkin.Position).Magnitude
                    
                    -- Nếu ở xa -> Bay đến Pumpkin (với tốc độ chống giật)
                    if distance > 8 then
                        local timeTravel = distance / getgenv().TweenSpeed
                        local tweenInfo = TweenInfo.new(timeTravel, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = pumpkin.CFrame * CFrame.new(0, 3, 0)})
                        tween:Play()

                        while tween.PlaybackState == Enum.PlaybackState.Playing do
                            if not pumpkin.Parent or not pumpkin then
                                tween:Cancel()
                                break
                            end
                            task.wait(0.1)
                        end
                    else
                        -- Đã tới nơi -> Giữ vị trí và liên tục thực hiện đánh thường
                        hrp.CFrame = pumpkin.CFrame * CFrame.new(0, 3, 0)
                        autoBasicAttack()
                    end
                end
            end)
        end
    end
end)
