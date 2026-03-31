-- [[ NEOHUB - TOTO STYLE ULTIMATE (AUTO GRAB ADDED) ]]
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- 1. 変数・座標設定
local A1 = {Vector3.new(-472.59,-7.30,94.43), Vector3.new(-484.55,-5.33,95.05), Vector3.new(-472.59,-7.30,94.43), Vector3.new(-471.25,-6.83,7.08)}
local B1 = {Vector3.new(-474.02,-7.30,25.55), Vector3.new(-484.92,-5.13,24.53), Vector3.new(-474.02,-7.30,25.55), Vector3.new(-470.93,-6.83,113.38)}

local SPEED_IDA = 60
local SPEED_VOLTA = 31
local auto1, auto2, instaGrab, aimEnabled = false, false, false, false
local antiRagdollActive = false
local infJumpActive = false
local autoGrabEnabled = false -- 追加: Auto Grab用フラグ

-- 2. コア関数
local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

local function go(pos, speed, cond)
    local r = hrp()
    if not r then return end
    while cond() and (r.Position - pos).Magnitude > 1 do
        local dir = (pos - r.Position).Unit
        r.AssemblyLinearVelocity = Vector3.new(dir.X * speed, r.AssemblyLinearVelocity.Y, dir.Z * speed)
        task.wait()
    end
end

-- 【追加】Auto Grab用関数
local function fireSteal(prompt)
    task.spawn(function()
        local connections = getconnections(prompt.Triggered)
        for _, con in pairs(connections) do
            con:Fire()
        end
        prompt:InputHoldBegin()
        task.wait(1.3) -- STEAL_DURATION
        prompt:InputHoldEnd()
    end)
end

-- 3. UI構築
local C = { bg = Color3.fromRGB(15, 15, 15), gold = Color3.fromRGB(180, 150, 80), text = Color3.fromRGB(255, 255, 255) }
local sg = Instance.new("ScreenGui", lp.PlayerGui); sg.Name = "NEOHUB_TOTO_V4"; sg.ResetOnSpawn = false

local function applyStyle(inst, r)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r or 8)
    local s = Instance.new("UIStroke", inst); s.Thickness = 2; s.Color = C.gold; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if not inst:IsA("TextLabel") then inst.BackgroundColor3 = C.bg end
end

local main = Instance.new("Frame", sg); main.Size = UDim2.new(0, 200, 0, 180); main.Position = UDim2.new(0.8, 0, 0.5, -90); applyStyle(main, 12)

local aimBtn = Instance.new("TextButton", main); aimBtn.Size = UDim2.new(0.43, 0, 0, 35); aimBtn.Position = UDim2.new(0.05, 0, 0.08, 0); aimBtn.Text = "エイム"; aimBtn.TextColor3 = C.gold; applyStyle(aimBtn, 8)
local gearBtn = Instance.new("TextButton", main); gearBtn.Size = UDim2.new(0.43, 0, 0, 35); gearBtn.Position = UDim2.new(0.52, 0, 0.08, 0); gearBtn.Text = "⚙️"; gearBtn.TextColor3 = C.gold; applyStyle(gearBtn, 8)
local leftBtn = Instance.new("TextButton", main); leftBtn.Size = UDim2.new(0.43, 0, 0, 35); leftBtn.Position = UDim2.new(0.05, 0, 0.32, 0); leftBtn.Text = "左"; leftBtn.TextColor3 = C.gold; applyStyle(leftBtn, 8)
local rightBtn = Instance.new("TextButton", main); rightBtn.Size = UDim2.new(0.43, 0, 0, 35); rightBtn.Position = UDim2.new(0.52, 0, 0.32, 0); rightBtn.Text = "右"; rightBtn.TextColor3 = C.gold; applyStyle(rightBtn, 8)
local stopBtn = Instance.new("TextButton", main); stopBtn.Size = UDim2.new(0.9, 0, 0, 30); stopBtn.Position = UDim2.new(0.05, 0, 0.56, 0); stopBtn.Text = "NAVI STOP"; stopBtn.TextColor3 = Color3.fromRGB(200, 50, 50); applyStyle(stopBtn, 8)
local hubOpenBtn = Instance.new("TextButton", main); hubOpenBtn.Size = UDim2.new(0.9, 0, 0, 30); hubOpenBtn.Position = UDim2.new(0.05, 0, 0.78, 0); hubOpenBtn.Text = "OPEN HUB MENU"; hubOpenBtn.TextColor3 = C.gold; applyStyle(hubOpenBtn, 8)

