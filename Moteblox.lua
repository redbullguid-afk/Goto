-- ==========================================================
-- Blox Fruits - Auto Fruit Finder & Auto Store (Fix Crash & Lỗi Chạy)
-- Hỗ trợ tối ưu: Delta Executor | Auto Store, Skip Owned, Server Hop 5s
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

print("[Fruit Finder] Khởi động script thành công! Đang quét trái ác quỷ...")

-- 1. QUEUE ON TELEPORT AN TOÀN (Không lỗi nếu executor không hỗ trợ)
pcall(function()
    local queueFunc = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
    if queueFunc then
        queueFunc([[
            task.wait(3)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/redbullguid-afk/Goto/main/Moteblox.lua"))()
        ]])
    end
end)

-- 2. Hàm gọi Remote an toàn tránh kẹt game
local function getCommF()
    local success, comm = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
    end)
    if success and comm then
        return comm
    end
    return nil
end

-- 3. Tự động chọn phe Hải Tặc
task.spawn(function()
    task.wait(1)
    pcall(function()
        local commF = getCommF()
        if commF then
            commF:InvokeServer("SetTeam", "Pirates")
        end
    end)
end)

-- 4. Kiểm tra trái đã có trong kho chưa
local function isFruitOwned(fruitName)
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

-- 5. Tự động cất trái vào kho
local function autoStoreFruit()
    pcall(function()
        local commF = getCommF()
        if not commF then return end
        
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        
        local function checkAndStore(tool)
            if tool and tool:IsA("Tool") and (tool.Name:find("Fruit") or tool.ToolTip == "Blox Fruit") then
                local fruitName = tool.Name
                print("[Auto Store] Đang cất trái: " .. fruitName)
                
                if tool.Parent == backpack and char and char:FindFirstChildOfClass("Humanoid") then
                    char.Humanoid:EquipTool(tool)
                    task.wait(0.2)
                end
                
                commF:InvokeServer("StoreFruit", fruitName, tool)
            end
        end

        if char then
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then checkAnd
