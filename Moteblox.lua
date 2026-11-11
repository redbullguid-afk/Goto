-- ==========================================================
-- Blox Fruits - Auto Fruit Finder, Auto Store & Smooth Fly (Fix Rubberband)
-- Feature: Fly Smooth No-Lag, Auto Pick & Store Fruit, Skip Owned, Server Hop 5s
-- ==========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

getgenv().AutoFruit = true
getgenv().TweenSpeed = 250 -- Tốc độ bay an toàn chống giật lùi

local noFruitTime = 0
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

print("[Fruit Finder] Đã cập nhật Fix giật bay & Auto Store chuẩn!")

-- 1. QUEUE ON TELEPORT (Tự động kích hoạt lại khi đổi server)
local queueOnTeleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport or qut
if queueOnTeleport then
    pcall(function()
        queueOnTeleport([[
            task.wait(3)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/redbullguid-afk/Goto/main/Moteblox.lua"))()
        ]])
    end)
end

-- 2. Tự động chọn phe Hải Tặc khi vào game
local function autoSelectPirates()
    pcall(function()
        CommF:InvokeServer("SetTeam", "Pirates")
    end)
end
autoSelectPirates()

-- 3. Kiểm tra xem Trái Ác Quỷ đã có trong Rương/Kho đồ chưa
local function isFruitOwned(fruitName)
    local owned = false
    pcall(function()
        local inventory = CommF:InvokeServer("getInventory")
        if inventory then
            for _, item in pairs(inventory) do
                if item.Name and item.Name:lower() == fruitName:lower() then
                    owned = true
                    break
                end
            end
        end
    end)
    return owned
end

-- 4. TỰ ĐỘNG LƯU TRÁI ÁC QUỶ VÀO KHO (FIX HOÀN CHỈNH)
local function autoStoreFruit()
    pcall(function()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        
        local function storeTool(tool)
            if tool and tool:IsA("Tool") and (tool.Name:find("Fruit") or tool.ToolTip == "Blox Fruit") then
                local fruitName = tool.Name
                print("[Auto Store] Đang lưu cất trái: " .. fruitName)
                
                -- Cầm trái lên tay nếu đang ở trong Balo
                if tool.Parent == backpack and char and char:FindFirstChildOfClass("Humanoid") then
                    char.Humanoid:EquipTool(tool)
                    task.wait(0.2)
                end
                
                -- Gửi lệnh cất vào kho
                CommF:InvokeServer("StoreFruit", fruitName, tool)
            end
        end

        if char then
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then storeTool(tool) end
            end
        end
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then storeTool(tool) end
            end
        end
    end)
end

-- 5. Server Hop 5s
local function serverHop()
    print("[Server Hop] Không có Trái Ác Quỷ mới trong 5s. Đang đổi server...")
    pcall(function()
        local placeId = game.PlaceId
        local servers = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/0?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(req)
        
        if data and data.data then
            for _, v in pairs(data.data) do
                if v.playing ~= v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
        end
        
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
        else
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    end)
end

-- 6. TỐI ƯU TRẠNG THÁI BAY (FIX LỖI GIẬT LÙI / RUBBERBAND 100%)
RunService.Stepped:Connect(function()
    if getgenv().AutoFruit and LocalPlayer.Character then
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if char and hrp then
                -- Vô hiệu hóa va chạm
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

                -- Xóa bỏ hoàn toàn vận tốc rơi gây giật lag
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                if not hrp:FindFirstChild("FruitHoverForce") then
                    local hover = Instance.new("BodyVelocity")
                    hover.Name = "FruitHoverForce"
                    hover.Velocity = Vector3.new(0, 0, 0)
                    hover.MaxForce = Vector3.new(0, math.huge, 0)
                    hover.Parent = hrp
                end
            end
        end)
    end
end)

-- 7. QUÉT TRÁI ÁC QUỶ TRÊN BẢN ĐỒ
local function getTargetFruit()
    local nearest = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    pcall(function()
        for _, obj in pairs(Workspace:GetChildren()) do
            if (obj:IsA("Tool") or obj:IsA("Model")) and obj.Name:find("Fruit") then
                local fruitName = obj.Name
                
                if not isFruitOwned(fruitName) then
                    local handle = obj:FindFirstChild("Handle") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if handle then
                        local dist = (hrp.Position - handle.Position).Magnitude
                        if dist < shortestDistance then
                            shortestDistance = dist
                            nearest = handle
                        end
                    end
                end
            end
        end
    end)
    
    return nearest
end

-- 8. LUỒNG BAY (TWEEN) MƯỢT MÀ & NHẶT TRÁI
task.spawn(function()
    local currentTween = nil
    
    while task.wait(0.3) do
        if getgenv().AutoFruit then
            pcall(function()
                autoStoreFruit()

                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    autoSelectPirates()
                    return
                end
                local hrp = char.HumanoidRootPart

                local targetFruit = getTargetFruit()
                if targetFruit and targetFruit.Parent then
                    noFruitTime = 0
                    
                    local targetCFrame = targetFruit.CFrame
                    local distance = (hrp.Position - targetCFrame.Position).Magnitude

                    if distance > 4 then
                        if currentTween then currentTween:Cancel() end
                        
                        local timeTravel = distance / getgenv().TweenSpeed
                        local tweenInfo = TweenInfo.new(timeTravel, Enum.EasingStyle.Linear)
                        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                        currentTween:Play()
                    else
                        if currentTween then currentTween:Cancel() end
                        hrp.CFrame = targetCFrame
                        
                        -- Chạm trực tiếp để nhặt item vào túi
                        if firetouchinterest and char:FindFirstChild("LeftFoot") then
                            firetouchinterest(char.LeftFoot, targetFruit, 0)
                            firetouchinterest(char.LeftFoot, targetFruit, 1)
                        end
                        
                        -- Kích hoạt ProximityPrompt nếu có
                        local parentObj = targetFruit.Parent
                        if parentObj then
                            for _, prompt in pairs(parentObj:GetDescendants()) do
                                if prompt:IsA("ProximityPrompt") then
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                        
                        task.wait(0.5)
                        autoStoreFruit()
                    end
                else
                    if currentTween then currentTween:Cancel() end
                    noFruitTime = noFruitTime + 0.3
                    print("[Fruit Finder] Đang tìm trái mới: " .. math.floor(noFruitTime) .. "/5s")

                    if noFruitTime >= 5 then
                        serverHop()
                    end
                end
            end)
        end
    end
end)
