-- ==========================================================
-- Blox Fruits Halloween Event Auto Script - Sửa Lỗi Triệt Để
-- Hỗ trợ: Delta, Hydrogen, Codex | Auto Melee & Find Pumpkin
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình
getgenv().AutoPumpkin = true
getgenv().TweenSpeed = 300

print("[Halloween Script] Đã khởi động phiên bản sửa lỗi tương thích Delta!")

-- 1. Giữ Noclip xuyên địa hình liên tục
RunService.Stepped:Connect(function()
    if getgenv().AutoPumpkin and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 2. Tự động cầm Melee (Võ)
local function equipMelee()
    local char = LocalPlayer.Character
    if not char then return nil end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.ToolTip == "Melee" or currentTool.ToolTip == "Sword") then
        return currentTool
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword") then
                char.Humanoid:EquipTool(tool)
                return tool
            end
        end
    end
    return nil
end

-- 3. Kích hoạt đòn đánh thường mượt mà (Không bị Anti-cheat chặn)
local function triggerAttack()
    pcall(function()
        local tool = equipMelee()
        if tool then
            tool:Activate()
        end
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0,0))
    end)
end

-- 4. Hàm tìm chính xác Pumpkin trên toàn bản đồ (Loại bỏ triệt để Player & NPC)
local function getNearestPumpkin()
    local nearest = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- Quét toàn bộ Descendants để không bỏ sót Pumpkin nằm trong Folder con
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Pumpkin" or obj.Name == "PumpkinModel" then
            -- Bỏ qua nếu thuộc về Player hoặc NPC
            local isModelPlayer = false
            local ancestorModel = obj:FindFirstAncestorOfClass("Model")
            
            if ancestorModel then
                if Players:GetPlayerFromCharacter(ancestorModel) or ancestorModel:FindFirstChildOfClass("Humanoid") then
                    isModelPlayer = true
                end
            end

            if not isModelPlayer then
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
    return nearest
end

-- 5. Vòng lặp Auto Attack (Chạy liên tục)
task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().AutoPumpkin then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local pumpkin = getNearestPumpkin()
            if hrp and pumpkin then
                local distance = (hrp.Position - pumpkin.Position).Magnitude
                if distance <= 25 then
                    triggerAttack()
                end
            end
        end
    end
end)

-- 6. Luồng di chuyển (Tween Bay)
local currentTween = nil
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart

                local pumpkin = getNearestPumpkin()
                if pumpkin and pumpkin.Parent then
                    local distance = (hrp.Position - pumpkin.Position).Magnitude

                    if distance > 10 then
                        if currentTween then currentTween:Cancel() end
                        
                        local timeTravel = distance / getgenv().TweenSpeed
                        local tweenInfo = TweenInfo.new(timeTravel, Enum.EasingStyle.Linear)
                        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = pumpkin.CFrame * CFrame.new(0, 3, 0)})
                        currentTween:Play()
                    else
                        if currentTween then currentTween:Cancel() end
                        hrp.CFrame = pumpkin.CFrame * CFrame.new(0, 3, 0)
                    end
                else
                    if currentTween then currentTween:Cancel() end
                end
            end)
        end
    end
end)
