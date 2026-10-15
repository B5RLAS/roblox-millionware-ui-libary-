local cloneref = (typeof(cloneref) == "function" and cloneref) or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TextService = cloneref(game:GetService("TextService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local GuiService = cloneref(game:GetService("GuiService"))

local function getMouse()
    local m = UserInputService:GetMouseLocation()
    local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
    if ok and inset then m = m - inset end
    return m
end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local ENV = (typeof(getgenv) == "function" and getgenv()) or _G
if ENV.__MILLIONWARE_SLATE then
    pcall(function() ENV.__MILLIONWARE_SLATE:Destroy() end)
    ENV.__MILLIONWARE_SLATE = nil
end

local GUI_NAME = "millionware_slate"

local function resolveGuiParent()
    if typeof(gethui) == "function" then
        local ok, holder = pcall(gethui)
        if ok and typeof(holder) == "Instance" then return holder end
    end
    local ok = pcall(function()
        local probe = Instance.new("ScreenGui")
        probe.Parent = CoreGui
        probe:Destroy()
    end)
    if ok then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local GUI_PARENT = resolveGuiParent()
do
    local old = GUI_PARENT:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end

local function rgba(r, g, b, a) return { r / 255, g / 255, b / 255, a or 1 } end

local Theme = {
    scheme    = rgba(195, 129, 133, 1),
    text      = rgba(234, 234, 234, 1),
    text2     = rgba(234, 234, 234, 0.70),
    text3     = rgba(234, 234, 234, 0.40),
    bg        = rgba(14, 14, 14, 1),
    bg2       = rgba(17, 17, 17, 1),
    bg3       = rgba(17, 17, 17, 1),
    bg4       = rgba(27, 27, 27, 1),
    border    = rgba(0, 0, 0, 1),
    tab       = rgba(22, 22, 22, 1),
    separator = rgba(255, 255, 255, 0.04),
}

local Colors = {}
for k, v in pairs(Theme) do Colors[k] = { v[1], v[2], v[3], v[4] } end

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local function mix(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t, a[4] + (b[4] - a[4]) * t }
end
local function fade(c, a) return { c[1], c[2], c[3], c[4] * a } end
local function c3(c) return Color3.new(c[1], c[2], c[3]) end

local function setBg(o, c)
    local col, tr = c3(c), 1 - c[4]
    if o.BackgroundColor3 ~= col then o.BackgroundColor3 = col end
    if o.BackgroundTransparency ~= tr then o.BackgroundTransparency = tr end
end
local function setText(o, c)
    local col, tr = c3(c), 1 - c[4]
    if o.TextColor3 ~= col then o.TextColor3 = col end
    if o.TextTransparency ~= tr then o.TextTransparency = tr end
end

local SPEED = 17
local function lerp(a, b, dt, speed)
    local t = dt * (speed or SPEED)
    if t > 1 then t = 1 end
    return a + (b - a) * t
end
local function anim(v, cond, dt) return lerp(v, cond and 1 or 0, dt) end

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end
local function trunc(x)
    if x >= 0 then return math.floor(x) end
    return math.ceil(x)
end

local INTER_ID = 12187365364
local FONT_MEDIUM, FONT_SEMI
do
    local ok1, f1 = pcall(Font.fromId, INTER_ID, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    local ok2, f2 = pcall(Font.fromId, INTER_ID, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    FONT_MEDIUM = (ok1 and f1) or Font.fromEnum(Enum.Font.GothamMedium)
    FONT_SEMI   = (ok2 and f2) or Font.fromEnum(Enum.Font.GothamBold)
end

local function textWidth(str, size)
    local ok, v = pcall(function()
        return TextService:GetTextSize(str, size or 13, Enum.Font.GothamMedium, Vector2.new(10000, 10000)).X
    end)
    if ok then return v end
    return #str * 7
end

local function create(class, props)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end

    pcall(function() o.AutoLocalize = false end)
    local parent = props.Parent
    for k, v in pairs(props) do
        if k ~= "Parent" then o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(parent, r)
    return create("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
end

local function inset(frame)

    frame.BorderMode = Enum.BorderMode.Inset
    frame.BorderSizePixel = 1
    frame.BorderColor3 = BLACK
    return frame
end

local function label(parent, text, props)
    local o = create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        TextColor3 = c3(Theme.text),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = false,
        TextWrapped = false,
        Size = UDim2.fromOffset(200, 16),
        Parent = parent,
    })
    if props then for k, v in pairs(props) do o[k] = v end end

    local size = o.Size
    local minHeight = (o.TextSize >= 13) and 16 or 14
    if size.Y.Scale == 0 and size.Y.Offset < minHeight then
        local delta = minHeight - size.Y.Offset
        local pos = o.Position
        o.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - delta / 2)
        o.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, minHeight)
    end
    return o
end

local function hitbox(parent, size, pos, z)
    return create("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Selectable = false,
        Size = size, Position = pos or UDim2.new(), ZIndex = z or 1, Parent = parent,
    })
end

local function shine(parent, alphaTop)
    local f = create("Frame", {
        Name = "Gradient", BackgroundColor3 = WHITE, BackgroundTransparency = 0,
        Size = UDim2.fromScale(1, 1), Parent = parent,
    })
    local g = create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1 - alphaTop, 1), Parent = f })
    return f, g
end

local function arrow(parent)
    local holder = create("Frame", { Name = "Arrow", BackgroundTransparency = 1, Size = UDim2.fromOffset(7, 6), Parent = parent })
    local widths = { 7, 5, 3, 1 }
    for i, w in ipairs(widths) do
        create("Frame", {
            BackgroundColor3 = c3(Theme.text2), BackgroundTransparency = 1 - Theme.text2[4],
            Size = UDim2.fromOffset(w, 1.5), Position = UDim2.fromOffset((7 - w) / 2, (i - 1) * 1.5),
            Parent = holder,
        })
    end
    return holder
end

local function trimLabel(s)
    s = tostring(s)
    local i = s:find("##", 1, true)
    if i then return s:sub(1, i - 1) end
    return s
end

local function fire(cb, ...)
    if typeof(cb) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(args, 1, args.n))
        if not ok then warn("[millionware] callback error: " .. tostring(err)) end
    end)
end

local function inside(o, m)
    local p, s = o.AbsolutePosition, o.AbsoluteSize
    return m.X >= p.X and m.Y >= p.Y and m.X < p.X + s.X and m.Y < p.Y + s.Y
end

local KEYNAMES = {
    MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3",
    Backspace = "BACK", Tab = "TAB", Return = "ENT", KeypadEnter = "ENT",
    LeftShift = "SHIFT", RightShift = "SHIFT", LeftControl = "CTRL", RightControl = "CTRL",
    LeftAlt = "ALT", RightAlt = "ALT", Pause = "PAUSE", CapsLock = "CAPS", Space = "SPACE",
    PageUp = "PGU", PageDown = "PGD", End = "END", Home = "HOME",
    Left = "LEFT", Up = "UP", Right = "RIGH", Down = "DOWN",
    Print = "PRINT", Insert = "INS", Delete = "DEL", Help = "HEL",
    Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
    KeypadZero = "NUM0", KeypadOne = "NUM1", KeypadTwo = "NUM2", KeypadThree = "NUM3", KeypadFour = "NUM4",
    KeypadFive = "NUM5", KeypadSix = "NUM6", KeypadSeven = "NUM7", KeypadEight = "NUM8", KeypadNine = "NUM9",
    KeypadMultiply = "*", KeypadPlus = "+", KeypadMinus = "-", KeypadPeriod = ".", KeypadDivide = "/",
    LeftSuper = "WIN", RightSuper = "WIN", Menu = "APP", NumLock = "NUMLOCK", ScrollLock = "SCR", Equals = "=",
}
for c = string.byte("A"), string.byte("Z") do KEYNAMES[string.char(c)] = string.char(c) end
for i = 1, 24 do KEYNAMES["F" .. i] = "F" .. i end

local function keyName(key)
    if key == nil then return "NONE" end
    return KEYNAMES[key.Name] or "NONE"
end

local library = {
    Flags = {},
    Tabs = {},
    Connections = {},
    ToggleKey = Enum.KeyCode.J,
    Theme = Theme,
}
local Flags = library.Flags

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(library.Connections, c)
    return c
end

local gui = create("ScreenGui", {
    Name = GUI_NAME, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then pcall(syn.protect_gui, gui) end
gui.Parent = GUI_PARENT
library.Gui = gui

local MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT = 740, 532
local windowWidth, windowHeight = MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT
local window = create("Frame", {
    Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(windowWidth, windowHeight), BackgroundColor3 = c3(Theme.bg), Active = true, Parent = gui,
})
library.Window = window
local uiscale = create("UIScale", { Scale = 1, Parent = window })

local modal = create("TextButton", {
    Name = "Modal", Text = "", Modal = true, BackgroundTransparency = 1,
    Size = UDim2.fromOffset(0, 0), Parent = window,
})

local function fitToScreen()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    uiscale.Scale = math.max(0.35, math.min(1, (vp.X - 20) / MIN_WINDOW_WIDTH, (vp.Y - 20) / MIN_WINDOW_HEIGHT))
end
fitToScreen()
do
    local camConn
    local function watch()
        if camConn then camConn:Disconnect() end
        local cam = workspace.CurrentCamera
        if cam then
            camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)
            table.insert(library.Connections, camConn)
        end
        fitToScreen()
    end
    watch()
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watch)
end

local topStrip = create("Frame", { Name = "TopStrip", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 31), Parent = window })
shine(topStrip, 0.03)

local main = inset(create("Frame", {
    Name = "Main", Position = UDim2.fromOffset(10, 31), Size = UDim2.new(1, -20, 1, -41),
    BackgroundColor3 = c3(Theme.bg2), Parent = window,
}))

local sidebar = create("Frame", { Name = "Sidebar", BackgroundTransparency = 1, Size = UDim2.new(0, 140, 1, 0), Parent = main })

local LOGO_IMAGE = "rbxassetid://126046912203530"
local LOGO_WIDTH, LOGO_HEIGHT = 101, 45
local LOGO_MARK_TEXT = "$"
local LOGO_MARK_X = 100
local LOGO_MARK_Y = 15
local LOGO_MARK_WIDTH = 19
local LOGO_MARK_HEIGHT = 30
local LOGO_MARK_TEXT_SIZE = 26
create("ImageLabel", {
    Name = "Logo", BackgroundTransparency = 1, Image = LOGO_IMAGE,
    Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(LOGO_WIDTH, LOGO_HEIGHT),
    ScaleType = Enum.ScaleType.Fit, Parent = sidebar,
})
local logoMark = label(sidebar, LOGO_MARK_TEXT, {
    Name = "LogoMark", Position = UDim2.fromOffset(LOGO_MARK_X, LOGO_MARK_Y), Size = UDim2.fromOffset(LOGO_MARK_WIDTH, LOGO_MARK_HEIGHT),
    FontFace = FONT_SEMI, TextSize = LOGO_MARK_TEXT_SIZE, TextColor3 = c3(Theme.scheme),
    TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 2,
})

local navHolder = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, Position = UDim2.fromOffset(3, 77), Size = UDim2.fromOffset(134, 400), Parent = sidebar })

local content = inset(create("Frame", {
    Name = "Content", Position = UDim2.fromOffset(140, 6), Size = UDim2.new(1, -146, 1, -12),
    BackgroundColor3 = c3(Theme.bg2), Parent = main,
}))

