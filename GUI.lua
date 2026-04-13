local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local LocalPlayer  = Players.LocalPlayer
local function newInst(className, props, parent)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    if parent then inst.Parent = parent end
    return inst
end
local function getHWID()
    if gethwid then
        local ok, v = pcall(gethwid)
        if ok and v and v ~= "" then return v end
    end
    local execName = ""
    if identifyexecutor then
        local ok, v = pcall(identifyexecutor)
        if ok and v then execName = v end
    elseif getexecutorname then
        local ok, v = pcall(getexecutorname)
        if ok and v then execName = v end
    end
    return "P_" .. tostring(LocalPlayer.UserId) .. "_" .. (execName ~= "" and execName or "unknown")
end
local function getKeyFilePath(folderName, serviceId)
    if folderName and folderName ~= "" then
        if isfolder and not isfolder(folderName) then
            pcall(makefolder, folderName)
        end
        return folderName .. "/" .. serviceId .. "_SavedKey.txt"
    end
    return serviceId .. "_SavedKey.txt"
end

local function loadSavedKey(folderName, serviceId)
    if not readfile then return nil end
    local ok, content = pcall(readfile, getKeyFilePath(folderName, serviceId))
    if ok and content and content ~= "" then return content end
    return nil
end

local function saveKey(folderName, serviceId, key)
    if not writefile then return end
    pcall(writefile, getKeyFilePath(folderName, serviceId), key)
end
local KeySystem = {}
KeySystem.__index = KeySystem

function KeySystem.new()
    return setmetatable({
        _showConfig        = {},
        _           = {},
        _validate          = {},
        _getKey            = {},
        _input             = {},
        _built             = false,
        _discordConnected  = false,
        _getKeyConnected   = false,
        _validateConnected = false,
        _inputConnected    = false,
        _screenGui         = nil,
        _mainFrame         = nil,
        _statusLabel       = nil,
        _keyInput          = nil,
        _validateButton    = nil,
        _serviceId         = "",
        _folderName        = "",
        _hwid              = "",
    }, KeySystem)
end

function KeySystem:Show(config)
    self._showConfig = config or {}
    self:_build()
    return self
end

function KeySystem:Discord(config)
    self._discord = config or {}
    if self._built then self:_applyDiscord() end
    return self
end

function KeySystem:Status(msg, r, g, b, clearAfter)
    local color = Color3.fromRGB(r or 150, g or 150, b or 170)
    self:_setStatus(msg, color, clearAfter)
end

function KeySystem:GetKey(config)
    self._getKey = config or {}
    if self._built then self:_applyGetKey() end
    return self
end

function KeySystem:Input(config)
    self._input = config or {}
    if self._built then self:_applyInput() end
    return self
end

function KeySystem:Validate(config)
    self._validate = config or {}
    if self._built then self:_applyValidate() end
    return self
end
function KeySystem:Delete()
    if self._screenGui and self._screenGui.Parent then
        self._screenGui:Destroy()
    end
