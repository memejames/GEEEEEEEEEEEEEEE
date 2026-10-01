local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local guiname = "PurgeKeySystem"
local windowwidth = 380
local windowheight = 390
local successwidth = 350
local successheight = 180

local Theme = {
    WindowBackground = Color3.fromRGB(15, 15, 20),
    WindowBorder = Color3.fromRGB(80, 80, 120),
    HeaderBackground = Color3.fromRGB(25, 25, 35),

    InputBackground = Color3.fromRGB(25, 25, 32),
    InputBorder = Color3.fromRGB(60, 60, 80),
    InputPlaceholder = Color3.fromRGB(80, 80, 100),

    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(140, 140, 160),
    TextMuted = Color3.fromRGB(80, 80, 100),
    TextStatus = Color3.fromRGB(150, 150, 170),
    TextButtonMuted = Color3.fromRGB(200, 200, 220),

    GetKey = Color3.fromRGB(60, 60, 85),
    GetKeyHover = Color3.fromRGB(80, 80, 110),
    Validate = Color3.fromRGB(70, 130, 180),
    ValidateHover = Color3.fromRGB(90, 150, 200),
    ValidateBusy = Color3.fromRGB(50, 100, 140),
    Discord = Color3.fromRGB(88, 101, 242),
    DiscordHover = Color3.fromRGB(108, 121, 255),
    Close = Color3.fromRGB(180, 60, 60),
    CloseHover = Color3.fromRGB(200, 80, 80),

    StatusInfo = Color3.fromRGB(100, 180, 255),
    SuccessBackground = Color3.fromRGB(20, 25, 20),
    SuccessBorder = Color3.fromRGB(60, 150, 80),
    SuccessIcon = Color3.fromRGB(80, 200, 100),
    SuccessSubtitle = Color3.fromRGB(120, 180, 130),
}

local function createInstance(className, properties, parent)
    local instance = Instance.new(className)

    if properties then
        for property, value in pairs(properties) do
            pcall(function()
                instance[property] = value
            end)
        end
    end

    if parent then
        instance.Parent = parent
    end

    return instance
end

local function addCorner(parent, radius)
    return createInstance("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function addStroke(parent, color, thickness, transparency)
    return createInstance("UIStroke", {
        Color = color,
        Thickness = thickness,
        Transparency = transparency or 0,
    }, parent)
end

local function tween(instance, duration, goal, easingStyle, easingDirection)
    local info = TweenInfo.new(
        duration,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local animation = TweenService:Create(instance, info, goal)
    animation:Play()
    return animation
end

local function addHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = hoverColor })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = normalColor })
    end)
end

local function getExecutorName()
    local getter = identifyexecutor or getexecutorname
    if getter then
        local success, name = pcall(getter)
        if success and name then
            return name
        end
    end
    return "unknown"
end

local function getHardwareId()
    if gethwid then
        local success, hwid = pcall(gethwid)
        if success and hwid and hwid ~= "" then
            return hwid
        end
    end
    return "P_" .. tostring(LocalPlayer.UserId) .. "_" .. getExecutorName()
end

local function getSavedKeyPath(folderName, serviceId)
    local fileName = serviceId .. "_SavedKey.txt"

    if folderName and folderName ~= "" then
        if isfolder and not isfolder(folderName) then
            pcall(makefolder, folderName)
        end
        return folderName .. "/" .. fileName
    end

    return fileName
end

local function loadSavedKey(folderName, serviceId)
    if not readfile then
        return nil
    end

    local success, content = pcall(readfile, getSavedKeyPath(folderName, serviceId))
    if success and content and content ~= "" then
        return content
    end

    return nil
end

local function saveKey(folderName, serviceId, key)
    if not writefile then
        return
    end

    pcall(writefile, getSavedKeyPath(folderName, serviceId), key)
end

local KeySystem = {}
KeySystem.__index = KeySystem

function KeySystem.new()
    return setmetatable({
        _showConfig = {},
        _discordConfig = {},
        _getKeyConfig = {},
        _inputConfig = {},
        _validateConfig = {},

        _isBuilt = false,
        _isDiscordBound = false,
        _isGetKeyBound = false,
        _isInputBound = false,
        _isValidateBound = false,

        _serviceId = "",
        _folderName = "",
        _hwid = "",

        _screenGui = nil,
        _mainFrame = nil,
        _statusLabel = nil,
        _keyTextBox = nil,
        _getKeyButton = nil,
        _validateButton = nil,
        _discordButton = nil,
    }, KeySystem)