local subtabGroup = create("CanvasGroup", {
    Name = "Subtabs", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), GroupTransparency = 0, Parent = content,
})
create("Frame", { Name = "Line", BackgroundColor3 = BLACK, Position = UDim2.fromOffset(0, 21), Size = UDim2.new(1, 0, 0, 1), Parent = subtabGroup })

local pageGroup = create("CanvasGroup", {
    Name = "Page", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 1, -25),
    GroupTransparency = 0, Parent = content,
})

local popupLayer = create("Frame", { Name = "Popups", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = window })

local State = {
    visible = true,
    mouse = Vector2.new(),
    hoveredAny = false,
    popupHover = nil,
    active = nil,
    dragging = false,
    resizing = false,
    binding = nil,
    cursorLocked = false,
    previousMouseIconEnabled = nil,
    previousMouseBehavior = nil,
    cursorRestoreFrames = 0,
}

local function setMenuCursor(enabled)
    if enabled then
        State.cursorRestoreFrames = 0
        if not State.cursorLocked then
            local okIcon, icon = pcall(function() return UserInputService.MouseIconEnabled end)
            local okBehavior, behavior = pcall(function() return UserInputService.MouseBehavior end)
            State.previousMouseIconEnabled = okIcon and icon or true
            State.previousMouseBehavior = okBehavior and behavior or Enum.MouseBehavior.Default
            State.cursorLocked = true
        end
        pcall(function() UserInputService.MouseIconEnabled = true end)
        pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
    elseif State.cursorLocked then
        if State.previousMouseIconEnabled ~= nil then
            pcall(function() UserInputService.MouseIconEnabled = State.previousMouseIconEnabled end)
        end
        if State.previousMouseBehavior ~= nil then
            pcall(function() UserInputService.MouseBehavior = State.previousMouseBehavior end)
        end
        State.cursorLocked = false

        State.cursorRestoreFrames = 8
    end
end

local function restoreMenuCursor()
    if State.previousMouseIconEnabled ~= nil then
        pcall(function() UserInputService.MouseIconEnabled = State.previousMouseIconEnabled end)
    end
    if State.previousMouseBehavior ~= nil then
        pcall(function() UserInputService.MouseBehavior = State.previousMouseBehavior end)
    end
    State.cursorRestoreFrames = math.max(0, State.cursorRestoreFrames - 1)
    if State.cursorRestoreFrames == 0 then
        State.previousMouseIconEnabled = nil
        State.previousMouseBehavior = nil
    end
end

setMenuCursor(true)

local function hoverable(obj, clip)
    if not State.visible or State.dragging or State.resizing then return false end
    local m = State.mouse
    if not obj.Visible or not inside(obj, m) then return false end
    if clip and not inside(clip, m) then return false end
    if State.popupHover and not obj:IsDescendantOf(State.popupHover.frame) then return false end
    State.hoveredAny = true
    if State.active and State.active ~= obj then return false end
    return true
end

local function toLocal(abs)
    local s = uiscale.Scale
    local w = window.AbsolutePosition
    return Vector2.new((abs.X - w.X) / s, (abs.Y - w.Y) / s)
end

local Popup = {}
Popup.__index = Popup
local AllPopups = {}
local AllBinders = {}
local popupZ = 50

local function newPopup(opt)
    popupZ = popupZ + 1
    local pad = opt.padding or 0
    local rounding = opt.rounding or 4
    local frame = create("CanvasGroup", {
        Name = "Popup", Visible = false, BackgroundColor3 = c3(opt.bg or Theme.bg),
        Size = UDim2.fromOffset(10, 10), GroupTransparency = 1, ZIndex = popupZ, Parent = popupLayer,
    })
    corner(frame, rounding)
    hitbox(frame, UDim2.fromScale(1, 1), nil, 1)
    local body = create("Frame", {
        Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(pad, pad),
        Size = UDim2.new(1, -pad * 2, 1, -pad * 2), ZIndex = 2, Parent = frame,
    })
    local edge = create("Frame", {
        Name = "Border", BackgroundTransparency = 1, Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2), ZIndex = 3, Parent = frame,
    })
    corner(edge, math.max(0, rounding - 1))
    create("UIStroke", { Color = BLACK, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = edge })

    local p = setmetatable({
        frame = frame, body = body, open = false, anim = 0,
        place = opt.place, size = opt.size, onUpdate = opt.onUpdate, anchorHit = opt.anchorHit,
    }, Popup)
    table.insert(AllPopups, p)
    return p
end

function Popup:setOpen(v)
    local shouldOpen = v and true or false

    if shouldOpen and self.isBinderMode then
        for _, popup in ipairs(AllPopups) do
            if popup ~= self and popup.isBinderMode then
                popup.open = false
            end
        end
    end
    self.open = shouldOpen
    if self.open then
        popupZ = popupZ + 1
        self.frame.ZIndex = popupZ
    end
end

function Popup:update(dt)
    self.anim = anim(self.anim, self.open, dt)
    if self.anim <= 0.05 then
        if not self.open then self.anim = 0 end
        if self.frame.Visible then self.frame.Visible = false end
        return
    end
    self.frame.Visible = true
    self.frame.GroupTransparency = 1 - self.anim
    local pos = self.place()
    local w, h = self.size(self.anim)
    self.frame.Position = UDim2.fromOffset(math.floor(pos.X + 0.5), math.floor(pos.Y + 0.5))
    self.frame.Size = UDim2.fromOffset(w, h)
    if self.onUpdate then self.onUpdate(dt) end
end

local function closeAllPopups(instant)
    for _, p in ipairs(AllPopups) do
        p.open = false
        if instant then
            p.anim = 0
            p.frame.Visible = false
        end
    end
end

local function topPopupAt(m)
    local best, z = nil, -1
    for _, p in ipairs(AllPopups) do
        if p.frame.Visible and p.anim > 0.05 and inside(p.frame, m) and p.frame.ZIndex > z then
            best, z = p, p.frame.ZIndex
        end
    end
    return best
end

local Section = {}
Section.__index = Section

local function newSection(parent, x, y, h, title)
    local frame = inset(create("Frame", {
        Name = "Section_" .. title, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(274, h),
        BackgroundColor3 = c3(Theme.bg2), Parent = parent,
    }))

    local clip = create("Frame", {
        Name = "Clip", BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 5),
        Size = UDim2.fromOffset(264, h - 10), ClipsDescendants = true, Parent = frame,
    })
    local holder = create("Frame", {
        Name = "Items", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(252, 0), Parent = clip,
    })

    label(frame, title, { Name = "Title", Position = UDim2.fromOffset(14, -10), Size = UDim2.fromOffset(246, 13), ZIndex = 2 })

    local self = setmetatable({
        Frame = frame, Clip = clip, Holder = holder, Title = frame:FindFirstChild("Title"), width = 252, cursor = 0,
        widgets = {}, layoutItems = {}, lastItem = nil, scroll = 0, scrollTarget = 0,
        height = h, baseHeight = h, scrolls = true,
    }, Section)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel and not State.popupHover then
            local max = self:scrollMax()
            if max > 0 then
                self.scrollTarget = clamp(self.scrollTarget - input.Position.Z * 80, 0, max)
            end
        end
    end)
    return self
end

local function newSubSection(parent, width)
    local holder = create("Frame", { Name = "Items", BackgroundTransparency = 1, Size = UDim2.fromOffset(width, 0), Parent = parent })
    return setmetatable({
        Holder = holder, width = width, cursor = 0, widgets = {}, layoutItems = {}, lastItem = nil, scroll = 0, scrollTarget = 0, scrolls = false,
    }, Section)
end

function Section:scrollMax()
    if not self.scrolls then return 0 end
    return math.max(0, (self.cursor - 6) + 22 - self.height)
end

function Section:contentHeight()
    return math.max(0, self.cursor - 6)
end

function Section:update(dt)
    if self.scrolls then
        self.scrollTarget = clamp(self.scrollTarget, 0, self:scrollMax())
        self.scroll = lerp(self.scroll, self.scrollTarget, dt, 40)
        if math.abs(self.scroll - self.scrollTarget) < 0.5 then self.scroll = self.scrollTarget end
        self.Holder.Position = UDim2.fromOffset(6, 6 - math.floor(self.scroll + 0.5))
    end
    local y = 0
    for _, layout in ipairs(self.layoutItems) do
        layout.anim = lerp(layout.anim, layout.target, dt)
        if math.abs(layout.anim - layout.target) < 0.01 then layout.anim = layout.target end
        local a = layout.anim
        layout.item.Visible = a > 0.01
        layout.item.GroupTransparency = 1 - a
        layout.item.Position = UDim2.fromOffset(0, math.floor(y + 0.5))
        local visibleHeight = layout.height * a + (a > 0.01 and 4 or 0)
        layout.item.Size = UDim2.fromOffset(self.width, math.max(0, math.floor(visibleHeight + 0.5)))
        y = y + (layout.height + 6) * a
    end
    self.Holder.Size = UDim2.fromOffset(self.width, math.max(0, math.floor(y - (y > 0 and 6 or 0) + 0.5)))
    for i = 1, #self.widgets do self.widgets[i](dt) end
end

function Section:_item(h)

    local item = create("CanvasGroup", {
        BackgroundTransparency = 1, GroupTransparency = 0,
        Position = UDim2.fromOffset(0, self.cursor),
        Size = UDim2.fromOffset(self.width, h + 4), Parent = self.Holder,
    })
    self.cursor = self.cursor + h + 6
    self.Holder.Size = UDim2.fromOffset(self.width, self:contentHeight())
    local layout = { item = item, height = h, target = 1, anim = 1 }
    table.insert(self.layoutItems, layout)
    self.lastItem = item
    return item
end

function Section:SetItemVisible(item, visible)
    for _, layout in ipairs(self.layoutItems) do
        if layout.item == item then
            layout.target = visible and 1 or 0
            return
        end
    end
end

function Section:_hover(obj)
    return hoverable(obj, self.Clip)
end

function Section:Spacing(px)

    self.cursor = self.cursor - 6 + (px or 0)
    self.Holder.Size = UDim2.fromOffset(self.width, self:contentHeight())
end

local BIND_MODES = { "Always On", "On Hotkey", "Toggle" }

