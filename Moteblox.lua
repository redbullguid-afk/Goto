-- Blox Fruit Halloween Event Script - Part 1
-- Features: ESP Pumpkin, Interactive & Teleport, Auto Attack (No Click), Mob Waiting

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Cấu hình tùy chỉnh
getgenv().HalloweenSettings = {
    AutoESP = true,
    TeleportToPumpkin = true,
    AutoAttack = true,
    WaitMobClear = true,
    AttackRange = 50, -- Khoảng cách tấn công xa
}

-- Hàm kiểm tra và lấy pumpkin (bí ngô sự kiện)
local function GetNearestPumpkin()
    local nearest = nil
    local shortestDist = math.huge

    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and (string.find(v.Name:lower(), "pumpkin") or string.find(v.Name:lower(), "candy")) then
            local rootPart = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Part")
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

-- Tính năng ESP Pumpkin và Tương tác trực quan
local function CreateESP(targetPart)
    if not targetPart:FindFirstChild("HalloweenESP") then
        local bill = Instance.new("BillboardGui")
        bill.Name = "HalloweenESP"
        bill.Size = UDim2.new(0, 100, 0, 50)
        bill.AlwaysOnTop = true
        bill.Adornee = targetPart

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "🎃 Pumpkin"
        text.TextColor3 = Color3.fromRGB(255, 140, 0)
        text.TextScaled = true
        text.Font = Enum.Font.SourceSansBold
        text.Parent = bill

        bill.Parent = targetPart
    end
end

-- Vòng lặp chính xử lý logic sự kiện
Task = task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not getgenv().HalloweenSettings.AutoESP then return end

            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then return end
            local hrp = character.HumanoidRootPart

            -- Tìm Pumpkin
            local pumpkin = GetNearestPumpkin()
            if pumpkin then
                local pPart = pumpkin:FindFirstChild("HumanoidRootPart") or pumpkin:FindFirstChild("PrimaryPart") or pumpkin:FindFirstChildOfClass("Part")
                if pPart then
                    CreateESP(pPart)

                    -- Bay đến chỗ pumpkin nếu bật tính năng
                    if getgenv().HalloweenSettings.TeleportToPumpkin then
                        hrp.CFrame = pPart.CFrame + Vector3.new(0, 5, 0)
                    end

                    -- Kiểm tra xem có quái vật xung quanh đang canh giữ không
                    local mobWaiting = false
                    for _, mob in pairs(Workspace.Enemies:GetChildren()) do
                        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                        local mobHum = mob:FindFirstChild("Humanoid")
                        if mobHRP and mobHum and mobHum.Health > 0 then
                            if (mobHRP.Position - pPart.Position).Magnitude < 30 then
                                mobWaiting = true
                                -- Chờ quái chết trước khi lấy pumpkin hoặc xử lý quái
                                if getgenv().HalloweenSettings.WaitMobClear then
                                    -- Tấn công quái từ xa tự động
                                    if getgenv().HalloweenSettings.AutoAttack then
                                        VirtualUser:Button1Down(Vector2.new(0,0), Camera.CFrame)
                                        task.wait(0.1)
                                        VirtualUser:Button1Up(Vector2.new(0,0), Camera.CFrame)
                                    end
                                end
                            end
                        end
                    end

                    -- Nếu không vướng quái hoặc quái đã chết, tiến hành tương tác tấn công/thu thập
                    if not mobWaiting and getgenv().HalloweenSettings.AutoAttack then
                        VirtualUser:Button1Down(Vector2.new(0,0), Camera.CFrame)
                        task.wait(0.2)
                        VirtualUser:Button1Up(Vector2.new(0,0), Camera.CFrame)
                    end
                end
            end
        end)
    end
end)

print("Blox Fruit Halloween Script Part 1 Loaded Successfully!")