end
function KeySystem:SuccessGui()
    local screenGui = self._screenGui
    local mainFrame = self._mainFrame
    if not (mainFrame and mainFrame.Parent) then return end

    saveKey(self._folderName, self._serviceId, getgenv().input or "")

    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("GuiObject") then
            TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        end
        if child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        end
    end
    task.wait(0.35)
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UICorner" and child.Name ~= "UIStroke" then
            child:Destroy()
        end
    end
    TweenService:Create(mainFrame, TweenInfo.new(0.4), {
        Size             = UDim2.new(0, 350, 0, 180),
        Position         = UDim2.new(0.5, -175, 0.5, -90),
        BackgroundColor3 = Color3.fromRGB(20, 25, 20),
    }):Play()
    local stroke = mainFrame:FindFirstChildOfClass("UIStroke")
    if stroke then
        TweenService:Create(stroke, TweenInfo.new(0.4), {Color = Color3.fromRGB(60, 150, 80)}):Play()
    end
    task.wait(0.4)
    local SuccessIcon = newInst("TextLabel", {
        Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.5, -30, 0, 25),
        BackgroundTransparency = 1, Text = "✓",
        TextColor3 = Color3.fromRGB(80, 200, 100), TextSize = 48,
        Font = Enum.Font.GothamBold, TextTransparency = 1,
    }, mainFrame)
    local SuccessTitle = newInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 95),
        BackgroundTransparency = 1, Text = "Successfully Authenticated",
        TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18,
        Font = Enum.Font.GothamBold, TextTransparency = 1,
    }, mainFrame)
    local SuccessSubtitle = newInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 125),
        BackgroundTransparency = 1, Text = "Loading your script...",
        TextColor3 = Color3.fromRGB(120, 180, 130), TextSize = 13,
        Font = Enum.Font.Gotham, TextTransparency = 1,
    }, mainFrame)
    TweenService:Create(SuccessIcon, TweenInfo.new(0.4, Enum.EasingStyle.Back), {TextTransparency = 0}):Play()
    task.delay(0.2, function() TweenService:Create(SuccessTitle,    TweenInfo.new(0.3), {TextTransparency = 0}):Play() end)
    task.delay(0.4, function() TweenService:Create(SuccessSubtitle, TweenInfo.new(0.3), {TextTransparency = 0}):Play() end)
    task.wait(2)
    TweenService:Create(mainFrame,       TweenInfo.new(0.4, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
    TweenService:Create(SuccessIcon,     TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(SuccessTitle,    TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(SuccessSubtitle, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    task.wait(0.5)
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end
function KeySystem:_build()
    local cfg        = self._showConfig
    local serviceId  = cfg.ServiceID  or "default"
    local version    = cfg.Version    or "1.0.0"
    local folderName = cfg.FolderName or ""

    self._serviceId  = serviceId
    self._folderName = folderName
    self._hwid       = getHWID()

    pcall(function()
        local ex = CoreGui:FindFirstChild("PandaKeySystem")
        if ex then ex:Destroy() end
    end)

    local ScreenGui = newInst("ScreenGui", {
        Name = "PandaKeySystem", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1001,
    })
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self._screenGui = ScreenGui

    local MainFrame = newInst("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 380, 0, 0),
        Position = UDim2.new(0.5, -190, 0.5, -185),
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BorderSizePixel = 0, BackgroundTransparency = 1,
    }, ScreenGui)
    newInst("UICorner", {CornerRadius = UDim.new(0, 14)}, MainFrame)
    newInst("UIStroke", {Color = Color3.fromRGB(80, 80, 120), Thickness = 1.5, Transparency = 0.3}, MainFrame)
    self._mainFrame = MainFrame

    local HeaderBand = newInst("Frame", {
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35), BorderSizePixel = 0,
    }, MainFrame)
    newInst("UICorner", {CornerRadius = UDim.new(0, 14)}, HeaderBand)
    newInst("Frame", {
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35), BorderSizePixel = 0,
    }, HeaderBand)

    newInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 35), Position = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1, Text = "Panda Key System",
        TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 20,
        Font = Enum.Font.GothamBold,
    }, MainFrame)

    newInst("TextLabel", {
        Size = UDim2.new(1, -30, 0, 30), Position = UDim2.new(0, 15, 0, 48),
        BackgroundTransparency = 1,
        Text = "Enter your license key to unlock premium features",
        TextColor3 = Color3.fromRGB(140, 140, 160), TextSize = 12,
        Font = Enum.Font.Gotham, TextWrapped = true,
    }, MainFrame)

    local InputContainer = newInst("Frame", {
        Size = UDim2.new(1, -40, 0, 45), Position = UDim2.new(0, 20, 0, 95),
        BackgroundColor3 = Color3.fromRGB(25, 25, 32), BorderSizePixel = 0,
    }, MainFrame)
    newInst("UICorner", {CornerRadius = UDim.new(0, 10)}, InputContainer)
    newInst("UIStroke", {Color = Color3.fromRGB(60, 60, 80), Thickness = 1}, InputContainer)

    local KeyInput = newInst("TextBox", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Enter your key here...",
        PlaceholderColor3 = Color3.fromRGB(80, 80, 100),
        TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClipsDescendants = true,
    }, InputContainer)
    self._keyInput = KeyInput

    local Row1 = newInst("Frame", {
        Size = UDim2.new(1, -40, 0, 42), Position = UDim2.new(0, 20, 0, 155),
        BackgroundTransparency = 1,
    }, MainFrame)

    local GetKeyButton = newInst("TextButton", {
        Size = UDim2.new(0.48, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(60, 60, 85), BorderSizePixel = 0,
        Text = "Get Key", TextColor3 = Color3.fromRGB(200, 200, 220),
        TextSize = 14, Font = Enum.Font.GothamBold,
    }, Row1)
    newInst("UICorner", {CornerRadius = UDim.new(0, 10)}, GetKeyButton)
    self._getKeyButton = GetKeyButton

    local ValidateButton = newInst("TextButton", {
        Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(70, 130, 180), BorderSizePixel = 0,
        Text = "Validate", TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14, Font = Enum.Font.GothamBold,
    }, Row1)
    newInst("UICorner", {CornerRadius = UDim.new(0, 10)}, ValidateButton)
    self._validateButton = ValidateButton

    local Row2 = newInst("Frame", {
        Size = UDim2.new(1, -40, 0, 42), Position = UDim2.new(0, 20, 0, 205),
        BackgroundTransparency = 1,
    }, MainFrame)

    local DiscordButton = newInst("TextButton", {
        Size = UDim2.new(0.48, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(88, 101, 242), BorderSizePixel = 0,
        Text = "Join Discord", TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14, Font = Enum.Font.GothamBold,
    }, Row2)
    newInst("UICorner", {CornerRadius = UDim.new(0, 10)}, DiscordButton)
    self._discordButton = DiscordButton

    local CloseButton = newInst("TextButton", {
        Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(180, 60, 60), BorderSizePixel = 0,
        Text = "Close Script", TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14, Font = Enum.Font.GothamBold,
    }, Row2)
    newInst("UICorner", {CornerRadius = UDim.new(0, 10)}, CloseButton)

    local StatusLabel = newInst("TextLabel", {
        Size = UDim2.new(1, -40, 0, 25), Position = UDim2.new(0, 20, 0, 255),
        BackgroundTransparency = 1, Text = "",
        TextColor3 = Color3.fromRGB(150, 150, 170), TextSize = 12,
        Font = Enum.Font.Gotham, TextWrapped = true,
    }, MainFrame)
    self._statusLabel = StatusLabel

    local Bottom = newInst("Frame", {
        Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 1, -30),
        BackgroundTransparency = 1,
    }, MainFrame)
    newInst("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1,
        Text = "HWID: " .. string.sub(self._hwid, 1, 20) .. "...",
        TextColor3 = Color3.fromRGB(80, 80, 100), TextSize = 10,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
    }, Bottom)
    newInst("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
        BackgroundTransparency = 1, Text = "v" .. version,
        TextColor3 = Color3.fromRGB(80, 80, 100), TextSize = 10,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right,
    }, Bottom)

    local function addHover(btn, normal, hover)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hover}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
        end)
    end
    addHover(GetKeyButton,  Color3.fromRGB(60, 60, 85),  Color3.fromRGB(80, 80, 110))
    addHover(ValidateButton,Color3.fromRGB(70, 130, 180), Color3.fromRGB(90, 150, 200))
    addHover(DiscordButton, Color3.fromRGB(88, 101, 242), Color3.fromRGB(108, 121, 255))
    addHover(CloseButton,   Color3.fromRGB(180, 60, 60),  Color3.fromRGB(200, 80, 80))

    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 380, 0, 370),
        BackgroundTransparency = 0,
    }):Play()

    CloseButton.MouseButton1Click:Connect(function()
        if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
    end)

    local savedKey = loadSavedKey(folderName, serviceId)
    if savedKey then
        KeyInput.Text    = savedKey
        getgenv().input  = savedKey
        self:_setStatus("Key loaded from saved file", Color3.fromRGB(100, 180, 255), 2)
    end

    self._built = true
    self:_applyDiscord()
    self:_applyGetKey()
    self:_applyInput()
    self:_applyValidate()