local function makeBinder(parent, section, default, onChange, defaultMode, onMode, onActive, noModeMenu, ignoreProcessed)
    local mode = defaultMode or "Always On"
    local b = {
        key = default, active = false, isActive = mode == "Always On", mode = mode,
        ignoreProcessed = ignoreProcessed == true,
        hover = 0, anim = 0, height = 14, w = textWidth(keyName(default), 11),
    }
    local frame = inset(hitbox(parent, UDim2.fromOffset(8 + math.floor(b.w), 14), nil, 3))
    frame.BackgroundTransparency = 0
    frame.BackgroundColor3 = c3(Theme.bg3)
    frame.Name = "Binder"
    local txt = label(frame, keyName(default), {
        TextSize = 11, Position = UDim2.fromOffset(4, 1), Size = UDim2.fromOffset(200, 12), ZIndex = 4,
    })
    setText(txt, Theme.text2)
    b.frame = frame
    table.insert(AllBinders, b)

    local modePopup
    local modeRows = {}
    local function modeIndex(name)
        for i, value in ipairs(BIND_MODES) do
            if value == name then return i end
        end
        return 1
    end

    function b.setActive(active, silent)
        local nextActive = active and true or false
        if b.isActive == nextActive then return end
        b.isActive = nextActive
        if not silent and typeof(onActive) == "function" then onActive(b.isActive) end
    end

    function b.setMode(nextMode, silent)
        for _, value in ipairs(BIND_MODES) do
            if value == nextMode then
                b.mode = nextMode
                b.setActive(nextMode == "Always On", false)
                if not silent and typeof(onMode) == "function" then onMode(b.mode, b.isActive) end
                return
            end
        end
    end

    function b.set(key, silent)
        b.key = key
        b.active = false
        txt.Text = keyName(key)
        if not silent then onChange(key) end
    end

    modePopup = newPopup({
        padding = 0, rounding = 3, bg = Theme.bg3, anchorHit = frame,
        place = function()
            local p = toLocal(frame.AbsolutePosition)
            return Vector2.new(p.X, p.Y + frame.AbsoluteSize.Y / uiscale.Scale + 4)
        end,
        size = function(a) return 126, math.floor((#BIND_MODES * 22 + 2) * a + 0.5) end,
    })
    modePopup.isBinderMode = true
    for i, modeName in ipairs(BIND_MODES) do
        local row = hitbox(modePopup.body, UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, (i - 1) * 22), 4)
        row.BackgroundTransparency = 1
        row.BackgroundColor3 = c3(Theme.bg4)
        local rowText = label(row, modeName, {
            Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 13), ZIndex = 5,
        })
        modeRows[i] = { row = row, text = rowText, hover = 0 }
        row.MouseButton1Click:Connect(function()
            b.setMode(modeName)
            modePopup:setOpen(false)
        end)
    end
    modePopup.onUpdate = function(dt)
        for i, row in ipairs(modeRows) do
            local hov = hoverable(row.row, modePopup.frame)
            row.hover = anim(row.hover, hov, dt)
            local selected = b.mode == BIND_MODES[i]
            setBg(row.row, fade(Colors.bg4, row.hover))
            setText(row.text, selected and Colors.scheme or mix(Colors.text2, Colors.text, row.hover))
            row.text.FontFace = selected and FONT_SEMI or FONT_MEDIUM
        end
    end

    frame.MouseButton1Click:Connect(function()
        b.active = true
        txt.Text = "..."
        State.binding = b
    end)
    frame.MouseButton2Click:Connect(function()
        if State.binding == b then
            State.binding = nil
            b.active = false
        end
        if not noModeMenu then
            modePopup:setOpen(not modePopup.open)
        end
    end)

    function b.width() return 8 + math.floor(b.w) end
    function b.update(dt)
        local hov = section:_hover(frame)
        b.hover = anim(b.hover, hov, dt)
        b.anim = anim(b.anim, hov or b.active or modePopup.open, dt)
        b.w = lerp(b.w, textWidth(b.active and "..." or keyName(b.key), 11), dt)
        frame.Size = UDim2.fromOffset(b.width(), 14)
        setBg(frame, mix(Colors.bg3, Colors.bg4, b.anim))
        setText(txt, b.isActive and Colors.text or Colors.text2)
        return hov
    end
    return b
end

local function toColorTable(c, a)
    if typeof(c) == "Color3" then return { c.R, c.G, c.B, a or 1 } end
    if type(c) == "table" then return { c[1] or 1, c[2] or 1, c[3] or 1, c[4] or a or 1 } end
    return { 1, 1, 1, a or 1 }
end

local function makeColorButton(parent, section, initial, alpha, onChange)
    local col = toColorTable(initial, alpha)

    local cb = { col = col, hover = 0, height = 10 }
    local frame = inset(hitbox(parent, UDim2.fromOffset(20, 10), nil, 3))
    frame.Name = "ColorButton"
    frame.BackgroundTransparency = 0
    frame.BackgroundColor3 = Color3.new(col[1], col[2], col[3])
    local shade = create("Frame", { BackgroundColor3 = BLACK, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = frame })
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.8), Parent = shade })
    cb.frame = frame

    local picker
    local function buildPicker()
        local h, s, v = Color3.new(col[1], col[2], col[3]):ToHSV()
        local st = { h = h, s = s, v = v }
        local hits = {}

        local pop
        pop = newPopup({
            padding = 14, rounding = 4, bg = Theme.bg, anchorHit = frame,
            place = function() return toLocal(frame.AbsolutePosition) end,
            size = function() return 235, 206 end,
        })
        local body = pop.body

        local square = create("Frame", { Name = "SV", BackgroundColor3 = Color3.fromHSV(st.h, 1, 1), Size = UDim2.fromOffset(193, 132), ZIndex = 4, Parent = body })
        corner(square, 4)
        local sw = create("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = square })
        corner(sw, 4)
        create("UIGradient", { Rotation = 0, Transparency = NumberSequence.new(0, 1), Parent = sw })
        local sb = create("Frame", { BackgroundColor3 = BLACK, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = square })
        corner(sb, 4)
        create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = sb })
        local svDot = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(6, 6), ZIndex = 7, Parent = square })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svDot })
        create("UIStroke", { Color = WHITE, Thickness = 1, Parent = svDot })
        hits.sv = hitbox(square, UDim2.fromScale(1, 1), nil, 8)

        local abar = create("Frame", { Name = "Alpha", BackgroundTransparency = 1, Position = UDim2.fromOffset(199, 0), Size = UDim2.fromOffset(6, 132), ZIndex = 4, Parent = body })
        for i = 0, 42 do
            local a1 = ((i + 1) % 2 == 0) and Color3.fromRGB(222, 222, 222) or Color3.fromRGB(155, 155, 155)
            local a2 = ((i + 1) % 2 ~= 0) and Color3.fromRGB(222, 222, 222) or Color3.fromRGB(155, 155, 155)
            create("Frame", { BackgroundColor3 = a1, Position = UDim2.fromOffset(0, i * 3), Size = UDim2.fromOffset(3, 3), ZIndex = 5, Parent = abar })
            create("Frame", { BackgroundColor3 = a2, Position = UDim2.fromOffset(3, i * 3), Size = UDim2.fromOffset(3, 3), ZIndex = 5, Parent = abar })
        end
        local aFill = create("Frame", { BackgroundColor3 = Color3.new(col[1], col[2], col[3]), Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = abar })
        corner(aFill, 3)
        create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1), Parent = aFill })
        local aDot = create("Frame", { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7), ZIndex = 7, Parent = abar })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = aDot })
        local aDotFill = create("Frame", { BackgroundColor3 = Color3.new(col[1], col[2], col[3]), Size = UDim2.fromScale(1, 1), ZIndex = 8, Parent = aDot })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = aDotFill })
        create("UIStroke", { Color = WHITE, Thickness = 1, Parent = aDot })
        hits.a = hitbox(abar, UDim2.fromScale(1, 1), nil, 9)

        local hbar = create("Frame", { Name = "Hue", BackgroundColor3 = WHITE, Position = UDim2.fromOffset(0, 138), Size = UDim2.fromOffset(207, 5), ZIndex = 4, Parent = body })
        corner(hbar, 3)
        local hueGrad = create("UIGradient", { Rotation = 0, Parent = hbar })
        local hDot = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), ZIndex = 5, Parent = hbar })
        create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hDot })
        create("UIStroke", { Color = WHITE, Thickness = 1, Parent = hDot })
        hits.h = hitbox(hbar, UDim2.fromScale(1, 1), nil, 6)

        local function inputBox(x, w)
            local holder = create("Frame", { BackgroundColor3 = c3(Theme.bg3), Position = UDim2.fromOffset(x, 149), Size = UDim2.fromOffset(w, 29), ZIndex = 4, Parent = body })
            corner(holder, 3)
            create("UIStroke", { Color = BLACK, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = holder })
            local box = create("TextBox", {
                BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0),
                FontFace = FONT_MEDIUM, TextSize = 13, TextColor3 = c3(Theme.text), TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false, Text = "", PlaceholderText = "", ZIndex = 5, Parent = holder,
            })
            return box
        end
        local hexBox = inputBox(0, 117)
        local alphaBox = inputBox(127, 80)

        local function refresh(changed)
            square.BackgroundColor3 = Color3.fromHSV(st.h, 1, 1)
            svDot.Position = UDim2.fromOffset(st.s * 193 - 3, (1 - st.v) * 132 - 3)
            local keys = {}
            for i = 0, 10 do
                keys[#keys + 1] = ColorSequenceKeypoint.new(i / 10, Color3.fromHSV(math.min(i / 10, 0.9999), clamp(st.s, 0.6, 1), clamp(st.v, 0.6, 1)))
            end
            hueGrad.Color = ColorSequence.new(keys)
            hDot.Position = UDim2.fromOffset(st.h * 207, 2.5)
            local rgb = Color3.new(col[1], col[2], col[3])
            aFill.BackgroundColor3 = rgb
            aDotFill.BackgroundColor3 = rgb
            aDotFill.BackgroundTransparency = 1 - col[4]
            aDot.Position = UDim2.fromOffset(3, (1 - col[4]) * 132)
            frame.BackgroundColor3 = rgb
            if not hexBox:IsFocused() then
                hexBox.Text = string.format("%02X%02X%02X", math.floor(col[1] * 255), math.floor(col[2] * 255), math.floor(col[3] * 255))
            end
            if not alphaBox:IsFocused() then
                alphaBox.Text = string.format("%d%%", math.floor(col[4] * 100))
            end
            if changed then onChange(col) end
        end

        local function applyHSV()
            local c = Color3.fromHSV(math.min(st.h, 0.9999), st.s, st.v)
            col[1], col[2], col[3] = c.R, c.G, c.B
        end

        for _, key in ipairs({ "sv", "a", "h" }) do
            hits[key].MouseButton1Down:Connect(function() State.active = hits[key] end)
        end

        hexBox.FocusLost:Connect(function()
            local digits = hexBox.Text:gsub("#", ""):sub(1, 6)
            if digits:match("^%x%x%x%x%x%x$") then
                col[1] = tonumber(digits:sub(1, 2), 16) / 255
                col[2] = tonumber(digits:sub(3, 4), 16) / 255
                col[3] = tonumber(digits:sub(5, 6), 16) / 255
                st.h, st.s, st.v = Color3.new(col[1], col[2], col[3]):ToHSV()
            end
            refresh(true)
        end)
        alphaBox.FocusLost:Connect(function()
            local n = tonumber(alphaBox.Text:match("%d+"))
            if n then col[4] = clamp(n / 100, 0, 1) end
            refresh(true)
        end)

        pop.onUpdate = function()
            local m = State.mouse
            local changed = false
            if State.active == hits.sv then
                local p, sz = square.AbsolutePosition, square.AbsoluteSize
                st.s = clamp((m.X - p.X) / sz.X, 0, 1)
                st.v = 1 - clamp((m.Y - p.Y) / sz.Y, 0, 1)
                applyHSV(); changed = true
            elseif State.active == hits.h then
                local p, sz = hbar.AbsolutePosition, hbar.AbsoluteSize
                st.h = clamp((m.X - p.X) / sz.X, 0, 1)
                applyHSV(); changed = true
            elseif State.active == hits.a then
                local p, sz = abar.AbsolutePosition, abar.AbsoluteSize
                col[4] = 1 - clamp((m.Y - p.Y) / sz.Y, 0, 1)
                changed = true
            end
            for _, hb in pairs(hits) do
                if hoverable(hb) then State.hoveredAny = true end
            end
            if changed then refresh(true) end
        end

        refresh(false)
        pop.refresh = refresh
        pop.state = st
        return pop
    end

    frame.MouseButton1Click:Connect(function()
        if not picker then picker = buildPicker() end
        picker:setOpen(not picker.open)
    end)

    function cb.set(c, a)
        local t = toColorTable(c, a or col[4])
        col[1], col[2], col[3], col[4] = t[1], t[2], t[3], t[4]
        frame.BackgroundColor3 = Color3.new(col[1], col[2], col[3])
        if picker then
            picker.state.h, picker.state.s, picker.state.v = Color3.new(col[1], col[2], col[3]):ToHSV()
            picker.refresh(false)
        end
        onChange(col)
    end
    function cb.width() return 20 end
    function cb.update(dt)
        local hov = section:_hover(frame)
        cb.hover = anim(cb.hover, hov, dt)
        return hov
    end
    return cb
end

local function colorValue(col)
    return Color3.new(col[1], col[2], col[3]), col[4]
end

local function makeOptions(parent, section, builder)
    local o = { hover = 0, height = 16 }
    local frame = hitbox(parent, UDim2.fromOffset(16, 16), nil, 3)
    frame.Name = "Options"
    local dots = {}
    for i = 0, 2 do
        dots[#dots + 1] = create("Frame", {
            BackgroundColor3 = c3(Theme.text2), BackgroundTransparency = 1 - Theme.text2[4],
            Position = UDim2.fromOffset(3 + i * 4, 7), Size = UDim2.fromOffset(2, 2), ZIndex = 4, Parent = frame,
        })
    end
    o.frame = frame

    local pop = newPopup({
        padding = 14, rounding = 4, bg = Theme.bg, anchorHit = frame,
        place = function()
            local p = toLocal(frame.AbsolutePosition)
            return Vector2.new(p.X, p.Y + frame.AbsoluteSize.Y / uiscale.Scale + 8)
        end,
        size = function() return 180 + 28, o.sub:contentHeight() + 28 end,
    })
    o.sub = newSubSection(pop.body, 180)
    pop.onUpdate = function(dt) o.sub:update(dt) end
    if typeof(builder) == "function" then builder(o.sub) end

    frame.MouseButton1Click:Connect(function() pop:setOpen(true) end)

    function o.width() return 16 end
    function o.update(dt)
        local hov = section:_hover(frame)
        o.hover = anim(o.hover, hov or pop.open, dt)
        local c = mix(Colors.text2, Colors.text, o.hover)
        for _, d in ipairs(dots) do setBg(d, c) end
        return hov
    end
    return o