end

function KeySystem:Show(config)
    self._showConfig = config or {}
    self:_build()
    return self
end

function KeySystem:Discord(config)
    self._discordConfig = config or {}
    if self._isBuilt then
        self:_bindDiscordButton()
    end
    return self
end

function KeySystem:GetKey(config)
    self._getKeyConfig = config or {}
    if self._isBuilt then
        self:_bindGetKeyButton()
    end
    return self
end

function KeySystem:Input(config)
    self._inputConfig = config or {}
    if self._isBuilt then
        self:_bindKeyTextBox()
    end
    return self
end

function KeySystem:Validate(config)
    self._validateConfig = config or {}
    if self._isBuilt then
        self:_bindValidateButton()
    end
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

    if not (mainFrame and mainFrame.Parent) then
        return
    end

    saveKey(self._folderName, self._serviceId, getgenv().input or "")

    for _, child in ipairs(mainFrame:GetDescendants()) do
        if child:IsA("GuiObject") then
            tween(child, 0.3, { BackgroundTransparency = 1 })
        end
        if child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("TextButton") then
            tween(child, 0.3, { TextTransparency = 1 })
        end
        if child:IsA("ImageLabel") then
            tween(child, 0.3, { ImageTransparency = 1 })
        end
        if child:IsA("UIStroke") and child.Parent ~= mainFrame then
            tween(child, 0.3, { Transparency = 1 })
        end
    end
    task.wait(0.35)

    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UICorner" and child.Name ~= "UIStroke" then
            child:Destroy()
        end
    end

    tween(mainFrame, 0.4, {
        Size = UDim2.new(0, successwidth, 0, successheight),
        Position = UDim2.new(0.5, -successwidth / 2, 0.5, -successheight / 2),
        BackgroundColor3 = Theme.SuccessBackground,
    })

    local stroke = mainFrame:FindFirstChildOfClass("UIStroke")
    if stroke then
        tween(stroke, 0.4, { Color = Theme.SuccessBorder })
    end
    task.wait(0.4)

    local checkIcon = createInstance("TextLabel", {
        Size = UDim2.new(0, 60, 0, 60),
        Position = UDim2.new(0.5, -30, 0, 25),
        BackgroundTransparency = 1,
        Text = "✓",
        TextColor3 = Theme.SuccessIcon,
        TextSize = 48,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
    }, mainFrame)

    local titleLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 95),
        BackgroundTransparency = 1,
        Text = "Successfully Authenticated",
        TextColor3 = Theme.TextPrimary,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
    }, mainFrame)

    local subtitleLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 125),
        BackgroundTransparency = 1,
        Text = "Loading your script...",
        TextColor3 = Theme.SuccessSubtitle,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextTransparency = 1,
    }, mainFrame)

    tween(checkIcon, 0.4, { TextTransparency = 0 }, Enum.EasingStyle.Back)
    task.delay(0.2, function()
        tween(titleLabel, 0.3, { TextTransparency = 0 })
    end)
    task.delay(0.4, function()
        tween(subtitleLabel, 0.3, { TextTransparency = 0 })
    end)

    task.wait(2)

    tween(mainFrame, 0.4, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart)
    tween(checkIcon, 0.3, { TextTransparency = 1 })
    tween(titleLabel, 0.3, { TextTransparency = 1 })
    tween(subtitleLabel, 0.3, { TextTransparency = 1 })
    task.wait(0.5)

    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end

