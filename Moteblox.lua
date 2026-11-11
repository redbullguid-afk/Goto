-- ==========================================================
-- Blox Fruits Halloween Event Auto Script - Phần 1
-- Tính năng: Auto ESP Pumpkin, Tween Bay, Auto Attack, Xử lý Quái
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Cấu hình người dùng
getgenv().AutoPumpkin = true
getgenv().TweenSpeed = 350 -- Tốc độ bay (điều chỉnh tùy ý)

print("[Halloween Script] Đã khởi động Phần 1 thành công!")

-- Hàm tìm kiếm Pumpkin gần nhất trong Workspace
local function getNearestPumpkin()
    local nearest = nil
    local shortestDistance = math.huge

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("pumpkin") or obj.Name:lower():find("candy") then
            local part = obj:IsA("Model") and obj.PrimaryPart or (obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart"))
            if part then
                local dist = (HumanoidRootPart.Position - part.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    nearest = part
                end
            end
        end
    end
    return nearest
end

-- Hàm kiểm tra quái vật xuất hiện xung quanh
local function checkNearbyMobs()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    for _, enemy in pairs(enemiesFolder:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        local hum = enemy:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = (HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < 25 then -- Phạm vi phát hiện quái đứng chờ/cản đường
                return enemy
            end
        end
    end
    return nil
end

-- Hàm gửi lệnh tấn công tự động (Không cần người chơi click chuột)
local function autoAttack()
    pcall(function()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        else
            -- Kích hoạt tấn công cơ bản / combat nếu không cầm tool
            VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
end

-- Vòng lặp chính xử lý logic sự kiện
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoPumpkin then
            pcall(function()
                Character = LocalPlayer.Character
                if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
                HumanoidRootPart = Character.HumanoidRootPart

                -- 1. Ưu tiên xử lý nếu có quái xuất hiện gần đó
                local mob = checkNearbyMobs()
                if mob and mob:FindFirstChild("HumanoidRootPart") then
                    local mobHrp = mob.HumanoidRootPart
                    local distToMob = (HumanoidRootPart.Position - mobHrp.Position).Magnitude
                    
                    if distToMob > 10 then
                        local tweenInfo = TweenInfo.new(distToMob / getgenv().TweenSpeed, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = mobHrp.CFrame * CFrame.new(0, 5, 5)})
                        tween:Play()
                        tween.Completed:Wait()
                    end

                    -- Đứng chờ và đánh liên tục cho đến khi quái chết
                    while mob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and getgenv().AutoPumpkin do
                        autoAttack()
                        task.wait(0.2)
                    end
                end

                -- 2. Tìm và bay đến Pumpkin
                local pumpkin = getNearestPumpkin()
                if pumpkin then
                    local distance = (HumanoidRootPart.Position - pumpkin.Position).Magnitude
                    local timeTravel = distance / getgenv().TweenSpeed
                    
                    local tweenInfo = TweenInfo.new(timeTravel, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = pumpkin.CFrame + Vector3.new(0, 3, 0)})
                    tween:Play()
                    
                    -- Theo dõi trong quá trình bay: nếu pumpkin biến mất hoặc bị người khác nhặt mất
                    while tween.PlaybackState == Enum.PlaybackState.Playing do
                        if not pumpkin.Parent or not pumpkin then
                            tween:Cancel()
                            print("[Halloween Script] Pumpkin đã biến mất, chuyển sang mục tiêu tiếp theo...")
                            break
                        end
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
end)
