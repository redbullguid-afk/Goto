-- ==========================================================
-- Blox Fruits - Auto Multi-Fruit Finder, Natural Pickup & Store
-- Quy trình: Bay tới nhặt tự nhiên -> Tự động cất kho -> Quét trái tiếp theo -> Server Hop 5s
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
getgenv().TweenSpeed = 250

local noFruitTime = 0
local processedFruits = {} -- Lưu trữ danh sách các trái đã xử lý xong để không lặp lại

print("[Auto Fruit] Đã bật chế độ Săn & Nhặt nhiều trái tự nhiên!")

-- 1. Auto Re-execute khi đổi Server
pcall(function()
    local queueFunc = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
    if queueFunc then
        queueFunc([[
            task.wait(3)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/redbullguid-afk/Goto/main/Moteblox.lua"))()
        ]])
    end
end)

-- 2. Hàm lấy Remote CommF_ an toàn
local function getCommF()
    local success, comm = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
    end)
    if success and comm then return comm end
    return nil
end

-- 3. Chọn phe Hải Tặc
task.spawn(function()
    task.wait(1)
    pcall(function()
        local commF = getCommF()
        if commF then commF:InvokeServer("SetTeam", "Pirates") end
    end)
end)

-- 4. Kiểm tra Trái Ác Quỷ đã có trong Rương (Inventory) chưa
local function isFruitInInventory(fruitName)
    local owned = false
    pcall(function()
        local commF = getCommF()
        if commF then
            local inventory = commF:InvokeServer("getInventory")
            if inventory then
                for _, item in pairs(inventory) do
                    if item.Name and item.Name:lower() == fruitName:lower() then
                        owned = true
                        break
                    end
                end
            end
        end
    end)
    return owned
end

-- 5. Tự động cất rương các trái nằm trong Balo hoặc trên tay
local function autoStoreFruits()
    pcall(function()
        local commF = getCommF()
        if not commF then return end

        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        
        local function checkAndStore(tool)
            if tool and tool:IsA("Tool") then
                local name = tool.Name
                if (name:find("Fruit") or tool.ToolTip == "Blox Fruit") and not name:find("Statue") and not name:find("Power") then
                    if not processedFruits[tool] then
                        if isFruitInInventory(name) then
                            print("[SKIP] Trái " .. name .. " đã có trong rương -> Đánh dấu bỏ qua!")
                            processedFruits[tool] = true
                        else
                            print("[STORE] Đang cất trái vào rương: " .. name)
                            commF:InvokeServer("StoreFruit", name, tool)
                            processedFruits[tool] = true
                            task.wait(0.5)
                        end
                    end
                end
            end
        end

        if char then
            for _, tool in pairs(char:GetChildren()) do checkAndStore(tool) end
        end
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do checkAndStore(tool) end
        end
    end)
end

-- 6. Server Hop 5s nếu không còn trái
local function serverHop()
    print("[Server Hop] Không tìm thấy trái mới trong 5s. Đang đổi server...")
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

-- 7. Khóa trọng lực & Chống giật lùi (Smooth Fly)
RunService.Stepped:Connect(function()
    if getgenv().AutoFruit and LocalPlayer.Character then
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if char and hrp then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end

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

-- 8. QUÉT TRÁI ÁC QUỶ DƯỚI ĐẤT (BỎ QUA TƯỢNG VÀ TRÁI ĐÃ XỬ LÝ)
local function getTargetFruit()
    local nearest = nil
    local shortestDistance = math.huge
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    pcall(function()
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Tool") or (obj:IsA("Model") and obj:FindFirstChild("Handle")) then
                local name = obj.Name:lower()
                
                -- Loại bỏ tượng, bệ thờ, NPC
                local isStatueOrQuest = name:find("statue") or name:find("pedestal") or name:find("shrine") or name:find("quest") or name:find("npc")
                local isInsideCharacter = obj:FindFirstAncestorOfClass("Model") and Players:GetPlayerFromCharacter(obj:FindFirstAncestorOfClass("Model"))
                
                if not isStatueOrQuest and not isInsideCharacter then
                    -- Kiểm tra xem trái này đã được xử lý (đã nhặt/đã skip) trong phiên này chưa
                    if not processedFruits[obj] then
                        -- Kiểm tra xem đã có trong rương chưa
                        if not isFruitInInventory(obj.Name) then
                            local handle = obj:FindFirstChild("Handle") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            if handle then
                                local dist = (hrp.Position - handle.Position).Magnitude
                                if dist < shortestDistance then
                                    shortestDistance = dist
                                    nearest = handle
                                end
                            end
                        else
                            -- Nếu đã có trong rương thì đánh dấu đã xử lý để bỏ qua luôn
                            processedFruits[obj] = true
                        end
                    end
                end
            end
        end
    end)
    
    return nearest
end

-- 9. LUỒNG THỰC THI CHÍNH (BAY, NHẶT VÀ CHUYỂN TRÁI TIẾP THEO HOẶC ĐỔI SERVER)
task.spawn(function()
    local currentTween = nil
    
    while task.wait(0.3) do
        if getgenv().AutoFruit then
            pcall(function()
                -- Cất rương tự động các trái đang có
                autoStoreFruits()

                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
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
                        
                        -- Chạm nhặt tự nhiên
                        if firetouchinterest and char:FindFirstChild("LeftFoot") then
                            firetouchinterest(char.LeftFoot, targetFruit, 0)
                            firetouchinterest(char.LeftFoot, targetFruit, 1)
                        end
                        
                        local parentObj = targetFruit.Parent
                        if parentObj then
                            for _, prompt in pairs(parentObj:GetDescendants()) do
                                if prompt:IsA("ProximityPrompt") then
                                    fireproximityprompt(prompt)
                                end
                            end
                            -- Đánh dấu vật thể này đã được ghé thăm để script chuyển sang tìm trái tiếp theo trên bản đồ
                            processedFruits[parentObj] = true
                        end
                        
                        task.wait(0.5)
                        autoStoreFruits()
                    end
                else
                    if currentTween then currentTween:Cancel() end
                    noFruitTime = noFruitTime + 0.3
                    print("[Fruit Finder] Không thấy trái mới, đang đếm ngược Server Hop: " .. math.floor(noFruitTime) .. "/5s")

                    if noFruitTime >= 5 then
                        serverHop()
                    end
                end
            end)
        end
    end
end)
