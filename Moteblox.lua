-- Blox Fruit Halloween Event Script - Delta Optimized
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Cấu hình tính năng
getgenv().HalloweenSettings = {
    AutoESP = true,
    TeleportToPumpkin = true,
    AutoAttack = true,
    WaitMobClear = true,
    AutoNoclip = true,
    AutoSelectMelee = true,
}

-- Tính năng Noclip (Chống kẹt tường/đảo khi bay)
RunService.Stepped:Connect(function()
    if getgenv().HalloweenSettings.AutoNoclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Tự động chọn Melee (Võ) ở Slot 1 hoặc Slot 2
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
            if (tool:FindFirstChild("ToolTip") and tool.ToolTip == "Melee") or string.find(tool.Name:lower(), "style") or string.find(tool.Name:lower(), "karate") or string.find(tool.Name:lower(), "step") or string.find(tool.Name:lower(), "claw") then
                character.Humanoid:EquipTool(tool)
                break
            end
        end
    end
end

-- Tìm Pumpkin gần nhất
local function GetNearestPumpkin()
    local nearest = nil
    local shortestDist = math.huge

    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and (string.find(v.Name:lower(), "pumpkin") or string.find(v.Name:lower(), "candy")) then
            local rootPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Part") or v:FindFirstChildOfClass("Part")
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

-- Vòng lặp chính xử lý Auto
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end
            
            EquipMelee()

            local pumpkin = GetNearestPumpkin()
            if pumpkin then
                local pPart = pumpkin:FindFirstChild("HumanoidRootPart") or pumpkin:FindFirstChild("PrimaryPart") or pumpkin:FindFirstChildOfClass("Part")
                if pPart then
                    if getgenv().HalloweenSettings.TeleportToPumpkin then
                        character.HumanoidRootPart.CFrame = pPart.CFrame + Vector3.new(0, 5, 0)
                    end

                    local mobWaiting = false
                    if Workspace:FindFirstChild("Enemies") then
                        for _, mob in pairs(Workspace.Enemies:GetChildren()) do
                            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                            local mobHum = mob:FindFirstChild("Humanoid")
                            if mobHRP and mobHum and mobHum.Health > 0 then
                                if (mobHRP.Position - pPart.Position).Magnitude < 35 then
                                    mobWaiting = true
                                    break
                                end
                            end
                        end
                    end

                    if (not mobWaiting or getgenv().HalloweenSettings.WaitMobClear) and getgenv().HalloweenSettings.AutoAttack then
                        VirtualUser:Button1Down(Vector2.new(0,0), Camera.CFrame)
                        task.wait(0.1)
                        VirtualUser:Button1Up(Vector2.new(0,0), Camera.CFrame)
                    end
                end
            end
        end)
    end
end)

print("Blox Fruit Halloween Script Loaded Successfully!")