-- 設定/HUBメニュー
local hubMenu = Instance.new("Frame", sg); hubMenu.Size = UDim2.new(0, 180, 0, 160); hubMenu.Position = UDim2.new(0.5, -90, 0.3, 0); hubMenu.Visible = false; applyStyle(hubMenu, 10)
local hubList = Instance.new("UIListLayout", hubMenu); hubList.HorizontalAlignment = Enum.HorizontalAlignment.Center; hubList.Padding = UDim.new(0,5)
local function addToggle(name, callback)
    local b = Instance.new("TextButton", hubMenu); b.Size = UDim2.new(0.9, 0, 0, 35); b.Text = name .. ": OFF"; b.TextColor3 = C.text; applyStyle(b, 6)
    local s = false
    b.MouseButton1Click:Connect(function() s = not s; b.Text = name .. ": " .. (s and "ON" or "OFF"); b.TextColor3 = s and Color3.fromRGB(0, 255, 150) or C.text; callback(s) end)
end

addToggle("Anti Ragdoll", function(v) antiRagdollActive = v end)
addToggle("Infinity Jump", function(v) infJumpActive = v end)
addToggle("Auto Grab", function(v) autoGrabEnabled = v end) -- 追加トグル

hubOpenBtn.MouseButton1Click:Connect(function() hubMenu.Visible = not hubMenu.Visible end)

-- 4. 実行ロジック
UIS.JumpRequest:Connect(function()
    if infJumpActive then
        local r = hrp()
        if r then r.Velocity = Vector3.new(r.Velocity.X, 50, r.Velocity.Z) end
    end
end)

RunService.Heartbeat:Connect(function()
    local r = hrp()
    if not r then return end
    
    -- Anti-Ragdoll (既存)
    if antiRagdollActive then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum and (hum:GetState() == Enum.HumanoidStateType.Physics or hum:GetState() == Enum.HumanoidStateType.Ragdoll) then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    -- Auto Grab 実行
    if autoGrabEnabled then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local dist = (v.Parent:IsA("BasePart") and (v.Parent.Position - r.Position).Magnitude) or 100
                if dist < 20 then -- STEAL_RADIUS
                    fireSteal(v)
                end
            end
        end
    end
end)

-- 移動・エイムボタン接続 (既存通り)
leftBtn.MouseButton1Click:Connect(function()
    if auto1 then return end; auto1 = true
    task.spawn(function()
        go(A1[1], SPEED_IDA, function() return auto1 end)
        go(A1[2], SPEED_IDA, function() return auto1 end); instaGrab = true
        go(A1[3], SPEED_VOLTA, function() return auto1 end); instaGrab = false
        go(A1[4], SPEED_VOLTA, function() return auto1 end); auto1 = false
    end)
end)
rightBtn.MouseButton1Click:Connect(function()
    if auto2 then return end; auto2 = true
    task.spawn(function()
        go(B1[1], SPEED_IDA, function() return auto2 end)
        go(B1[2], SPEED_IDA, function() return auto2 end); instaGrab = true
        go(B1[3], SPEED_VOLTA, function() return auto2 end); instaGrab = false
        go(B1[4], SPEED_VOLTA, function() return auto2 end); auto2 = false
    end)
end)
stopBtn.MouseButton1Click:Connect(function() auto1, auto2, instaGrab = false, false, false end)
aimBtn.MouseButton1Click:Connect(function() aimEnabled = not aimEnabled; aimBtn.BackgroundColor3 = aimEnabled and Color3.fromRGB(0, 100, 0) or C.bg end)