end

function Section:Checkbox(text, default, callback, opts)
    opts = opts or {}
    local flag = opts.flag or text
    local item = self:_item(10)
    local hit = hitbox(item, UDim2.new(1, 0, 0, 10))
    local box = inset(create("Frame", { Name = "Box", BackgroundColor3 = c3(Theme.bg2), Size = UDim2.fromOffset(10, 10), Parent = item }))
    local lbl = label(item, trimLabel(text), { Position = UDim2.fromOffset(15, -2), Size = UDim2.new(1, -15, 0, 13) })

    local value = default and true or false
    local st = { hover = 0, enabled = value and 1 or 0, anim = value and 1 or 0 }
    local api = {}
    Flags[flag] = value

    local extras = {}
    if opts.keybind ~= nil then
        local start = (typeof(opts.keybind) == "EnumItem") and opts.keybind or nil
        local binder = makeBinder(item, self, start, function(key)
            Flags[flag .. "_key"] = key
            fire(opts.onKey, key)
        end, opts.mode, function(mode, active)
            fire(opts.onMode, mode, active)
        end, function(active)
            fire(opts.onActive, active)
        end, opts.noModeMenu, opts.ignoreProcessed)
        Flags[flag .. "_key"] = start
        api.Binder = binder
        table.insert(extras, binder)
    end
    if opts.options then
        table.insert(extras, makeOptions(item, self, opts.options))
    end
    local colors = opts.color
    if typeof(colors) == "Color3" or (type(colors) == "table" and type(colors[1]) == "number") then colors = { colors } end
    api.Colors = {}
    for i, c in ipairs(colors or {}) do
        local key = flag .. "_color" .. (i > 1 and tostring(i) or "")
        local btn = makeColorButton(item, self, c, 1, function(col)
            local rgb, a = colorValue(col)
            Flags[key] = rgb
            Flags[key .. "_alpha"] = a
            fire(opts.onColor, rgb, a, i)
        end)
        Flags[key] = (typeof(c) == "Color3") and c or Color3.new(1, 1, 1)
        Flags[key .. "_alpha"] = 1
        table.insert(api.Colors, btn)
        table.insert(extras, btn)
    end

    local function set(v, silent)
        value = v and true or false
        Flags[flag] = value
        if not silent then fire(callback, value) end
    end
    hit.MouseButton1Click:Connect(function() set(not value) end)

    table.insert(self.widgets, function(dt)

        local total = 2
        for i, e in ipairs(extras) do total = total + e.width() + (i > 1 and 8 or 0) end
        local x = self.width - total + 1
        local overExtra = false
        for _, e in ipairs(extras) do
            local w = e.width()
            local h = e.height
            e.frame.Position = UDim2.fromOffset(x, math.floor(5 - h / 2 + 0.5))
            x = x + w + 8
            if e.update(dt) then overExtra = true end
        end

        local hov = (not overExtra) and self:_hover(hit)
        st.hover = anim(st.hover, hov and not value, dt)
        st.enabled = anim(st.enabled, value, dt)
        st.anim = anim(st.anim, hov or value, dt)

        setBg(box, mix(mix(Colors.bg2, Colors.bg4, st.hover), Colors.scheme, st.enabled))
        setText(lbl, mix(mix(Colors.text2, Colors.text3, st.hover), Colors.text, st.enabled))
        local f = value and FONT_SEMI or FONT_MEDIUM
        if lbl.FontFace ~= f then lbl.FontFace = f end
    end)

    function api:Set(v) set(v) end
    function api:Get() return value end
    function api:Toggle() set(not value) end
    function api:SetColor(c, a, i)
        local b = api.Colors[i or 1]
        if b then b.set(c, a) end
    end
    function api:SetKey(key)
        if api.Binder then api.Binder.set(key) end
    end
    return api
end

local function formatValue(format, v, isInt)
    if isInt then v = trunc(v + 0) end
    local ok, s = pcall(string.format, format, v)
    if ok then return s end
    return tostring(v)
end

function Section:_slider(text, isInt, min, max, default, callback, format, flag)
    format = format or (isInt and "%d" or "%.1f")
    flag = flag or text
    local item = self:_item(21)
    local hit = hitbox(item, UDim2.new(1, 0, 0, 21))
    local bar = inset(create("Frame", { Name = "Bar", BackgroundColor3 = c3(Theme.bg2), Position = UDim2.fromOffset(15, 15), Size = UDim2.new(1, -36, 0, 6), Parent = item }))
    local fill = create("Frame", { Name = "Fill", BackgroundColor3 = c3(Theme.scheme), Size = UDim2.fromOffset(0, 6), Parent = bar })
    label(item, trimLabel(text), { Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -86, 0, 13) })
    local valueBox = create("TextBox", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -91, 0, -1.5), Size = UDim2.fromOffset(70, 16),
        FontFace = FONT_MEDIUM, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center, ClearTextOnFocus = false,
        Text = "", ZIndex = 3, Parent = item,
    })
    setText(valueBox, Theme.text2)

    local value = clamp(default or min, min, max)
    if isInt then value = trunc(value) end
    local st = { hover = 0, held = 0, anim = 0, val = 0 }
    Flags[flag] = value
    valueBox.Text = formatValue(format, value, isInt)

    local function set(v, silent)
        v = tonumber(v) or value
        v = clamp(v, min, max)
        if isInt then v = trunc(v) end
        if v == value then return end
        value = v
        Flags[flag] = value
        if not valueBox:IsFocused() then valueBox.Text = formatValue(format, value, isInt) end
        if not silent then fire(callback, value) end
    end

    hit.MouseButton1Down:Connect(function() State.active = hit end)
    valueBox.FocusLost:Connect(function()
        local n = tonumber((valueBox.Text:gsub("[^%d%.%-]", "")))
        if n then set(n) end
        valueBox.Text = formatValue(format, value, isInt)
    end)

    table.insert(self.widgets, function(dt)
        local held = State.active == hit
        local hov = self:_hover(hit) or self:_hover(valueBox)
        if held and max > min then
            local p, sz = bar.AbsolutePosition, bar.AbsoluteSize
            local raw = min + (State.mouse.X - p.X) / sz.X * (max - min)
            set(isInt and trunc(raw) or raw)
        end
        st.hover = anim(st.hover, hov, dt)
        st.held = anim(st.held, held, dt)
        st.anim = anim(st.anim, hov or held, dt)
        local barW = bar.AbsoluteSize.X / math.max(uiscale.Scale, 0.001)
        local target = (max > min) and (value - min) / (max - min) * barW or 0
        st.val = lerp(st.val, target, dt)
        fill.Size = UDim2.fromOffset(clamp(st.val, 0, barW), 6)
        setBg(bar, mix(mix(Colors.bg2, Colors.bg4, st.hover), Colors.bg4, st.held))
        setBg(fill, Colors.scheme)
        setText(valueBox, Colors.text2)
    end)

    local api = {}
    function api:Set(v) set(v) end
    function api:Get() return value end
    return api
end

function Section:SliderInt(text, min, max, default, callback, format, flag)
    return self:_slider(text, true, min, max, default, callback, format or "%d", flag)
end
function Section:SliderFloat(text, min, max, default, callback, format, flag)
    return self:_slider(text, false, min, max, default, callback, format or "%.1f", flag)
end
function Section:Slider(text, min, max, default, callback, opts)
    opts = opts or {}
    if opts.float then return self:SliderFloat(text, min, max, default, callback, opts.format, opts.flag) end
    return self:SliderInt(text, min, max, default, callback, opts.format, opts.flag)
end

function Section:_comboBase(text)
    local item = self:_item(34)
    label(item, trimLabel(text), { Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -36, 0, 13) })
    local box = inset(create("Frame", { Name = "Box", BackgroundColor3 = c3(Theme.bg2), Position = UDim2.fromOffset(15, 15), Size = UDim2.new(1, -36, 0, 19), Parent = item }))
    local _, grad = shine(box, 0.03)
    local preview = label(box, "", { Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -30, 0, 13), ZIndex = 2, TextTruncate = Enum.TextTruncate.AtEnd })
    local arr = arrow(box)
    arr.Position = UDim2.new(1, -17, 0, 7)
    arr.ZIndex = 2
    local hit = hitbox(box, UDim2.fromScale(1, 1), nil, 3)
    return { item = item, box = box, grad = grad, preview = preview, arrow = arr, hit = hit }
end

