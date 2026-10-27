local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local vim = game:GetService("VirtualInputManager")
local vu = game:GetService("VirtualUser")

player.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

task.spawn(function()
    while true do
        task.wait(300)
        pcall(function()
            vim:SendKeyEvent(true, Enum.KeyCode.Unknown, false, game)
            task.wait(0.1)
            vim:SendKeyEvent(false, Enum.KeyCode.Unknown, false, game)
        end)
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RGBTeleportUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 90)
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Parent = frame

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 25, 0, 25)
minimizeButton.Position = UDim2.new(1, -30, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 14
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.Text = "-"
minimizeButton.Parent = frame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "Status: Ready"
statusLabel.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Text = "START"
toggleButton.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

task.spawn(function()
    while true do
        local hue = tick() % 5 / 5
        local rgbColor = Color3.fromHSV(hue, 1, 1)
        stroke.Color = rgbColor
        task.wait(0.1)
    end
end)

local isMinimized = false
minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    statusLabel.Visible = not isMinimized
    toggleButton.Visible = not isMinimized
    frame.Size = isMinimized and UDim2.new(0, 240, 0, 35) or UDim2.new(0, 240, 0, 90)
    minimizeButton.Text = isMinimized and "+" or "-"
end)

local isRunning = false
local savedFolderIndex = 1
local savedItemIndex = 1

local function checkDeveloper()
    local creatorId = game.CreatorId
    local creatorType = game.CreatorType
    
    if creatorType == Enum.CreatorType.User then
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.UserId == creatorId then
                return true, p.Name
            end
        end
    elseif creatorType == Enum.CreatorType.Group then
        for _, p in ipairs(game.Players:GetPlayers()) do
            local success, rank = pcall(function()
                return p:GetRankInGroup(creatorId)
            end)
            if success and rank >= 254 then
                return true, p.Name
            end
        end
    end
    return false, ""
end

toggleButton.MouseButton1Click:Connect(function()
    local found, devName = checkDeveloper()
    if found and not isRunning then
        statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        statusLabel.Text = "Dev (" .. devName .. ") Found! Cannot Start"
        return
    end

    isRunning = not isRunning
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    if isRunning then
        toggleButton.Text = "STOP"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusLabel.Text = "Status: Running..."
    else
        toggleButton.Text = "START"
        toggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        statusLabel.Text = "Status: Paused"
    end
end)

task.spawn(function()
    while true do
        if isRunning then
            local found, devName = checkDeveloper()
            if found then
                statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                statusLabel.Text = "Dev (" .. devName .. ") Joined! Waiting..."
                while found and isRunning do
                    task.wait(2)
                    found, _ = checkDeveloper()
                end
                if isRunning then
                    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    statusLabel.Text = "Dev Left! Resuming..."
                    task.wait(1)
                end
            end

            if not isRunning then 
                task.wait(0.5)
                continue 
            end

            local allFolders = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "CaramelosEvento" then
                    table.insert(allFolders, obj)
                end
            end

            if #allFolders == 0 then
                statusLabel.Text = "Searching folders..."
                task.wait(3)
            else
                for folderIndex = savedFolderIndex, #allFolders do
                    if not isRunning then break end
                    
                    local foundNow, _ = checkDeveloper()
                    if foundNow then break end 

                    savedFolderIndex = folderIndex
                    
                    local folder = allFolders[folderIndex]
                    local items = folder:GetDescendants()
                    
                    for i = savedItemIndex, #items do
                        if not isRunning then break end
                        
                        local foundItemNow, _ = checkDeveloper()
                        if foundItemNow then break end 

                        savedItemIndex = i
                        
                        local target = items[i]
                        local targetPart = nil
                        
                        if target then
                            if target:IsA("BasePart") then
                                targetPart = target
                            elseif target:IsA("Model") then
                                targetPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
                            end
                        end
                        
                        if targetPart then
                            statusLabel.Text = "F:" .. folderIndex .. " | Item: " .. i .. "/" .. #items
                            
                            local tweenInfo = TweenInfo.new(
                                0.3,
                                Enum.EasingStyle.Linear,
                                Enum.EasingDirection.Out
                            )
                            
                            local tween = tweenService:Create(humanoidRootPart, tweenInfo, {
                                CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                            })
                            
                            tween:Play()
                            tween.Completed:Wait()
                            
                            task.wait(1.2)
                        end
                    end
                    
                    if isRunning and savedFolderIndex < #allFolders then
                        savedItemIndex = 1
                    end
                end

                if isRunning then
                    local foundEnd, _ = checkDeveloper()
                    if not foundEnd then
                        savedFolderIndex = 1
                        savedItemIndex = 1
                        statusLabel.Text = "Rescanning items..."
                        task.wait(2)
                    end
                end
            end
        else
            task.wait(0.5)
        end
    end
end)
