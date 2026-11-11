-- ==========================================================
-- Blox Fruits Halloween - Script Săn Boss/Người Tuyết Bí Ngô Đặc Biệt
-- Tính năng: Lọc bí ngô đặc biệt, Chống rơi lơ lửng, Fast Attack, Auto Team
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

getgenv().AutoSpecialPumpkin = true
getgenv().TweenSpeed = 300

print("[Halloween Special] Đã khởi động script săn Người Tuyết Bí Ngô đặc biệt!")

-- 1. Tự động chọn phe Hải Tặc khi vào game
local function autoSelectPirates()
    pcall(function()
        local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer("SetTeam", "Pirates")
        end
    end)
end
autoSelectPirates()

-- 2. Hệ thống Noclip & Đóng băng lơ lửng chống rơi (Hover)
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
    else
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:FindFirstChild("SpecialHoverForce") then
                hrp.SpecialHoverForce:Destroy()
            end
        end)
    end
end)

-- 3. Tự động trang bị vũ khí Melee / Sword
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

-- 4. Kích hoạt Fast Attack liên tục
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

-- 5. HÀM QUÉT ĐẶC BIỆT: Tìm "Người tuyết bí ngô" (Boss / Model có Humanoid hoặc nhiều tầng)
local function getSpecialPumpkinTarget()
    local nearest = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    pcall(function()
        -- Quét trong thư mục Enemies hoặc toàn bộ Workspace tìm đối tượng có dạng Boss/Mob đặc biệt
        local searchFolders = {Workspace:FindFirstChild("Enemies"), Workspace}
        
        for _, folder in pairs(searchFolders) do
            if folder then
                for _, obj in pairs(folder:GetChildren()) do
                    if obj:IsA("Model") then
                        local name = obj.Name:lower()
                        local humanoid = obj:FindFirstChildOfClass("Humanoid")
                        local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")

                        -- Nhận diện dựa trên tên sự kiện hoặc việc đối tượng có thanh máu (Humanoid) và từ khóa liên quan đến Pumpkin/Boss/Giant
                        local isSpecial = (name:find("pumpkin") or name:find("snowman") or name:find("boss") or name:find("jack")) 
                                          and humanoid and humanoid.Health > 0

                        -- Hoặc nhận diện nếu model có nhiều phần xếp chồng (giống hình người tuyết) nhưng không phải Player
                        if not Players:GetPlayerFromCharacter(obj) and (isSpecial or (humanoid and obj:GetChildren() >= 10)) then
                            if primaryPart then
                                local dist = (hrp.Position - primaryPart.Position).Magnitude
                                if dist < shortestDistance then
                                    shortestDistance = dist
                                    nearest = primaryPart
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

-- 6. Luồng Tấn công mục tiêu đặc biệt
task.spawn(function()
    while true do
        task.wait(0.05)
        if getgenv().AutoSpecialPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local target = getSpecialPumpkinTarget()
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

-- 7. Luồng Bay (Tween) đến mục tiêu
task.spawn(function()
    local currentTween = nil
    
    while task.wait(0.15) do
        if getgenv().AutoSpecialPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    autoSelectPirates()
                    return
                end
                local hrp = char.HumanoidRootPart

                local target = getSpecialPumpkinTarget()
                if target and target.Parent then
                    local targetCFrame = target.CFrame * CFrame.new(0, 5, 0) -- Lơ lửng phía trên 5 studs
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
                end
            end)
        else
            if currentTween then currentTween:Cancel() end
        end
    end
end)