local function makeListPopup(base, items, isSelected, onPick)
    local n = #items
    local maxw = 0
    for _, it in ipairs(items) do maxw = math.max(maxw, textWidth(tostring(it), 13) + 48) end

    local rows = {}
    local pop
    pop = newPopup({
        padding = 0, rounding = 2, bg = Theme.bg3, anchorHit = base.hit,
        place = function()
            local p = toLocal(base.box.AbsolutePosition)
            return Vector2.new(p.X, p.Y + base.box.AbsoluteSize.Y / uiscale.Scale + 4)
        end,
        size = function(a)
            local w = math.max(maxw, base.box.AbsoluteSize.X / math.max(uiscale.Scale, 0.001))
            return w, math.max(1, math.floor(math.min(n * 22 + 2, 200) * a + 0.5))
        end,
    })
    local scroller = create("ScrollingFrame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 1, -2),
        CanvasSize = UDim2.fromOffset(0, n * 22), ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(79, 79, 79),
        ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
        VerticalScrollBarInset = Enum.ScrollBarInset.None, Parent = pop.body,
    })
    for i, it in ipairs(items) do
        local row = hitbox(scroller, UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, (i - 1) * 22), 2)
        row.BackgroundTransparency = 1
        row.BackgroundColor3 = c3(Theme.bg4)
        local txt = label(row, tostring(it), { Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 13), ZIndex = 3 })
        local r = { row = row, txt = txt, hover = 0, sel = isSelected(i) and 1 or 0 }
        rows[i] = r
        row.MouseButton1Click:Connect(function() onPick(i) end)
    end
    pop.onUpdate = function(dt)
        for i, r in ipairs(rows) do
            local selected = isSelected(i)
            local hov = hoverable(r.row, scroller)
            r.hover = anim(r.hover, hov, dt)
            r.sel = anim(r.sel, selected, dt)
            setBg(r.row, fade(Colors.bg4, r.hover))
            setText(r.txt, mix(mix(Colors.text2, Colors.text3, r.hover), Colors.scheme, r.sel))
            local f = selected and FONT_SEMI or FONT_MEDIUM
            if r.txt.FontFace ~= f then r.txt.FontFace = f end
        end
    end
    return pop
end

local function comboUpdater(section, base, pop, st)
    return function(dt)
        local hov = section:_hover(base.hit)
        st.hover = anim(st.hover, hov, dt)
        local o = pop.anim
        local a = 0.03 + (0.06 - 0.03) * st.hover
        a = a + (0.06 - a) * o
        base.grad.Transparency = NumberSequence.new(1 - a, 1)
        local rot = pop.open and 180 or 0
        if base.arrow.Rotation ~= rot then base.arrow.Rotation = rot end
    end
end

function Section:Combo(text, items, default, callback, flag)
    flag = flag or text
    items = items or {}
    local base = self:_comboBase(text)
    local index = 1
    if type(default) == "number" then
        index = clamp(math.floor(default), 1, math.max(1, #items))
    elseif default ~= nil then
        for i, v in ipairs(items) do if v == default then index = i end end
    end
    Flags[flag] = items[index]
    base.preview.Text = tostring(items[index] or "")

    local pop, updater
    local function set(i, silent)
        if not items[i] then return end
        index = i
        Flags[flag] = items[i]
        base.preview.Text = tostring(items[i] or "")
        if not silent then fire(callback, items[i], i) end
    end
    local function rebuildPopup()
        if pop then
            pop:setOpen(false)
            for i = #AllPopups, 1, -1 do
                if AllPopups[i] == pop then table.remove(AllPopups, i); break end
            end
            pcall(function() pop.frame:Destroy() end)
        end
        pop = makeListPopup(base, items, function(i) return i == index end, function(i)
            set(i)
            pop:setOpen(false)
        end)
        updater = comboUpdater(self, base, pop, { hover = 0 })
    end
    rebuildPopup()
    base.hit.MouseButton1Click:Connect(function() pop:setOpen(not pop.open) end)

    table.insert(self.widgets, function(dt) if updater then updater(dt) end end)

    local api = {}
    function api:Set(v)
        if type(v) == "number" then
            if #items > 0 then set(clamp(v, 1, #items)) end
            return
        end
        for i, it in ipairs(items) do if it == v then set(i); return end end
    end
    function api:SetItems(newItems, selected, silent)
        items = newItems or {}
        index = 1
        if selected ~= nil then
            for i, it in ipairs(items) do if it == selected then index = i; break end end
        end
        Flags[flag] = items[index]
        base.preview.Text = tostring(items[index] or "")
        rebuildPopup()
        if not silent and items[index] ~= nil then fire(callback, items[index], index) end
    end
    function api:GetItems() return items end
    function api:Get() return items[index], index end
    return api
end

function Section:MultiCombo(text, items, defaults, callback, flag)
    flag = flag or text
    local base = self:_comboBase(text)
    local selected = {}
    for _, d in ipairs(defaults or {}) do
        if type(d) == "number" then selected[d] = true
        else for i, v in ipairs(items) do if v == d then selected[i] = true end end end
    end

    local function listValue()
        local out = {}
        for i, v in ipairs(items) do if selected[i] then table.insert(out, v) end end
        return out
    end
    local function previewText()
        local buf = table.concat(listValue(), ", ")
        if textWidth(buf, 13) > 100 then
            for i = 1, #buf - 1 do
                if textWidth(buf:sub(1, i + 1), 13) > 100 then
                    buf = buf:sub(1, i)
                    if buf:sub(-1) == "," then buf = buf:sub(1, -2) end
                    buf = buf .. ".."
                    break
                end
            end
        end
        if buf == "" then buf = "None" end
        return buf
    end
    local function refresh(silent)
        local list = listValue()
        Flags[flag] = list
        base.preview.Text = previewText()
        if not silent then fire(callback, list) end
    end
    refresh(true)

    local pop = makeListPopup(base, items, function(i) return selected[i] == true end, function(i)
        selected[i] = not selected[i]
        refresh(false)
    end)
    base.hit.MouseButton1Click:Connect(function() pop:setOpen(not pop.open) end)
    table.insert(self.widgets, comboUpdater(self, base, pop, { hover = 0 }))

    local api = {}
    function api:Set(list)
        selected = {}
        for _, d in ipairs(list or {}) do
            for i, v in ipairs(items) do if v == d then selected[i] = true end end
        end
        refresh(false)
    end
    function api:Get() return listValue() end
    return api
end

function Section:Keybind(text, default, callback, flag, opts)
    flag = flag or text
    opts = opts or {}
    local item = self:_item(14)
    label(item, trimLabel(text), { Position = UDim2.fromOffset(0, 0.5), Size = UDim2.new(1, -60, 0, 13) })
    Flags[flag] = default
    local binder = makeBinder(item, self, default, function(key)
        Flags[flag] = key
        fire(callback, key)
    end, opts.mode, function(mode, active)
        fire(opts.onMode, mode, active)
    end, function(active)
        fire(opts.onActive, active)
    end, opts.noModeMenu, opts.ignoreProcessed)
    table.insert(self.widgets, function(dt)
        binder.update(dt)
        binder.frame.Position = UDim2.new(1, -binder.width(), 0, 0)
    end)
    local api = {}
    function api:Set(key) binder.set(key) end
    function api:Get() return binder.key end
    function api:SetMode(mode) binder.setMode(mode) end
    function api:GetMode() return binder.mode end
    return api
end

function Section:ColorPicker(text, default, callback, alpha, flag)
    flag = flag or text
    local item = self:_item(13)
    label(item, trimLabel(text), { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -30, 0, 13) })
    Flags[flag] = (typeof(default) == "Color3") and default or Color3.new(1, 1, 1)
    Flags[flag .. "_alpha"] = alpha or 1
    local btn = makeColorButton(item, self, default, alpha, function(col)
        local rgb, a = colorValue(col)
        Flags[flag] = rgb
        Flags[flag .. "_alpha"] = a
        fire(callback, rgb, a)
    end)

    btn.frame.Position = UDim2.new(1, -btn.width() - 1, 0, 0)
    table.insert(self.widgets, function(dt) btn.update(dt) end)
    local api = {}
    function api:Set(c, a) btn.set(c, a) end
    function api:Get() return colorValue(btn.col) end
    return api
end

function Section:Button(text, callback)
    local shown = trimLabel(text)

    local item = self:_item(19)
    local btn = inset(create("TextButton", {
        Name = "Button", Text = "", AutoButtonColor = false, Selectable = false,
        BackgroundColor3 = c3(Theme.bg2), Position = UDim2.fromOffset(15, 0),
        Size = UDim2.new(1, -36, 0, 19), Parent = item,
    }))
    local _, grad = shine(btn, 0.03)
    local txt = label(btn, shown, {
        Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 2,
    })
    local st = { hover = 0 }
    btn.MouseButton1Click:Connect(function() fire(callback) end)
    table.insert(self.widgets, function(dt)
        local hov = self:_hover(btn)
        st.hover = anim(st.hover, hov, dt)
        local a = 0.03 + (0.06 - 0.03) * st.hover
        grad.Transparency = NumberSequence.new(1 - a, 1)
        setText(txt, Colors.text)
    end)
    return btn
end

function Section:TextInput(text, default, callback, placeholder, flag)
    flag = flag or text
    local shown = trimLabel(text)
    local hasLabel = shown ~= ""
    local item = self:_item(hasLabel and 34 or 19)
    if hasLabel then
        label(item, shown, { Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -36, 0, 13) })
    end

    local holder = inset(create("Frame", {
        BackgroundColor3 = c3(Theme.bg2), Position = UDim2.fromOffset(15, hasLabel and 15 or 0),
        Size = UDim2.new(1, -36, 0, 19), Parent = item,
    }))
    local box = create("TextBox", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 1, 0),
        FontFace = FONT_MEDIUM, TextSize = 13, TextColor3 = c3(Theme.text), TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = placeholder or "", PlaceholderColor3 = Color3.fromRGB(164, 164, 164),
        ClearTextOnFocus = false, Text = default or "", ZIndex = 2, Parent = holder,
    })
    Flags[flag] = box.Text
    box.FocusLost:Connect(function(enter)
        Flags[flag] = box.Text
        fire(callback, box.Text, enter)
    end)
    table.insert(self.widgets, function()
        self:_hover(holder)
    end)
    local api = {}
    function api:Set(v) box.Text = tostring(v); Flags[flag] = box.Text end
    function api:Get() return box.Text end
    return api
end

function Section:Label(text)
    local item = self:_item(13)
    local l = label(item, tostring(text), { Size = UDim2.new(1, 0, 0, 13) })
    local api = {}
    function api:Set(v) l.Text = tostring(v) end
    return api
end

function Section:Separator()

    local item = self:_item(1)
    local line = create("Frame", {
        BackgroundColor3 = WHITE, BackgroundTransparency = 1 - Theme.separator[4],
        Position = UDim2.fromOffset(3, 0), Size = UDim2.new(1, 8, 0, 1), Parent = item,
    })
    return line
end

local Nav = { current = 1, nextTab = 1, tabAnim = 1, tabDest = 1, subAnim = 1, subDest = 1 }

local function findTab(name)
    for i, t in ipairs(library.Tabs) do
        if t.name == name then return t, i end
    end
end

local function applyPage()
    local tab = library.Tabs[Nav.current]
    for ti, t in ipairs(library.Tabs) do
        if t.subRow then t.subRow.Visible = (ti == Nav.current) end
        for pi, pg in ipairs(t.pages) do
            pg.container.Visible = (ti == Nav.current and pi == t.current)
        end
    end
    local hasSubs = tab and #tab.subtabs > 0
    subtabGroup.Visible = hasSubs and true or false

    if hasSubs then
        pageGroup.Position = UDim2.fromOffset(0, 22)
        pageGroup.Size = UDim2.new(1, 0, 1, -25)
    else
        pageGroup.Position = UDim2.fromOffset(0, 0)
        pageGroup.Size = UDim2.new(1, 0, 1, -3)
    end