end
function KeySystem:_setStatus(msg, color, clearAfter)
    local lbl = self._statusLabel
    if not (lbl and lbl.Parent) then return end
    lbl.Text       = msg
    lbl.TextColor3 = color or Color3.fromRGB(150, 150, 170)
    if clearAfter then
        task.delay(clearAfter, function()
            if lbl and lbl.Parent then lbl.Text = "" end
        end)
    end
end
function KeySystem:_apply()
    local btn = self._Button
    if not btn then return end
    local cfg = self._ or {}
    if cfg.Title and cfg.Title ~= "" then btn.Text = cfg.Title end
    if self._Connected then return end
    self._Connected = true
    btn.MouseButton1Click:Connect(function()
        local cb = (self._ or {}).Callback
        if cb then task.spawn(cb) end
    end)
end
function KeySystem:_applyGetKey()
    local btn = self._getKeyButton
    if not btn then return end
    local cfg = self._getKey or {}
    if cfg.Title and cfg.Title ~= "" then btn.Text = cfg.Title end
    if self._getKeyConnected then return end
    self._getKeyConnected = true
    btn.MouseButton1Click:Connect(function()
        local cb = (self._getKey or {}).Callback
        if cb then task.spawn(cb) end
    end)
end
function KeySystem:_applyInput()
    local keyInput = self._keyInput
    if not keyInput then return end
    local cfg = self._input or {}
    if cfg.Title and cfg.Title ~= "" then
        keyInput.PlaceholderText = cfg.Title
    end
    if self._inputConnected then return end
    self._inputConnected = true
    keyInput:GetPropertyChangedSignal("Text"):Connect(function()
        local cb = (self._input or {}).Callback
        if cb then task.spawn(function() cb(keyInput.Text) end) end
    end)
end
function KeySystem:_applyValidate()
    local btn = self._validateButton
    if not btn then return end
    local cfg = self._validate or {}
    if cfg.Title and cfg.Title ~= "" then btn.Text = cfg.Title end
    if self._validateConnected then return end
    self._validateConnected = true

    local function doValidate()
        local validateCfg = self._validate or {}
        local btnTitle    = (validateCfg.Title and validateCfg.Title ~= "") and validateCfg.Title or "Validate"
        btn.Text             = "..."
        btn.BackgroundColor3 = Color3.fromRGB(50, 100, 140)
        task.spawn(function()
            local cb = validateCfg.Callback
            if cb then cb() end
            btn.Text             = btnTitle
            btn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        end)
    end

    btn.MouseButton1Click:Connect(doValidate)
    local keyInput = self._keyInput
    if keyInput then
        keyInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then doValidate() end
        end)
    end
end

return KeySystem.new()
