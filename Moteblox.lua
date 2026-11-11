-- ==========================================================
-- Blox Fruits Halloween Auto Pumpkin Script - Phiên bản chuẩn không lỗi
-- Hỗ trợ tối ưu: Delta, Codex, Hydrogen
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- Bật/Tắt Auto (Có thể gõ: getgenv().AutoPumpkin = false trên console để tắt)
getgenv().AutoPumpkin = true
getgenv().TweenSpeed = 300 -- Tốc độ bay mượt không bị văng

print("[Halloween Script] Đã khởi động thành công!")

-- 1. Chế độ Noclip tự động giúp bay xuyên tường/địa hình không kẹt
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

-- 2. Hàm trang bị vũ khí cận chiến (Melee / Sword)
local function autoEquipWeapon()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and (currentTool.ToolTip == "Melee" or currentTool.ToolTip == "Sword") then
            return
        end
        
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword") then
                    char.Humanoid:EquipTool(tool)
                    break
                end
            end
        end
    end)
end

-- 3. Hàm kích hoạt đánh Melee an toàn
local function triggerAttack()
    pcall(function()
        autoEquipWeapon()
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0,0))
    end)
end

-- 4. Hàm quét tìm Pumpkin chính xác 100% (Loại bỏ triệt để người chơi đội mũ bí ngô)
local function getNearestPumpkin()
    local nearest = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj and obj.Name == "Pumpkin" then
                -- Kiểm tra xem vật thể có gắn với Người chơi hoặc NPC không
                local isPlayerOrNPC = false
                local ancestorModel = obj:FindFirstAncestorOfClass("Model")
                
                if ancestorModel then
                    if Players:GetPlayerFromCharacter(ancestorModel) or ancestorModel:FindFirstChildOfClass("Humanoid") then
                        isPlayerOrNPC = true
                    end
                end

                -- Nếu là Pumpkin sự kiện thật sự nằm tự do trên map
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

-- 5. Luồng xử lý Tấn công liên tục khi ở gần mục tiêu
task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local pumpkin = getNearestPumpkin()
                
                if hrp and pumpkin then
                    local distance = (hrp.Position - pumpkin.Position).Magnitude
                    if distance <= 15 then
                        triggerAttack()
                    end
                end
            end)
        end
    end
end)

-- 6. Luồng xử lý Di chuyển (Tween Bay mượt, tự động hủy khi pumpkin biến mất)
task.spawn(function()
    local currentTween = nil
    
    while task.wait(0.2) do
        if getgenv().AutoPumpkin then
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart

                local pumpkin = getNearestPumpkin()
                if pumpkin and pumpkin.Parent then
                    local distance = (hrp.Position - pumpkin.Position).Magnitude

                    if distance > 8 then
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
        else
            if currentTween then currentTween:Cancel() end
        end
    end
end)