end

function library:AddTab(name, subtabs)
    local existing = findTab(name)
    if existing then return existing end
    local index = #self.Tabs + 1
    local tab = { name = name, subtabs = subtabs or {}, pages = {}, current = 1, nextSub = 1, hover = 0, sel = (index == 1) and 1 or 0 }

    local btn = hitbox(navHolder, UDim2.fromOffset(134, 32), UDim2.fromOffset(0, (index - 1) * 35))
    btn.Name = "Tab_" .. name
    create("UIStroke", { Color = BLACK, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn })
    btn.BackgroundColor3 = c3(Theme.tab)
    btn.BackgroundTransparency = 1
    local accent = create("Frame", { Name = "Accent", BackgroundColor3 = c3(Theme.scheme), BackgroundTransparency = 1, Size = UDim2.fromOffset(3, 32), ZIndex = 2, Parent = btn })
    local txt = label(btn, name, { Position = UDim2.fromOffset(10, 9.5), Size = UDim2.fromOffset(118, 13), ZIndex = 2 })
    tab.button, tab.accent, tab.label = btn, accent, txt
    btn.MouseButton1Click:Connect(function()
        if Nav.nextTab ~= index then
            Nav.nextTab = index
            Nav.tabDest = 0
        end
    end)

    local count = math.max(1, #tab.subtabs)
    for i = 1, count do
        local container = create("Frame", {
            Name = "Page_" .. name .. "_" .. tostring(tab.subtabs[i] or "main"),
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = pageGroup,
        })
        tab.pages[i] = { name = tab.subtabs[i] or name, container = container, sections = {}, y = { 10, 10 } }
    end

    if #tab.subtabs > 0 then
        local row = create("Frame", { Name = "Row_" .. name, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 2, Parent = subtabGroup })
        tab.subRow = row
        tab.subButtons = {}
        local count = #tab.subtabs
        for i, sname in ipairs(tab.subtabs) do
            local sb = hitbox(row, UDim2.new(1 / count, 0, 0, 22), UDim2.new((i - 1) / count, 0, 0, 0))
            local _, grad = shine(sb, 0.03)
            local stxt = label(sb, sname, {
                Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 13),
                TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2,
            })
            local line = create("Frame", { BackgroundColor3 = c3(Theme.scheme), BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 2), ZIndex = 3, Parent = sb })
            local entry = { button = sb, grad = grad, label = stxt, line = line, hover = 0, sel = (i == 1) and 1 or 0 }
            tab.subButtons[i] = entry
            sb.MouseButton1Click:Connect(function()
                if tab.nextSub ~= i then
                    tab.nextSub = i
                    Nav.subDest = 0
                end
            end)
        end
    end

    table.insert(self.Tabs, tab)
    applyPage()
    return tab
end

function library:AddSection(tabName, subName, title, column, height)
    local tab = findTab(tabName) or self:AddTab(tabName)
    local page = tab.pages[1]
    if subName then
        for _, pg in ipairs(tab.pages) do
            if pg.name == subName then page = pg end
        end
    end
    column = (column == 2) and 2 or 1
    height = height or 150
    local x = (column == 1) and 6 or 290
    local section = newSection(page.container, x, page.y[column], height, title or "")
    section.column = column
    section.baseY = page.y[column]
    page.y[column] = page.y[column] + height + 10
    table.insert(page.sections, section)
    return section
end

local function updateNav(dt)
    for i, t in ipairs(library.Tabs) do
        local hov = hoverable(t.button)
        local selected = (Nav.nextTab == i)
        t.hover = anim(t.hover, hov, dt)
        t.sel = anim(t.sel, selected, dt)
        setBg(t.button, mix(mix(fade(Colors.tab, 0), fade(Colors.tab, 0.5), t.hover), Colors.tab, t.sel))
        setBg(t.accent, fade(Colors.scheme, t.sel))
        setText(t.label, Colors.text)
        local f = selected and FONT_SEMI or FONT_MEDIUM
        if t.label.FontFace ~= f then t.label.FontFace = f end
    end

    Nav.tabAnim = lerp(Nav.tabAnim, Nav.tabDest, dt)
    Nav.subAnim = lerp(Nav.subAnim, Nav.subDest, dt)

    if Nav.tabAnim < 0.05 then
        Nav.tabDest = 1
        if Nav.current ~= Nav.nextTab then
            Nav.current = Nav.nextTab
            closeAllPopups(true)
            applyPage()
        end
    end
    local tab = library.Tabs[Nav.current]
    if Nav.subAnim < 0.05 then
        Nav.subDest = 1
        if tab and tab.current ~= tab.nextSub then
            tab.current = tab.nextSub
            closeAllPopups(true)
            applyPage()
        end
    end

    subtabGroup.GroupTransparency = 1 - Nav.tabAnim
    pageGroup.GroupTransparency = 1 - Nav.tabAnim * Nav.subAnim

    if tab and tab.subButtons then
        for i, e in ipairs(tab.subButtons) do
            local hov = hoverable(e.button)
            local selected = (i == tab.nextSub)
            e.hover = anim(e.hover, hov, dt)
            e.sel = anim(e.sel, selected, dt)
            local a = 0.03 + (0.06 - 0.03) * e.hover
            a = a + (0.03 - a) * e.sel
            e.grad.Transparency = NumberSequence.new(1 - a, 1)
            setText(e.label, Colors.text)
            setBg(e.line, fade(Colors.scheme, e.sel))
            local f = selected and FONT_SEMI or FONT_MEDIUM
            if e.label.FontFace ~= f then e.label.FontFace = f end
        end
    end

end

function library:SelectTab(name)
    local _, i = findTab(name)
    if i and Nav.nextTab ~= i then
        Nav.nextTab = i
        Nav.tabDest = 0
    end
end

function library:SelectSubtab(name)
    local tab = library.Tabs[Nav.nextTab]
    if not tab then return end
    for i, s in ipairs(tab.subtabs) do
        if s == name and tab.nextSub ~= i then
            tab.nextSub = i
            Nav.subDest = 0
        end
    end
end
library.SelectPage = library.SelectSubtab

function library:SetVisible(v)
    State.visible = v and true or false
    window.Visible = State.visible
    modal.Visible = State.visible
    setMenuCursor(State.visible)
    if not State.visible then
        closeAllPopups(true)
        State.dragging = false
        State.resizing = false
        State.active = nil
        if State.binding then
            State.binding.set(State.binding.key, true)
            State.binding = nil
        end
    end
end
function library:Toggle() self:SetVisible(not State.visible) end
function library:SetToggleKey(key)
    if typeof(key) == "EnumItem" then self.ToggleKey = key end
end
function library:SetAccent(color)
    if typeof(color) == "Color3" then
        Theme.scheme = { color.R, color.G, color.B, 1 }
    end
end

local dragStart, windowStart
local resizeStart, resizeSize, resizePosition

local resizeHandle = hitbox(window, UDim2.fromOffset(16, 16), UDim2.new(1, -16, 1, -16), 100)
resizeHandle.Name = "ResizeHandle"

local function applyWindowLayout(width, height)
    windowWidth = math.max(MIN_WINDOW_WIDTH, math.floor(width + 0.5))
    windowHeight = math.max(MIN_WINDOW_HEIGHT, math.floor(height + 0.5))
    window.Size = UDim2.fromOffset(windowWidth, windowHeight)

    local contentWidth = windowWidth - 166
    local sectionWidth = math.max(274, math.floor((contentWidth - 26) / 2))
    local heightGrowth = windowHeight - MIN_WINDOW_HEIGHT
    for _, tab in ipairs(library.Tabs) do
        for _, page in ipairs(tab.pages) do
            for _, section in ipairs(page.sections) do
                local x = section.column == 2 and (16 + sectionWidth) or 6
                local h = section.baseHeight + heightGrowth
                section.width = sectionWidth - 22
                section.height = h
                section.Frame.Position = UDim2.fromOffset(x, section.baseY)
                section.Frame.Size = UDim2.fromOffset(sectionWidth, h)
                section.Clip.Size = UDim2.fromOffset(sectionWidth - 10, h - 10)
                if section.Title then
                    section.Title.Size = UDim2.fromOffset(sectionWidth - 28, 13)
                end
            end
        end
    end
end

function library:SetWindowSize(width, height)
    applyWindowLayout(width or windowWidth, height or windowHeight)
end

