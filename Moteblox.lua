-- ==========================================================
-- Blox Fruits - Auto Fruit Finder (Fix Bỏ Qua Bức Tượng & NPC Nhiệm Vụ)
-- Feature: Chỉ nhặt Trái dưới đất, Bỏ qua Bức Tượng, Smooth Fly, Auto Store, Hop 5s
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
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

print("[Fruit Finder] Đã cập nhật Fix triệt để lỗi bay nhầm vào Bức Tượng NPC!")

-- 1. QUEUE ON TELEPORT (Tự động chạy lại khi đổi server)
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

-- 4. TỰ ĐỘNG LƯU TRÁI ÁC QUỶ VÀO KHO
local function autoStoreFruit()
    pcall(function()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        
        local function storeTool(tool)
            if tool and tool:IsA("Tool") and (tool.Name:find("Fruit") or tool.ToolTip == "Blox Fruit") then
                local fruitName = tool.Name
                if tool.Parent == backpack and char and char:FindFirstChildOfClass("Humanoid") then
                    char.Humanoid:EquipTool(tool)
                    task.wait(0.2)
                end
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

-- 6. TỐI ƯU CHỐNG GIẬT LAG KHI BAY
RunService.Stepped:Connect(function()
    if getgenv().AutoFruit and LocalPlayer.Character then
        pcall(function()
            local char = LocalPlayer.Character
            local hr