function KeySystem:_build()
    local config = self._showConfig
    local serviceId = config.ServiceID or "default"
    local version = config.Version or "1.0.0"
    local folderName = config.FolderName or ""

    self._serviceId = serviceId
    self._folderName = folderName
    self._hwid = getHardwareId()

    pcall(function()
        local existing = CoreGui:FindFirstChild(guiname)
        if existing then
            existing:Destroy()
        end
    end)

    local screenGui = createInstance("ScreenGui", {
        Name = guiname,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1001,
    })

    pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self._screenGui = screenGui

    local mainFrame = createInstance("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, windowwidth, 0, 0),
        Position = UDim2.new(0.5, -windowwidth / 2, 0.5, -windowheight / 2),
        BackgroundColor3 = Theme.WindowBackground,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, screenGui)
    addCorner(mainFrame, 14)
    addStroke(mainFrame, Theme.WindowBorder, 1.5, 0.3)
    self._mainFrame = mainFrame

    self:_buildHeader(mainFrame)
    self:_buildKeyInput(mainFrame)
    self:_buildButtons(mainFrame)
    self:_buildStatusLabel(mainFrame)
    self:_buildGameIcon(mainFrame)
    self:_buildFooter(mainFrame, version)

    tween(mainFrame, 0.5, {
        Size = UDim2.new(0, windowwidth, 0, windowheight),
        BackgroundTransparency = 0,
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local savedKey = loadSavedKey(folderName, serviceId)
    if savedKey then
        self._keyTextBox.Text = savedKey
        getgenv().input = savedKey
        self:_setStatus("Key loaded from saved file", Theme.StatusInfo, 2)
    end

    self._isBuilt = true
    self:_bindDiscordButton()
    self:_bindGetKeyButton()
    self:_bindKeyTextBox()
    self:_bindValidateButton()
end

function KeySystem:_buildHeader(mainFrame)
    local headerBand = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = Theme.HeaderBackground,
        BorderSizePixel = 0,
    }, mainFrame)
    addCorner(headerBand, 14)

    createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -20),
        BackgroundColor3 = Theme.HeaderBackground,
        BorderSizePixel = 0,
    }, headerBand)

    createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1,
        Text = "Purge Key System",
        TextColor3 = Theme.TextPrimary,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
    }, mainFrame)

    createInstance("TextLabel", {
        Size = UDim2.new(1, -30, 0, 30),
        Position = UDim2.new(0, 15, 0, 48),
        BackgroundTransparency = 1,
        Text = "Enter your license key to unlock Script",
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
    }, mainFrame)
end

function KeySystem:_buildKeyInput(mainFrame)
    local inputContainer = createInstance("Frame", {
        Size = UDim2.new(1, -40, 0, 45),
        Position = UDim2.new(0, 20, 0, 95),
        BackgroundColor3 = Theme.InputBackground,
        BorderSizePixel = 0,
    }, mainFrame)
    addCorner(inputContainer, 10)
    local stroke = addStroke(inputContainer, Theme.InputBorder, 1)

    self._keyTextBox = createInstance("TextBox", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Enter your key here...",
        PlaceholderColor3 = Theme.InputPlaceholder,
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
    }, inputContainer)

    self._keyTextBox.Focused:Connect(function()
        tween(stroke, 0.15, { Color = Theme.Validate })
    end)
    self._keyTextBox.FocusLost:Connect(function()
        tween(stroke, 0.15, { Color = Theme.InputBorder })
    end)
end

function KeySystem:_buildButtons(mainFrame)
    local function createRow(positionY)
        return createInstance("Frame", {
            Size = UDim2.new(1, -40, 0, 42),
            Position = UDim2.new(0, 20, 0, positionY),
            BackgroundTransparency = 1,
        }, mainFrame)
    end

    local function createButton(parent, text, backgroundColor, textColor, hoverColor, positionX)
        local button = createInstance("TextButton", {
            Size = UDim2.new(0.48, 0, 1, 0),
            Position = UDim2.new(positionX or 0, 0, 0, 0),
            BackgroundColor3 = backgroundColor,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = textColor,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
        }, parent)
        addCorner(button, 10)
        addHoverEffect(button, backgroundColor, hoverColor)
        return button
    end

    local topRow = createRow(155)
    local bottomRow = createRow(205)

    self._getKeyButton = createButton(
        topRow, "Get Key",
        Theme.GetKey, Theme.TextButtonMuted, Theme.GetKeyHover
    )
    self._validateButton = createButton(
        topRow, "Validate",
        Theme.Validate, Theme.TextPrimary, Theme.ValidateHover, 0.52
    )
    self._discordButton = createButton(
        bottomRow, "Join Discord",
        Theme.Discord, Theme.TextPrimary, Theme.DiscordHover
    )

    local closeButton = createButton(
        bottomRow, "Close Script",
        Theme.Close, Theme.TextPrimary, Theme.CloseHover, 0.52
    )
    closeButton.MouseButton1Click:Connect(function()
        self:Delete()
    end)
end

function KeySystem:_buildStatusLabel(mainFrame)
    self._statusLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, -40, 0, 25),
        Position = UDim2.new(0, 20, 0, 255),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.TextStatus,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
    }, mainFrame)
end