local function isMouse1(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

connect(UserInputService.InputBegan, function(input, processed)
    local m = getMouse()
    State.mouse = m

    if State.binding then
        local b = State.binding
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
            State.binding = nil
            b.set(t)
        elseif t == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                State.binding = nil
                b.set(nil)
                return
            elseif KEYNAMES[input.KeyCode.Name] then
                State.binding = nil
                b.set(input.KeyCode)
                return
            end
        end
    end

    local function matchesBind(b, input)
        if not b.key or typeof(b.key) ~= "EnumItem" then return false end
        if b.key.EnumType == Enum.KeyCode then return input.KeyCode == b.key end
        if b.key.EnumType == Enum.UserInputType then return input.UserInputType == b.key end
        return false
    end
    for _, b in ipairs(AllBinders) do
        if (not processed or b.ignoreProcessed) and matchesBind(b, input) then
            if b.mode == "On Hotkey" then
                b.setActive(true)
            elseif b.mode == "Toggle" then
                b.setActive(not b.isActive)
            end
        end
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == library.ToggleKey and not UserInputService:GetFocusedTextBox() then
            library:Toggle()
        end
        return
    end

    if not State.visible or not isMouse1(input) then return end

    local overPopup = topPopupAt(m)
    for _, p in ipairs(AllPopups) do
        if p.open and not overPopup and not (p.anchorHit and inside(p.anchorHit, m)) then
            p:setOpen(false)
        end
    end

    if inside(resizeHandle, m) and not overPopup and not State.active then
        closeAllPopups(true)
        State.resizing = true
        State.dragging = false
        resizeStart = m
        resizeSize = Vector2.new(windowWidth, windowHeight)
        resizePosition = window.Position
        return
    end

    if inside(window, m) and not overPopup and not State.hoveredAny and not State.active then
        State.dragging = true
        dragStart = m
        windowStart = window.Position
    end
end)

connect(UserInputService.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local m = getMouse()
        State.mouse = m
        if State.resizing and resizeStart and resizeSize and resizePosition then
            local d = m - resizeStart
            local scale = math.max(uiscale.Scale, 0.001)
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
            local topLeft = window.AbsolutePosition
            local maxWidth = math.max(MIN_WINDOW_WIDTH, (vp.X - topLeft.X - 10) / scale)
            local maxHeight = math.max(MIN_WINDOW_HEIGHT, (vp.Y - topLeft.Y - 10) / scale)
            local nextWidth = clamp(resizeSize.X + d.X / scale, MIN_WINDOW_WIDTH, maxWidth)
            local nextHeight = clamp(resizeSize.Y + d.Y / scale, MIN_WINDOW_HEIGHT, maxHeight)
            local physicalWidthDelta = (nextWidth - resizeSize.X) * scale
            local physicalHeightDelta = (nextHeight - resizeSize.Y) * scale
            window.Position = UDim2.new(
                resizePosition.X.Scale, resizePosition.X.Offset + physicalWidthDelta / 2,
                resizePosition.Y.Scale, resizePosition.Y.Offset + physicalHeightDelta / 2
            )
            applyWindowLayout(nextWidth, nextHeight)
        elseif State.dragging and dragStart then
            local d = m - dragStart
            window.Position = UDim2.new(windowStart.X.Scale, windowStart.X.Offset + d.X, windowStart.Y.Scale, windowStart.Y.Offset + d.Y)
        end
    end
end)

connect(UserInputService.InputEnded, function(input)
    if isMouse1(input) then
        State.dragging = false
        State.resizing = false
        resizeStart, resizeSize, resizePosition = nil, nil, nil
        State.active = nil
    end
    for _, b in ipairs(AllBinders) do
        if b.mode == "On Hotkey" and b.key and typeof(b.key) == "EnumItem" then
            local sameKey = (b.key.EnumType == Enum.KeyCode and input.KeyCode == b.key)
                or (b.key.EnumType == Enum.UserInputType and input.UserInputType == b.key)
            if sameKey then b.setActive(false) end
        end
    end
end)

connect(RunService.RenderStepped, function(dt)
    dt = math.min(dt, 0.1)

    for k, target in pairs(Theme) do
        local c = Colors[k]
        for i = 1, 4 do c[i] = lerp(c[i], target[i], dt) end
    end
    setText(logoMark, Colors.scheme)
    if not State.visible then
        if State.cursorRestoreFrames > 0 then restoreMenuCursor() end
        return
    end

    setMenuCursor(true)

    State.mouse = getMouse()
    State.popupHover = topPopupAt(State.mouse)
    State.hoveredAny = false

    updateNav(dt)

    local tab = library.Tabs[Nav.current]
    if tab then
        local page = tab.pages[tab.current]
        if page then
            for _, s in ipairs(page.sections) do s:update(dt) end
        end
    end

    for _, p in ipairs(AllPopups) do p:update(dt) end
end)

function library:Destroy()
    setMenuCursor(false)
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    self.Connections = {}
    if gui then gui:Destroy() end
    if ENV.__MILLIONWARE_SLATE == self then ENV.__MILLIONWARE_SLATE = nil end
end
library.Unload = library.Destroy
ENV.__MILLIONWARE_SLATE = library

library.ConfigItems = {}
library.ConfigIgnore = {}
do
    local function reg(flag, kind, api, extra)
        if flag == nil or api == nil then return api end
        library.ConfigItems[tostring(flag)] = { kind = kind, api = api, extra = extra }
        return api
    end
    local _cb, _sl, _co, _mc, _kb, _cp, _ti =
        Section.Checkbox, Section._slider, Section.Combo, Section.MultiCombo, Section.Keybind, Section.ColorPicker, Section.TextInput
    function Section:Checkbox(text, default, callback, opts)
        local api = _cb(self, text, default, callback, opts)
        local o = opts or {}
        return reg(o.flag or text, "checkbox", api, { ncolors = api and api.Colors and #api.Colors or 0 })
    end
    function Section:_slider(text, isInt, min, max, default, callback, format, flag)
        return reg(flag or text, "slider", _sl(self, text, isInt, min, max, default, callback, format, flag))
    end
    function Section:Combo(text, items, default, callback, flag)
        return reg(flag or text, "combo", _co(self, text, items, default, callback, flag))
    end
    function Section:MultiCombo(text, items, defaults, callback, flag)
        return reg(flag or text, "multi", _mc(self, text, items, defaults, callback, flag))
    end
    function Section:Keybind(text, default, callback, flag, opts)
        return reg(flag or text, "keybind", _kb(self, text, default, callback, flag, opts))
    end
    function Section:ColorPicker(text, default, callback, alpha, flag)
        return reg(flag or text, "color", _cp(self, text, default, callback, alpha, flag))
    end
    function Section:TextInput(text, default, callback, placeholder, flag)
        return reg(flag or text, "text", _ti(self, text, default, callback, placeholder, flag))
    end
end

local function cfgEncodeKey(k)
    if typeof(k) == "EnumItem" then return { enum = tostring(k.EnumType), name = k.Name } end
    return nil
end
local function cfgDecodeKey(t)
    if type(t) ~= "table" or not t.enum or not t.name then return nil end
    local ok, v = pcall(function() return Enum[t.enum][t.name] end)
    return ok and v or nil
end
local function cfgEncodeColor(c, a)
    if typeof(c) ~= "Color3" then return nil end
    return { c.R, c.G, c.B, a or 1 }
end
local function cfgDecodeColor(t)
    if type(t) ~= "table" then return nil end
    return Color3.new(tonumber(t[1]) or 1, tonumber(t[2]) or 1, tonumber(t[3]) or 1), tonumber(t[4]) or 1
end

function library:GetConfig()
    local out = {}
    for flag, it in pairs(self.ConfigItems) do
        if not self.ConfigIgnore[flag] then
            local api, e = it.api, {}
            local ok = pcall(function()
                if it.kind == "checkbox" then
                    e.v = api:Get()
                    if api.Binder then e.key = cfgEncodeKey(api.Binder.key); e.mode = api.Binder.mode end
                    if api.Colors and #api.Colors > 0 then
                        e.colors = {}
                        for i = 1, #api.Colors do
                            local key = flag .. "_color" .. (i > 1 and tostring(i) or "")
                            e.colors[i] = cfgEncodeColor(Flags[key], Flags[key .. "_alpha"])
                        end
                    end
                elseif it.kind == "slider" or it.kind == "text" then e.v = api:Get()
                elseif it.kind == "combo" then e.v = (api:Get())
                elseif it.kind == "multi" then e.v = api:Get()
                elseif it.kind == "keybind" then e.key = cfgEncodeKey(api:Get()); e.mode = api:GetMode()
                elseif it.kind == "color" then e.v = cfgEncodeColor(Flags[flag], Flags[flag .. "_alpha"])
                end
            end)
            if ok then e.t = it.kind; out[flag] = e end
        end
    end
    return out
end

function library:ApplyConfig(data)
    if type(data) ~= "table" then return false end
    for flag, e in pairs(data) do
        local it = self.ConfigItems[flag]
        if it and not self.ConfigIgnore[flag] and type(e) == "table" and e.t == it.kind then
            local api = it.api
            pcall(function()
                if it.kind == "checkbox" then
                    if e.v ~= nil and api:Get() ~= e.v then api:Set(e.v) end
                    if api.Binder then
                        if e.mode then api.Binder.setMode(e.mode) end
                        api.Binder.set(cfgDecodeKey(e.key))
                    end
                    if e.colors then
                        for i, c in pairs(e.colors) do
                            local col, a = cfgDecodeColor(c)
                            if col then api:SetColor(col, a, tonumber(i)) end
                        end
                    end
                elseif it.kind == "slider" then if tonumber(e.v) then api:Set(tonumber(e.v)) end
                elseif it.kind == "text" then if e.v ~= nil then api:Set(e.v) end
                elseif it.kind == "combo" then if e.v ~= nil then api:Set(e.v) end
                elseif it.kind == "multi" then if type(e.v) == "table" then api:Set(e.v) end
                elseif it.kind == "keybind" then
                    if e.mode then api:SetMode(e.mode) end
                    api:Set(cfgDecodeKey(e.key))
                elseif it.kind == "color" then
                    local col, a = cfgDecodeColor(e.v)
                    if col then api:Set(col, a) end
                end
            end)
        end
    end
    return true
end

library.ConfigFolder = "millionware/configs"
local fs = {
    write = typeof(writefile) == "function" and writefile or nil,
    read = typeof(readfile) == "function" and readfile or nil,
    isfile = typeof(isfile) == "function" and isfile or nil,
    isfolder = typeof(isfolder) == "function" and isfolder or nil,
    makefolder = typeof(makefolder) == "function" and makefolder or nil,
    list = typeof(listfiles) == "function" and listfiles or nil,
    delete = typeof(delfile) == "function" and delfile or nil,
}
local HttpSvc = cloneref(game:GetService("HttpService"))
local function cfgEnsureFolder()
    if not (fs.isfolder and fs.makefolder) then return end
    local path = ""
    for part in string.gmatch(library.ConfigFolder, "[^/]+") do
        path = (path == "" and part) or (path .. "/" .. part)
        if not fs.isfolder(path) then pcall(fs.makefolder, path) end
    end
end
local function cfgSanitize(name)
    name = tostring(name or ""):gsub("[^%w%-%_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return name
end
local function cfgPath(name) return library.ConfigFolder .. "/" .. name .. ".json" end

function library:ListConfigs()
    local out = {}
    if not fs.list then return out end
    cfgEnsureFolder()
    local ok, files = pcall(fs.list, self.ConfigFolder)
    if not ok or type(files) ~= "table" then return out end
    for _, f in ipairs(files) do
        local n = tostring(f):gsub("\\", "/"):match("([^/]+)%.json$")
        if n then table.insert(out, n) end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end
function library:SaveConfig(name)
    name = cfgSanitize(name)
    if name == "" then return false, "invalid name" end
    if not fs.write then return false, "writefile unsupported" end
    cfgEnsureFolder()
    local ok, json = pcall(function() return HttpSvc:JSONEncode(self:GetConfig()) end)
    if not ok then return false, "encode failed" end
    local wok = pcall(fs.write, cfgPath(name), json)
    return wok, wok and nil or "write failed"
end
function library:LoadConfig(name)
    name = cfgSanitize(name)
    if name == "" then return false, "invalid name" end
    if not fs.read then return false, "readfile unsupported" end
    if fs.isfile and not fs.isfile(cfgPath(name)) then return false, "not found" end
    local ok, raw = pcall(fs.read, cfgPath(name))
    if not ok then return false, "read failed" end
    local dok, data = pcall(function() return HttpSvc:JSONDecode(raw) end)
    if not dok then return false, "corrupt file" end
    return self:ApplyConfig(data)
end
function library:DeleteConfig(name)
    name = cfgSanitize(name)
    if name == "" or not fs.delete then return false end
    if fs.isfile and not fs.isfile(cfgPath(name)) then return false end
    return (pcall(fs.delete, cfgPath(name)))
end
function library:SetAutoloadConfig(name)
    if not fs.write then return false end
    cfgEnsureFolder()
    return (pcall(fs.write, self.ConfigFolder .. "/autoload.txt", cfgSanitize(name or "")))
end
function library:GetAutoloadConfig()
    if not fs.read then return nil end
    local p = self.ConfigFolder .. "/autoload.txt"
    if fs.isfile and not fs.isfile(p) then return nil end
    local ok, n = pcall(fs.read, p)
    if ok and type(n) == "string" and n ~= "" then return n end
    return nil
end

library:AddTab("Examples")
library:AddTab("Settings")

local F = { alive = true }
local UI = {}
local PINK = Color3.fromRGB(202, 115, 132)
library:SetAccent(PINK)

local destroyUI = library.Destroy
function library:Destroy()
    F.alive = false
    destroyUI(self)
end
library.Unload = library.Destroy

do

    local WATERMARK_FIELDS = {
        "Username", "Display Name", "Game", "Ping", "FPS", "Players",
        "Place ID", "Job ID", "Account Age", "User ID", "Time",
    }
    local DEFAULT_WATERMARK_FIELDS = { "Username", "Ping", "Game" }

    F.watermarkEnabled = true
    F.watermarkFields = table.clone(DEFAULT_WATERMARK_FIELDS)
    F.watermarkFps = 0
    F.watermarkFrames = 0
    F.watermarkFrameStarted = os.clock()
    F.watermarkGameName = game.Name

    local function cleanWatermarkGameName(name)
        local result = {}
        for _, codepoint in utf8.codes(tostring(name or "")) do
            local emoji = (codepoint >= 0x1F300 and codepoint <= 0x1FAFF)
                or (codepoint >= 0x2700 and codepoint <= 0x27BF)
                or (codepoint >= 0x2600 and codepoint <= 0x26FF)
                or (codepoint >= 0x1F100 and codepoint <= 0x1F1FF)
            if not emoji then table.insert(result, utf8.char(codepoint)) end
        end
        local cleaned = table.concat(result):gsub("%s+", " ")
        cleaned = cleaned:match("^%s*(.-)%s*$") or cleaned
        return cleaned ~= "" and cleaned or "Roblox"
    end

    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name and info.Name ~= "" then F.watermarkGameName = info.Name end
    end)
    F.watermarkGameName = cleanWatermarkGameName(F.watermarkGameName)

    local watermark = create("Frame", {
        Name = "MillionwareWatermark", AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -9, 0, 10), Size = UDim2.fromOffset(120, 16),
        BackgroundColor3 = Color3.fromRGB(24, 23, 23), BackgroundTransparency = 0.5,
        ZIndex = 200, Parent = gui,
    })
    local watermarkAccent = create("Frame", {
        Name = "Accent", Position = UDim2.fromOffset(0, -3), Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = c3(Theme.scheme), ZIndex = 201, Parent = watermark,
    })
    create("Frame", {
        Name = "Shadow", Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(10, 10, 10), BackgroundTransparency = 0.45,
        ZIndex = 199, Parent = watermark,
    })
    local watermarkText = create("TextLabel", {
        Name = "WatermarkText", BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 0),
        Size = UDim2.new(1, -10, 1, 0), FontFace = Font.new("rbxasset://fonts/families/Roboto.json"),
        TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0.82, TextStrokeColor3 = BLACK,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        RichText = false, Text = "millionware.vip", ZIndex = 202, Parent = watermark,
    })
    library.Watermark = watermark
        F.watermark = watermark

    local function watermarkFieldEnabled(name)
        for _, selected in ipairs(F.watermarkFields) do
            if selected == name then return true end
        end
        return false
    end

    local function getWatermarkPing()
        local ping = 0
        pcall(function() ping = LocalPlayer:GetNetworkPing() * 1000 end)
        return math.max(0, math.floor(ping + 0.5))
    end

    local function watermarkValue(name)
        if name == "Username" then return LocalPlayer.Name end
        if name == "Display Name" then return LocalPlayer.DisplayName end
        if name == "Game" then return F.watermarkGameName end
        if name == "Ping" then return string.format("%dms", getWatermarkPing()) end
        if name == "FPS" then return string.format("%dfps", F.watermarkFps) end
        if name == "Players" then return string.format("%d/%d players", #Players:GetPlayers(), Players.MaxPlayers) end
        if name == "Place ID" then return "place " .. tostring(game.PlaceId) end
        if name == "Job ID" then return game.JobId ~= "" and ("job " .. game.JobId) or "studio server" end
        if name == "Account Age" then return tostring(LocalPlayer.AccountAge) .. "d account" end
        if name == "User ID" then return "uid " .. tostring(LocalPlayer.UserId) end
        if name == "Time" then return os.date("%H:%M:%S") end
        return nil
    end

    local function applyWatermarkWidth()
        local width = math.max(120, math.ceil(watermarkText.TextBounds.X) + 10)
        watermark.Size = UDim2.fromOffset(width, 16)
    end

    local function updateWatermark()
        watermark.Visible = F.watermarkEnabled
        if not F.watermarkEnabled then return end
        local parts = { "millionware.vip" }
        for _, name in ipairs(WATERMARK_FIELDS) do
            if watermarkFieldEnabled(name) then
                local value = watermarkValue(name)
                if value and value ~= "" then table.insert(parts, value) end
            end
        end
        watermarkText.Text = table.concat(parts, " | ")
        applyWatermarkWidth()
        task.defer(applyWatermarkWidth)
    end

    F.updateWatermark = updateWatermark
    F.watermarkFieldsOptions = WATERMARK_FIELDS
    F.defaultWatermarkFields = DEFAULT_WATERMARK_FIELDS

    connect(watermarkText:GetPropertyChangedSignal("TextBounds"), applyWatermarkWidth)
    connect(RunService.RenderStepped, function()
        F.watermarkFrames = F.watermarkFrames + 1
        local now = os.clock()
        local elapsed = now - F.watermarkFrameStarted
        if elapsed >= 0.5 then
            F.watermarkFps = math.max(0, math.floor(F.watermarkFrames / elapsed + 0.5))
            F.watermarkFrames = 0
            F.watermarkFrameStarted = now
        end
        watermarkAccent.BackgroundColor3 = c3(Colors.scheme)
    end)

    task.spawn(function()
        while F.alive and gui.Parent do
            updateWatermark()
            task.wait(1)
        end
    end)
    updateWatermark()
end

do
    local controls = library:AddSection("Examples", nil, "Controls", 1, 440)
    local basicToggle = controls:Checkbox("Example toggle", false, nil, { flag = "ExampleToggle" })
    controls:Checkbox("Toggle with color", true, nil, {
        flag = "ExampleColorToggle", color = PINK,
    })
    controls:Checkbox("Toggle with bind", false, nil, {
        flag = "ExampleBindToggle", keybind = Enum.KeyCode.G, mode = "Toggle",
    })
    controls:Checkbox("Toggle with two colors", true, nil, {
        flag = "ExampleTwoColors", color = { PINK, Color3.fromRGB(115, 175, 202) },
    })
    controls:Checkbox("Toggle with options", false, nil, {
        flag = "ExampleOptionsToggle",
        options = function(sub)
            sub:Checkbox("Extra toggle", false, nil, { flag = "ExampleExtraToggle" })
            sub:SliderInt("Extra amount", 0, 100, 25, nil, "%d%%", "ExampleExtraAmount")
            sub:Combo("Extra mode", { "Mode 1", "Mode 2" }, 1, nil, "ExampleExtraMode")
        end,
    })
    controls:Separator()
    controls:SliderInt("Example slider", 0, 100, 50, nil, "%d%%", "ExampleSlider")
    controls:SliderFloat("Example float", 0, 10, 2.5, nil, "%.1f", "ExampleFloat")
    controls:SliderInt("Example delay", 0, 1000, 100, nil, "%d ms", "ExampleDelay")
    controls:Combo("Example combo", { "Option 1", "Option 2", "Option 3" }, 1, nil, "ExampleCombo")
    controls:MultiCombo("Example multibox", { "Option 1", "Option 2", "Option 3", "Option 4" },
        { "Option 1", "Option 3" }, nil, "ExampleMultibox")
    controls:MultiCombo("Empty multibox", { "Alpha", "Beta", "Gamma" }, {}, nil, "ExampleEmptyMultibox")

    local extras = library:AddSection("Examples", nil, "Colors / Binds / Inputs", 2, 440)
    extras:ColorPicker("Example color", PINK, nil, 1, "ExampleColor")
    extras:ColorPicker("Example alpha", Color3.fromRGB(115, 175, 202), nil, 0.5, "ExampleAlpha")
    extras:Separator()
    extras:Keybind("Example bind", Enum.KeyCode.F, nil, "ExampleBind", { mode = "On Hotkey" })
    extras:Keybind("Unassigned bind", nil, nil, "ExampleUnassignedBind", { mode = "Toggle" })
    extras:Keybind("Mouse bind", Enum.UserInputType.MouseButton2, nil, "ExampleMouseBind", { mode = "On Hotkey" })
    extras:Separator()
    local status = extras:Label("Status: discord: 5nqs (Barlas)")
    extras:TextInput("Example text", "barlas", function(text)
        status:Set("Text: " .. tostring(text):sub(1, 28))
    end, "Enter text...", "ExampleText")
    extras:Button("Example button", function() status:Set("Status: button clicked") end)
    extras:Button("Toggle example", function() basicToggle:Toggle() end)
    extras:Button("Reset status", function() status:Set("Status: ready") end)
end

UI.settingsSection = library:AddSection("Settings", nil, "Menu", 1, 150)
UI.settingsSection:Keybind("Menu key", Enum.KeyCode.J, function(key)
    if key and typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then library:SetToggleKey(key) end
end, "Menu key", { noModeMenu = true })
UI.settingsSection:ColorPicker("Menu accent", PINK, function(color) library:SetAccent(color) end)
UI.settingsSection:Checkbox("Watermark", true, function(enabled)
    F.watermarkEnabled = enabled
    F.watermark.Visible = enabled
    if UI.watermarkFieldsItem then UI.settingsSection:SetItemVisible(UI.watermarkFieldsItem, enabled) end
    F.updateWatermark()
end, { flag = "Watermark" })
UI.settingsSection:MultiCombo("Watermark Info", F.watermarkFieldsOptions, F.defaultWatermarkFields, function(selected)
    F.watermarkFields = selected
    F.updateWatermark()
end, "Watermark Info")
UI.watermarkFieldsItem = UI.settingsSection.lastItem
UI.settingsSection:Button("Unload menu", function() library:Destroy() end)

UI.configSection = library:AddSection("Settings", nil, "Configs", 2, 260)
F.cfgName = ""
F.cfgSelected = nil
UI.configList = UI.configSection:Combo("Config", { "None" }, 1, function(v)
    F.cfgSelected = (v ~= "None") and v or nil
end, "__cfg_list")
UI.configNameBox = UI.configSection:TextInput("Config name", "", function(t) F.cfgName = t end, "new config name...", "__cfg_name")
local function cfgRefresh(select)
    local list = library:ListConfigs()
    if #list == 0 then list = { "None" } end
    local sel = select or F.cfgSelected
    UI.configList:SetItems(list, sel, true)
    local cur = UI.configList:Get()
    F.cfgSelected = (cur ~= "None") and cur or nil
end
local function cfgTarget()
    local typed = tostring(F.cfgName or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if typed ~= "" then return typed end
    return F.cfgSelected
end
UI.configSection:Button("Create config", function()
    local n = tostring(F.cfgName or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then return end
    local ok = library:SaveConfig(n)
    if ok then
        cfgRefresh(n); UI.configNameBox:Set(""); F.cfgName = ""
    end
end)
UI.configSection:Button("Save config", function()
    local n = cfgTarget()
    if not n then return end
    local ok = library:SaveConfig(n)
    if ok then cfgRefresh(n) end
end)
UI.configSection:Button("Load config", function()
    local n = F.cfgSelected
    if not n then return end
    library:LoadConfig(n)
end)
UI.configSection:Button("Delete config", function()
    local n = F.cfgSelected
    if not n then return end
    if library:DeleteConfig(n) then F.cfgSelected = nil; cfgRefresh() end
end)
UI.configSection:Button("Refresh list", function() cfgRefresh() end)
UI.configSection:Button("Set as autoload", function()
    local n = F.cfgSelected
    if not n then return end
    library:SetAutoloadConfig(n)
end)
UI.configSection:Button("Reset autoload", function()
    library:SetAutoloadConfig("")
end)
library.ConfigIgnore["__cfg_list"] = true
library.ConfigIgnore["__cfg_name"] = true
cfgRefresh()

applyPage()
do
    local auto = library:GetAutoloadConfig()
    if auto then
        task.defer(function()
            local ok = library:LoadConfig(auto)
            if ok then cfgRefresh(auto) end
        end)
    end
end
return library
