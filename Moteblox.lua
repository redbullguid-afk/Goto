-- Blox Fruits Halloween Event Script - Fixed & Anti-Cheat Bypassed for Delta
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình cài đặt
getgenv().HalloweenSettings = {
    TeleportToPumpkin = true,
    AutoAttack = true,
    AutoNoclip = true,
    AutoSelectMelee = true,
}

-- Tính năng Noclip an toàn chống kẹt
RunService.Stepped:Connect(function()
    if getgenv().HalloweenSettings.AutoNoclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Tự động chọn Melee (Võ) ở ô 1 hoặc 2
local function EquipMelee()
    if not getgenv().HalloweenSettings.AutoSelectMelee then return end
    local character = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if not character or not backpack then return end

    local currentTool = character:FindFirstChildOfClass("Tool")
    if currentTool and currentTool:FindFirstChild("ToolTip") and currentTool.ToolTip == "Melee" then
        return
    end

    local items = backpack:GetChildren()
    for index = 1, math.min(2, #items) do
        local tool = items[index]
        if tool and tool:IsA("Tool") then
            if (tool:FindFirstChild("ToolTip") and tool.ToolTip == "Melee") or string.find(tool.Name:lower(), "style") or string.find(tool.Name:lower(), "step") or string.find(tool.Name:lower(), "claw") or string.find(tool.Name:lower(), "human") then
                character.Humanoid:EquipTool(tool)
                break
            end
        end
    end
end

-- Tìm Pumpkin gần nhất trên Workspace
local function GetNearestPumpkin()
    local nearest = nil
    local shortestDist = math.huge

    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and (string.find(v.Name:lower(), "pumpkin") or string.find(v.Name:lower(), "candy")) then
            local rootPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("PrimaryPart") or v:FindFirstChildOfClass("Part")
            if rootPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = v
                end
            end
        end
    end
    return nearest
end

-- Hàm tấn công chuẩn bằng Combat Remotes của Blox Fruits (Thay thế VirtualUser bị Anti-Cheat chặn)
local function AttackTarget()
    pcall(function()
        local combatRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if combatRemote then
            combatRemote:InvokeServer("LeftClick")
        end
    end)
end

-- Vòng lặp chính thực thi an toàn
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end
            
            -- Trang bị vũ khí Melee
            EquipMelee()

            -- Tìm và di chuyển đến Pumpkin
            local pumpkin = GetNearestPumpkin()
            if pumpkin then
                local pPart = pumpkin:FindFirstChild("HumanoidRootPart") or pumpkin:FindFirstChild("PrimaryPart") or pumpkin:FindFirstChildOfClass("Part")
                if pPart then
                    if getgenv().HalloweenSettings.TeleportToPumpkin then
                        -- Dịch chuyển nhẹ nhàng phía trên Pumpkin để tránh bị lọt xuống đất
                        character.HumanoidRootPart.CFrame = pPart.CFrame + Vector3.new(0, 4, 0)
                    end

                    -- Thực hiện tấn công tự động
                    if getgenv().HalloweenSettings.AutoAttack then
                        AttackTarget()
                    end
                end
            end
        end)
    end
end)

print("Blox Fruits Halloween Script (Anti-Cheat Bypass) Successfully Loaded!")