function KeySystem:_buildGameIcon(mainFrame)
    local container = createInstance("Frame", {
        Name = "GameCard",
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 20, 0, 286),
        BackgroundColor3 = Theme.InputBackground,
        BorderSizePixel = 0,
    }, mainFrame)
    addCorner(container, 10)
    addStroke(container, Theme.InputBorder, 1)

    local icon = createInstance("ImageLabel", {
        Name = "GameIcon",
        Size = UDim2.new(0, 38, 0, 38),
        Position = UDim2.new(0, 6, 0.5, -19),
        BackgroundColor3 = Theme.HeaderBackground,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150",
        ScaleType = Enum.ScaleType.Crop,
    }, container)
    addCorner(icon, 8)

    local titleLabel = createInstance("TextLabel", {
        Name = "GameTitle",
        Size = UDim2.new(1, -56, 0, 18),
        Position = UDim2.new(0, 50, 0, 7),
        BackgroundTransparency = 1,
        Text = "Loading...",
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)

    local detailsLabel = createInstance("TextLabel", {
        Name = "GameDetails",
        Size = UDim2.new(1, -56, 0, 16),
        Position = UDim2.new(0, 50, 0, 25),
        BackgroundTransparency = 1,
        Text = "Place ID: " .. tostring(game.PlaceId),
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, container)

    task.spawn(function()
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if success and info and info.Name and titleLabel.Parent then
            titleLabel.Text = info.Name
        else
            titleLabel.Text = game.Name ~= "" and game.Name or "Unknown Game"
        end
    end)
end

function KeySystem:_buildFooter(mainFrame, version)
    local footer = createInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 1, -30),
        BackgroundTransparency = 1,
    }, mainFrame)

    createInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "HWID: " .. string.sub(self._hwid, 1, 20) .. "...",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, footer)

    createInstance("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "v" .. version,
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, footer)
end

function KeySystem:_setStatus(message, color, clearAfterSeconds)
    local label = self._statusLabel
    if not (label and label.Parent) then
        return
    end

    label.Text = message
    label.TextColor3 = color or Theme.TextStatus

    if clearAfterSeconds then
        task.delay(clearAfterSeconds, function()
            if label and label.Parent then
                label.Text = ""
            end
        end)
    end
end

function KeySystem:_bindDiscordButton()
    local button = self._discordButton
    if not button then
        return
    end

    local title = self._discordConfig.Title
    if title and title ~= "" then
        button.Text = title
    end

    if self._isDiscordBound then
        return
    end
    self._isDiscordBound = true

    button.MouseButton1Click:Connect(function()
        local callback = self._discordConfig.Callback
        if callback then
            task.spawn(callback)
        end
    end)
end

function KeySystem:_bindGetKeyButton()
    local button = self._getKeyButton
    if not button then
        return
    end

    local title = self._getKeyConfig.Title
    if title and title ~= "" then
        button.Text = title
    end

    if self._isGetKeyBound then
        return
    end
    self._isGetKeyBound = true

    button.MouseButton1Click:Connect(function()
        local callback = self._getKeyConfig.Callback
        if callback then
            task.spawn(callback)
        end
    end)
end

function KeySystem:_bindKeyTextBox()
    local textBox = self._keyTextBox
    if not textBox then
        return
    end

    local title = self._inputConfig.Title
    if title and title ~= "" then
        textBox.PlaceholderText = title
    end

    if self._isInputBound then
        return
    end
    self._isInputBound = true

    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local callback = self._inputConfig.Callback
        if callback then
            task.spawn(callback, textBox.Text)
        end
    end)
end

function KeySystem:_bindValidateButton()
    local button = self._validateButton
    if not button then
        return
    end

    local title = self._validateConfig.Title
    if title and title ~= "" then
        button.Text = title
    end

    if self._isValidateBound then
        return
    end
    self._isValidateBound = true

    local function runValidation()
        local config = self._validateConfig
        local idleText = (config.Title and config.Title ~= "") and config.Title or "Validate"

        button.Text = "..."
        button.BackgroundColor3 = Theme.ValidateBusy

        task.spawn(function()
            if config.Callback then
                config.Callback()
            end

            button.Text = idleText
            button.BackgroundColor3 = Theme.Validate
        end)
    end

    button.MouseButton1Click:Connect(runValidation)

    self._keyTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            runValidation()
        end
    end)
end

return KeySystem.new()
