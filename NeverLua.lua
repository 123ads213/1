--[[
████████████████████████████████████████████████████████
█                                                      █
█          N E V E R L U A   U I   L I B               █
█       Neverlose-style from scratch · Roblox          █
█                                                      █
████████████████████████████████████████████████████████

    Usage:
        local NeverLua = loadstring(game:HttpGet("RAW_URL"))()
        local Window = NeverLua:CreateWindow({ ... })
        local Tab = Window:Tab({ Title="Rage", Category="AIMBOT" })
        local Sec = Tab:Section("MAIN")
        Sec:Toggle({ Flag="on", Title="Enabled", Default=true, Callback=function(v) end })

    GitHub: https://github.com/YourName/NeverLua
    Version: 1.0.0
]]

-- ═══════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")
local TextService       = game:GetService("TextService")

local cloneref = (cloneref or clonereference or function(i) return i end)
local RS   = cloneref(RunService)
local UIS  = cloneref(UserInputService)
local TS   = cloneref(TweenService)
local PL   = cloneref(Players)
local HTTP = cloneref(HttpService)

local LocalPlayer = PL.LocalPlayer

-- ═══════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════
local function tween(obj, info, props)
    TS:Create(obj, info, props):Play()
end

local function lerp(a, b, t) return a + (b - a) * t end

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local function round(x, step)
    step = step or 1
    return math.floor(x / step + 0.5) * step
end

local function formatNum(n, decimals)
    if decimals and decimals > 0 then
        return string.format("%." .. decimals .. "f", n)
    end
    return tostring(math.floor(n + 0.5))
end

local function getDecimals(step)
    local s = tostring(step)
    local dot = s:find("%.")
    if dot then return #s - dot else return 0 end
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k,v in pairs(t) do c[deepCopy(k)] = deepCopy(v) end
    return setmetatable(c, getmetatable(t))
end

local function tableFind(t, val)
    for i,v in ipairs(t) do if v == val then return i end end
end

local function signal()
    local cbs = {}
    return {
        Connect = function(_, fn) table.insert(cbs, fn) end,
        Fire    = function(_, ...) for _,fn in ipairs(cbs) do fn(...) end end,
    }
end

-- ═══════════════════════════════════════════════════════
--  PALETTE  —  Neverlose dark
-- ═══════════════════════════════════════════════════════
local C = {
    -- backgrounds
    Win         = Color3.fromHex("#0f1015"),   -- окно
    Sidebar     = Color3.fromHex("#11131a"),   -- сайдбар
    Content     = Color3.fromHex("#13151d"),   -- контент
    Section     = Color3.fromHex("#181b24"),   -- секция заголовок
    Row         = Color3.fromHex("#13151d"),   -- строка элемента
    RowHover    = Color3.fromHex("#1a1d27"),   -- hover строки
    Popup       = Color3.fromHex("#16192200"), -- попап
    -- borders
    Border      = Color3.fromHex("#252830"),
    BorderLight = Color3.fromHex("#2e3244"),
    -- accent
    Accent      = Color3.fromHex("#5865f2"),
    AccentDim   = Color3.fromHex("#3d49c7"),
    AccentGlow  = Color3.fromHex("#7775f2"),
    -- semantic
    Green       = Color3.fromHex("#30d980"),
    Red         = Color3.fromHex("#ef4f4f"),
    Yellow      = Color3.fromHex("#eca201"),
    Purple      = Color3.fromHex("#9b59f7"),
    -- text
    Text        = Color3.fromHex("#dde0f0"),
    TextSub     = Color3.fromHex("#8b90b0"),
    TextDim     = Color3.fromHex("#4a4f6a"),
    TextMicro   = Color3.fromHex("#2e3250"),
    -- toggle
    ToggleOn    = Color3.fromHex("#5865f2"),
    ToggleOff   = Color3.fromHex("#252a3a"),
    ToggleKnob  = Color3.fromHex("#ffffff"),
    -- slider
    SliderTrack = Color3.fromHex("#1e2030"),
    SliderFill  = Color3.fromHex("#5865f2"),
    SliderKnob  = Color3.fromHex("#ffffff"),
    -- topbar
    Topbar      = Color3.fromHex("#0d0f14"),
    -- category label
    CatLabel    = Color3.fromHex("#3a3f58"),
    -- sidebar item
    SideItem    = Color3.fromHex("#11131a"),
    SideActive  = Color3.fromHex("#1a1d2a"),
    SideHover   = Color3.fromHex("#161922"),
    -- dot
    DotActive   = Color3.fromHex("#5865f2"),
    DotInactive = Color3.fromHex("#2e3250"),
}

-- ═══════════════════════════════════════════════════════
--  FONT
-- ═══════════════════════════════════════════════════════
local F = {
    UI    = Enum.Font.GothamMedium,
    UIBold= Enum.Font.GothamBold,
    UISemi= Enum.Font.GothamSemibold,
    Mono  = Enum.Font.Code,
    Cat   = Enum.Font.GothamBold,
}

-- ═══════════════════════════════════════════════════════
--  TWEEN INFOS
-- ═══════════════════════════════════════════════════════
local TI = {
    Fast  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Med   = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow  = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Cubic = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Spring= TweenInfo.new(0.35, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}

-- ═══════════════════════════════════════════════════════
--  GUI ROOT
-- ═══════════════════════════════════════════════════════
local function getRoot()
    local ok, gui = pcall(function()
        return cloneref(game:GetService("CoreGui"))
    end)
    if ok then return gui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════
--  BASE ELEMENT BUILDER
-- ═══════════════════════════════════════════════════════
local function make(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function makeRound(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function makePad(parent, t, r, b, l)
    make("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        Parent        = parent,
    })
end

local function makeList(parent, dir, pad, fill, wrap)
    make("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, pad or 0),
        HorizontalFillMode  = fill or Enum.UIFlexAlignment.None,
        Wraps               = wrap or false,
        Parent              = parent,
    })
end

local function autoSize(obj, axis)
    local c = make("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = obj })
    _ = c -- suppress warning
    -- fallback: just set SizeConstraint
end

-- ═══════════════════════════════════════════════════════
--  SHADOW helper  (ImageLabel drop shadow)
-- ═══════════════════════════════════════════════════════
local function makeShadow(parent, size)
    size = size or 20
    make("ImageLabel", {
        Name            = "Shadow",
        AnchorPoint     = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image           = "rbxassetid://6014261993",
        ImageColor3     = Color3.new(0,0,0),
        ImageTransparency = 0.5,
        Position        = UDim2.new(0.5, 0, 0.5, 0),
        Size            = UDim2.new(1, size*2, 1, size*2),
        ZIndex          = -1,
        Parent          = parent,
    })
end

-- ═══════════════════════════════════════════════════════
--  SCROLLING FRAME helper
-- ═══════════════════════════════════════════════════════
local function makeScroll(parent, props)
    local sf = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = C.BorderLight,
        ScrollingDirection     = Enum.ScrollingDirection.Y,
        CanvasSize             = UDim2.new(0,0,0,0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ElasticBehavior        = Enum.ElasticBehavior.Never,
        Parent                 = parent,
    })
    for k,v in pairs(props or {}) do sf[k] = v end
    return sf
end

-- ═══════════════════════════════════════════════════════
--  THREE-DOTS ICON  (drawn as dots in a TextLabel)
-- ═══════════════════════════════════════════════════════
local function makeDotsBtn(parent, zIndex)
    local btn = make("TextButton", {
        Name               = "DotsBtn",
        BackgroundColor3   = Color3.fromHex("#1e2135"),
        BackgroundTransparency = 1,
        Text               = "•••",
        TextColor3         = C.TextDim,
        Font               = Enum.Font.GothamBold,
        TextSize           = 10,
        Size               = UDim2.new(0, 24, 0, 20),
        ZIndex             = zIndex or 5,
        AutoButtonColor    = false,
        Parent             = parent,
    })
    -- hover
    btn.MouseEnter:Connect(function()
        tween(btn, TI.Fast, { TextColor3 = C.TextSub })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TI.Fast, { TextColor3 = C.TextDim })
    end)
    return btn
end

-- ═══════════════════════════════════════════════════════
--  CONTEXT MENU  (three dots popup)
-- ═══════════════════════════════════════════════════════
local activeContextMenu = nil

local function closeContextMenu()
    if activeContextMenu then
        activeContextMenu:Destroy()
        activeContextMenu = nil
    end
end

local function openContextMenu(anchor, items, root)
    closeContextMenu()

    local absPos = anchor.AbsolutePosition
    local absSize = anchor.AbsoluteSize

    local menu = make("Frame", {
        Name               = "ContextMenu",
        BackgroundColor3   = Color3.fromHex("#1a1d2a"),
        BorderSizePixel    = 0,
        Position           = UDim2.new(0, absPos.X + absSize.X + 4, 0, absPos.Y),
        Size               = UDim2.new(0, 180, 0, 0),
        AutomaticSize      = Enum.AutomaticSize.Y,
        ZIndex             = 50,
        Parent             = root,
    })
    makeRound(menu, 8)
    make("UIStroke", {
        Color     = C.Border,
        Thickness = 1,
        Parent    = menu,
    })
    makePad(menu, 6, 0, 6, 0)
    makeList(menu, Enum.FillDirection.Vertical, 1)
    makeShadow(menu, 16)

    for _, item in ipairs(items) do
        if item.Divider then
            make("Frame", {
                BackgroundColor3 = C.Border,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, -16, 0, 1),
                BackgroundTransparency = 0,
                ZIndex           = 51,
                Parent           = menu,
            })
        else
            local row = make("TextButton", {
                BackgroundColor3       = Color3.fromHex("#1a1d2a"),
                BackgroundTransparency = 1,
                Text                   = "",
                Size                   = UDim2.new(1, 0, 0, 32),
                AutoButtonColor        = false,
                ZIndex                 = 51,
                Parent                 = menu,
            })
            makePad(row, 0, 12, 0, 12)
            local lbl = make("TextLabel", {
                BackgroundTransparency = 1,
                Text                   = item.Title or "",
                TextColor3             = item.Color or C.TextSub,
                Font                   = F.UI,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Size                   = UDim2.new(1, 0, 1, 0),
                ZIndex                 = 52,
                Parent                 = row,
            })
            row.MouseEnter:Connect(function()
                tween(row, TI.Fast, { BackgroundTransparency = 0 })
                tween(lbl, TI.Fast, { TextColor3 = C.Text })
            end)
            row.MouseLeave:Connect(function()
                tween(row, TI.Fast, { BackgroundTransparency = 1 })
                tween(lbl, TI.Fast, { TextColor3 = item.Color or C.TextSub })
            end)
            row.MouseButton1Click:Connect(function()
                closeContextMenu()
                if item.Callback then item.Callback() end
            end)
        end
    end

    activeContextMenu = menu

    -- close on outside click
    local conn
    conn = UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            task.defer(function()
                closeContextMenu()
                conn:Disconnect()
            end)
        end
    end)

    return menu
end

-- ═══════════════════════════════════════════════════════
--  KEYBIND PICKER  (modal overlay)
-- ═══════════════════════════════════════════════════════
local function openKeybindPicker(currentKey, onPick, root)
    local overlay = make("Frame", {
        BackgroundColor3       = Color3.new(0,0,0),
        BackgroundTransparency = 0.5,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 100,
        Parent                 = root,
    })
    local box = make("Frame", {
        AnchorPoint            = Vector2.new(0.5,0.5),
        BackgroundColor3       = Color3.fromHex("#1a1d2a"),
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5,0,0.5,0),
        Size                   = UDim2.new(0, 240, 0, 100),
        ZIndex                 = 101,
        Parent                 = overlay,
    })
    makeRound(box, 10)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = box })
    makeShadow(box, 20)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Text      = "Press any key to bind",
        TextColor3= C.TextSub,
        Font      = F.UI,
        TextSize  = 13,
        Size      = UDim2.new(1,0,0,40),
        Position  = UDim2.new(0,0,0,16),
        ZIndex    = 102,
        Parent    = box,
    })
    local curLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = currentKey or "None",
        TextColor3 = C.Accent,
        Font       = F.UIBold,
        TextSize   = 20,
        Size       = UDim2.new(1,0,0,32),
        Position   = UDim2.new(0,0,0,52),
        ZIndex     = 102,
        Parent     = box,
    })

    local conn
    conn = UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        local name
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            name = inp.KeyCode.Name
        elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
            name = "Mouse1"
        elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
            name = "Mouse2"
        end
        if name then
            conn:Disconnect()
            overlay:Destroy()
            if onPick then onPick(name) end
        end
    end)
end

-- ═══════════════════════════════════════════════════════
--  COLOR PICKER  (HSV wheel popup)
-- ═══════════════════════════════════════════════════════
local function openColorPicker(current, onPick, root)
    local H, S, V = Color3.toHSV(current or Color3.new(1,1,1))

    local popup = make("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromHex("#1a1d2a"),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(0, 240, 0, 290),
        ZIndex           = 60,
        Parent           = root,
    })
    makeRound(popup, 10)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = popup })
    makeShadow(popup, 20)
    makePad(popup, 14, 14, 14, 14)

    -- SV picker (gradient square)
    local svBox = make("ImageLabel", {
        BackgroundColor3       = Color3.fromHSV(H, 1, 1),
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 160),
        ZIndex                 = 61,
        Image                  = "rbxassetid://6923796443",
        Parent                 = popup,
    })
    makeRound(svBox, 6)

    -- SV cursor
    local svCursor = make("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 10, 0, 10),
        Position         = UDim2.new(S, 0, 1 - V, 0),
        ZIndex           = 63,
        Parent           = svBox,
    })
    makeRound(svCursor, 5)
    make("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1.5, Parent = svCursor })

    -- Hue bar
    local hueBar = make("ImageLabel", {
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 172),
        Size             = UDim2.new(1, 0, 0, 16),
        ZIndex           = 61,
        Image            = "rbxassetid://6923796440",
        Parent           = popup,
    })
    makeRound(hueBar, 4)

    -- Hue cursor
    local hueCursor = make("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 10, 1, 4),
        Position         = UDim2.new(H, 0, 0.5, 0),
        ZIndex           = 63,
        Parent           = hueBar,
    })
    makeRound(hueCursor, 3)
    make("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1.5, Parent = hueCursor })

    -- Preview + hex
    local preview = make("Frame", {
        BackgroundColor3 = Color3.fromHSV(H, S, V),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 200),
        Size             = UDim2.new(0, 36, 0, 36),
        ZIndex           = 61,
        Parent           = popup,
    })
    makeRound(preview, 6)

    local hexInput = make("TextBox", {
        BackgroundColor3       = Color3.fromHex("#13151d"),
        BorderSizePixel        = 0,
        PlaceholderText        = "#ffffff",
        Text                   = "",
        TextColor3             = C.Text,
        Font                   = F.Mono,
        TextSize               = 13,
        Position               = UDim2.new(0, 44, 0, 207),
        Size                   = UDim2.new(1, -44, 0, 22),
        ZIndex                 = 62,
        ClearTextOnFocus       = false,
        Parent                 = popup,
    })
    makeRound(hexInput, 5)
    makePad(hexInput, 0, 8, 0, 8)

    -- OK button
    local ok = make("TextButton", {
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        Text             = "Apply",
        TextColor3       = Color3.new(1,1,1),
        Font             = F.UIBold,
        TextSize         = 13,
        Position         = UDim2.new(0, 0, 0, 248),
        Size             = UDim2.new(1, 0, 0, 28),
        ZIndex           = 62,
        AutoButtonColor  = false,
        Parent           = popup,
    })
    makeRound(ok, 6)

    local function updateColor()
        local col = Color3.fromHSV(H, S, V)
        preview.BackgroundColor3 = col
        svBox.BackgroundColor3   = Color3.fromHSV(H, 1, 1)
        svCursor.Position        = UDim2.new(S, 0, 1 - V, 0)
        hueCursor.Position       = UDim2.new(H, 0, 0.5, 0)
        hexInput.Text            = "#" .. col:ToHex()
        if onPick then onPick(col) end
    end

    -- SV drag
    local svDrag = false
    svBox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if svDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = inp.Position - svBox.AbsolutePosition
            S = clamp(rel.X / svBox.AbsoluteSize.X, 0, 1)
            V = clamp(1 - rel.Y / svBox.AbsoluteSize.Y, 0, 1)
            updateColor()
        end
    end)

    -- Hue drag
    local hueDrag = false
    hueBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if hueDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = inp.Position - hueBar.AbsolutePosition
            H = clamp(rel.X / hueBar.AbsoluteSize.X, 0, 1)
            updateColor()
        end
    end)

    -- hex input
    hexInput.FocusLost:Connect(function()
        local hex = hexInput.Text:gsub("#","")
        if #hex == 6 then
            local ok2, col = pcall(Color3.fromHex, hex)
            if ok2 then
                H, S, V = Color3.toHSV(col)
                updateColor()
            end
        end
    end)

    ok.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)

    updateColor()
    return popup
end

-- ═══════════════════════════════════════════════════════
--  DROPDOWN MENU
-- ═══════════════════════════════════════════════════════
local activeDropdown = nil

local function closeDropdown()
    if activeDropdown then
        local dd = activeDropdown
        activeDropdown = nil
        tween(dd, TI.Fast, { Size = UDim2.new(dd.Size.X.Scale, dd.Size.X.Offset, 0, 0) })
        task.delay(0.15, function() if dd and dd.Parent then dd:Destroy() end end)
    end
end

local function openDropdown(anchor, values, current, multi, onSelect, root)
    closeDropdown()

    local absPos  = anchor.AbsolutePosition
    local absSize = anchor.AbsoluteSize
    local itemH   = 30
    local maxH    = math.min(#values * itemH + 12, 200)

    local frame = make("Frame", {
        BackgroundColor3 = Color3.fromHex("#1a1d2a"),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4),
        Size             = UDim2.new(0, absSize.X, 0, 0),
        ZIndex           = 40,
        ClipsDescendants = true,
        Parent           = root,
    })
    makeRound(frame, 8)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = frame })
    makeShadow(frame, 12)

    local scroll = makeScroll(frame, {
        Size     = UDim2.new(1, -4, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex   = 41,
    })
    makePad(scroll, 6, 4, 6, 4)
    makeList(scroll, Enum.FillDirection.Vertical, 1)

    local selected = {}
    if multi and type(current) == "table" then
        for _,v in ipairs(current) do selected[v] = true end
    elseif current then
        selected[current] = true
    end

    for _, val in ipairs(values) do
        if type(val) == "table" and val.Type == "Divider" then
            make("Frame", {
                BackgroundColor3 = C.Border,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, -8, 0, 1),
                ZIndex           = 42,
                Parent           = scroll,
            })
        else
            local title = type(val) == "table" and val.Title or tostring(val)
            local icon  = type(val) == "table" and val.Icon  or nil
            local locked= type(val) == "table" and val.Locked or false

            local row = make("TextButton", {
                BackgroundColor3       = Color3.fromHex("#1a1d2a"),
                BackgroundTransparency = 1,
                Text                   = "",
                Size                   = UDim2.new(1, 0, 0, itemH),
                AutoButtonColor        = false,
                ZIndex                 = 42,
                Parent                 = scroll,
            })
            makeRound(row, 5)
            makePad(row, 0, 8, 0, 8)

            -- checkmark
            local check = make("TextLabel", {
                BackgroundTransparency = 1,
                Text       = "✓",
                TextColor3 = C.Accent,
                Font       = F.UIBold,
                TextSize   = 12,
                Size       = UDim2.new(0, 16, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 43,
                Visible    = selected[title] == true,
                Parent     = row,
            })

            local lbl = make("TextLabel", {
                BackgroundTransparency = 1,
                Text       = title,
                TextColor3 = locked and C.TextDim or (selected[title] and C.Text or C.TextSub),
                Font       = F.UI,
                TextSize   = 13,
                Size       = UDim2.new(1, -20, 1, 0),
                Position   = UDim2.new(0, 20, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 43,
                Parent     = row,
            })

            if not locked then
                row.MouseEnter:Connect(function()
                    tween(row, TI.Fast, { BackgroundTransparency = 0 })
                    tween(lbl, TI.Fast, { TextColor3 = C.Text })
                end)
                row.MouseLeave:Connect(function()
                    tween(row, TI.Fast, { BackgroundTransparency = 1 })
                    tween(lbl, TI.Fast, { TextColor3 = selected[title] and C.Text or C.TextSub })
                end)
                row.MouseButton1Click:Connect(function()
                    if multi then
                        selected[title] = not selected[title]
                        check.Visible    = selected[title]
                        tween(lbl, TI.Fast, { TextColor3 = selected[title] and C.Text or C.TextSub })
                        local picks = {}
                        for k,v in pairs(selected) do if v then table.insert(picks, k) end end
                        if onSelect then onSelect(picks) end
                    else
                        closeDropdown()
                        if onSelect then onSelect(title) end
                    end
                end)
            end
        end
    end

    activeDropdown = frame
    tween(frame, TI.Fast, { Size = UDim2.new(0, absSize.X, 0, maxH) })

    -- outside click closes
    local conn
    conn = UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            task.defer(function()
                closeDropdown()
                conn:Disconnect()
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════
--  MAIN LIBRARY TABLE
-- ═══════════════════════════════════════════════════════
local NeverLua = {}
NeverLua.__index = NeverLua
NeverLua._version = "1.0.0"

-- ═══════════════════════════════════════════════════════
--  CONFIG SYSTEM
-- ═══════════════════════════════════════════════════════
local Config = {}
Config.__index = Config

function Config.new(folder)
    local self = setmetatable({}, Config)
    self.folder = folder or "NeverLua"
    self.flags  = {}
    return self
end

function Config:set(flag, val) if flag then self.flags[flag] = val end end
function Config:get(flag, def)
    if flag and self.flags[flag] ~= nil then return self.flags[flag] end
    return def
end

function Config:save(name)
    name = name or "default"
    if not (writefile and isfolder) then return false, "No filesystem access" end
    if not isfolder(self.folder) then makefolder(self.folder) end
    local ok, err = pcall(writefile, self.folder .. "/" .. name .. ".json",
        HTTP:JSONEncode(self.flags))
    return ok, err
end

function Config:load(name)
    name = name or "default"
    if not (readfile and isfile) then return false end
    local path = self.folder .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    local ok, data = pcall(function() return HTTP:JSONDecode(readfile(path)) end)
    if ok and type(data) == "table" then
        for k,v in pairs(data) do self.flags[k] = v end
        return true
    end
    return false
end

function Config:delete(name)
    if delfile and isfile then
        local path = self.folder .. "/" .. name .. ".json"
        if isfile(path) then delfile(path) return true end
    end
    return false
end

function Config:list()
    local out = {}
    if listfiles and isfolder and isfolder(self.folder) then
        for _, f in ipairs(listfiles(self.folder)) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end
    return out
end

-- ═══════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════
local WindowMeta = {}
WindowMeta.__index = WindowMeta

--[[
    NeverLua:CreateWindow({
        Title    = "Neverlose",
        Subtitle = "Counter-Strike 2",
        Icon     = "🎯",         -- emoji or RBX assetid
        Folder   = "neverlose",
        Size     = Vector2.new(860, 560),
        ToggleKey= Enum.KeyCode.Insert,
        User     = { Name="User", Days=570 },
        OnClose  = function() end,
    })
]]
function NeverLua:CreateWindow(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, WindowMeta)
    self._cfg      = cfg
    self._config   = Config.new(cfg.Folder or "NeverLua")
    self._tabs     = {}       -- { Tab objects }
    self._cats     = {}       -- { catName → { tabs } }
    self._catOrder = {}       -- ordered cat names
    self._activeTab= nil
    self._open     = true
    self._connections = {}

    local W = cfg.Size and cfg.Size.X or 860
    local H = cfg.Size and cfg.Size.Y or 560

    -- ── Root ScreenGui ──────────────────────────────────
    local gui = make("ScreenGui", {
        Name              = "NeverLua_" .. (cfg.Title or "Menu"),
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn      = false,
        DisplayOrder      = 999,
        IgnoreGuiInset    = true,
        Parent            = getRoot(),
    })
    self._gui = gui

    -- ── Main window frame ───────────────────────────────
    local win = make("Frame", {
        Name             = "Window",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.Win,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(0, W, 0, H),
        ZIndex           = 1,
        Parent           = gui,
    })
    makeRound(win, 12)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = win })
    makeShadow(win, 30)
    self._win = win

    -- ── Topbar (44px) ───────────────────────────────────
    local topbar = make("Frame", {
        Name             = "Topbar",
        BackgroundColor3 = C.Topbar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 44),
        ZIndex           = 5,
        Parent           = win,
    })
    -- round top only
    makeRound(topbar, 12)
    -- cover bottom corners
    make("Frame", {
        BackgroundColor3 = C.Topbar,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0.5, 0),
        ZIndex           = 4,
        Parent           = topbar,
    })
    make("Frame", {
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = 6,
        Parent           = topbar,
    })

    -- Mac-style window buttons
    local function macBtn(color, x)
        local b = make("Frame", {
            BackgroundColor3 = color,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, x, 0.5, -6),
            Size             = UDim2.new(0, 12, 0, 12),
            ZIndex           = 7,
            Parent           = topbar,
        })
        makeRound(b, 6)
        return b
    end
    local btnClose   = macBtn(Color3.fromHex("#ff5f56"), 14)
    local btnMinimize= macBtn(Color3.fromHex("#ffbd2e"), 32)
    local btnMax     = macBtn(Color3.fromHex("#27c93f"), 50)

    -- Title
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = cfg.Title or "NeverLua",
        TextColor3 = C.Text,
        Font       = F.UIBold,
        TextSize   = 14,
        Position   = UDim2.new(0, 72, 0, 0),
        Size       = UDim2.new(0, 200, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 7,
        Parent     = topbar,
    })

    -- Config dropdown (top right)
    local cfgLabel = make("TextButton", {
        BackgroundColor3 = Color3.fromHex("#1a1d2a"),
        BorderSizePixel  = 0,
        Text             = "  ⚙  Config  ∨",
        TextColor3       = C.TextSub,
        Font             = F.UI,
        TextSize         = 12,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -14, 0.5, 0),
        Size             = UDim2.new(0, 120, 0, 26),
        AutoButtonColor  = false,
        ZIndex           = 7,
        Parent           = topbar,
    })
    makeRound(cfgLabel, 6)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = cfgLabel })

    -- Search button
    make("TextButton", {
        BackgroundTransparency = 1,
        Text       = "🔍",
        TextColor3 = C.TextDim,
        Font       = F.UI,
        TextSize   = 14,
        AnchorPoint= Vector2.new(1, 0.5),
        Position   = UDim2.new(1, -144, 0.5, 0),
        Size       = UDim2.new(0, 24, 0, 24),
        ZIndex     = 7,
        Parent     = topbar,
    })

    -- Config dropdown logic
    cfgLabel.MouseButton1Click:Connect(function()
        openContextMenu(cfgLabel, {
            { Title = "Save Config",   Callback = function() self:_saveConfig() end },
            { Title = "Load Config",   Callback = function() self:_loadConfig() end },
            { Divider = true },
            { Title = "Reset Config",  Color = C.Red, Callback = function() self:_resetConfig() end },
        }, gui)
    end)

    -- ── Body (sidebar + content) ────────────────────────
    local body = make("Frame", {
        Name             = "Body",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, 0, 44),
        Size             = UDim2.new(1, 0, 1, -44),
        ZIndex           = 2,
        Parent           = win,
    })

    -- ── Sidebar (200px) ─────────────────────────────────
    local sidebar = make("Frame", {
        Name             = "Sidebar",
        BackgroundColor3 = C.Sidebar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 200, 1, 0),
        ZIndex           = 3,
        Parent           = body,
    })
    -- right border
    make("Frame", {
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -1, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        ZIndex           = 4,
        Parent           = sidebar,
    })
    -- round bottom-left only (top-left already from win)
    local sbScroll = makeScroll(sidebar, {
        Position = UDim2.new(0, 0, 0, 0),
        Size     = UDim2.new(1, 0, 1, -52),
        ZIndex   = 4,
    })
    makePad(sbScroll, 10, 4, 10, 4)
    makeList(sbScroll, Enum.FillDirection.Vertical, 2)
    self._sidebar = sbScroll

    -- User card (bottom of sidebar)
    local userCard = make("Frame", {
        BackgroundColor3 = Color3.fromHex("#0e1014"),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 52),
        ZIndex           = 4,
        Parent           = sidebar,
    })
    make("Frame", {
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = 5,
        Parent           = userCard,
    })
    makePad(userCard, 0, 8, 0, 12)
    local userIcon = make("Frame", {
        BackgroundColor3 = Color3.fromHex("#1e2135"),
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 32, 0, 32),
        Position         = UDim2.new(0, 0, 0.5, -16),
        ZIndex           = 5,
        Parent           = userCard,
    })
    makeRound(userIcon, 16)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = "👤",
        TextSize   = 15,
        Size       = UDim2.new(1,0,1,0),
        ZIndex     = 6,
        Parent     = userIcon,
    })
    local uName = cfg.User and cfg.User.Name or "User"
    local uDays = cfg.User and cfg.User.Days or 0
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = uName,
        TextColor3 = C.Text,
        Font       = F.UISemi,
        TextSize   = 13,
        Position   = UDim2.new(0, 42, 0, 8),
        Size       = UDim2.new(1, -56, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 5,
        Parent     = userCard,
    })
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = uDays .. " days left",
        TextColor3 = C.TextDim,
        Font       = F.UI,
        TextSize   = 11,
        Position   = UDim2.new(0, 42, 0, 26),
        Size       = UDim2.new(1, -56, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 5,
        Parent     = userCard,
    })
    make("TextButton", {
        BackgroundTransparency = 1,
        Text       = "›",
        TextColor3 = C.TextDim,
        Font       = F.UIBold,
        TextSize   = 18,
        AnchorPoint= Vector2.new(1, 0.5),
        Position   = UDim2.new(1, 0, 0.5, 0),
        Size       = UDim2.new(0, 20, 0, 20),
        ZIndex     = 6,
        Parent     = userCard,
    })

    -- ── Content area ────────────────────────────────────
    local contentArea = make("Frame", {
        Name             = "Content",
        BackgroundColor3 = C.Content,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 200, 0, 0),
        Size             = UDim2.new(1, -200, 1, 0),
        ZIndex           = 2,
        ClipsDescendants = true,
        Parent           = body,
    })
    self._content = contentArea
    self._gui = gui

    -- ── Dragging ─────────────────────────────────────────
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = win.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ── Toggle key ───────────────────────────────────────
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.Insert
    local toggleConn = UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == toggleKey then
            self._open = not self._open
            win.Visible = self._open
        end
    end)
    table.insert(self._connections, toggleConn)

    -- ── Close button ─────────────────────────────────────
    btnClose.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Destroy()
        end
    end)
    btnMinimize.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            self._open = false
            win.Visible = false
        end
    end)

    return self
end

-- ═══════════════════════════════════════════════════════
--  SIDEBAR: add category + tab items
-- ═══════════════════════════════════════════════════════

--[[
    Window:Tab({
        Title    = "Rage",
        Category = "AIMBOT",
        Icon     = "🎯",    -- emoji
    })
    returns TabObject
]]
function WindowMeta:Tab(cfg2)
    cfg2 = cfg2 or {}
    local catName = cfg2.Category or "MENU"

    -- Create category label if new
    if not self._cats[catName] then
        self._cats[catName] = {}
        table.insert(self._catOrder, catName)

        -- Category label
        make("TextLabel", {
            BackgroundTransparency = 1,
            Text       = catName,
            TextColor3 = C.CatLabel,
            Font       = F.Cat,
            TextSize   = 10,
            Size       = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 5,
            Parent     = self._sidebar,
        })
    end

    -- Sidebar item button
    local item = make("TextButton", {
        BackgroundColor3       = C.SideItem,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Text                   = "",
        Size                   = UDim2.new(1, 0, 0, 34),
        AutoButtonColor        = false,
        ZIndex                 = 5,
        Parent                 = self._sidebar,
    })
    makeRound(item, 7)

    -- Active indicator bar
    local indicator = make("Frame", {
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.15, 0),
        Size             = UDim2.new(0, 3, 0.7, 0),
        ZIndex           = 6,
        Visible          = false,
        Parent           = item,
    })
    makeRound(indicator, 2)

    -- Dot
    local dot = make("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.DotInactive,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 18, 0.5, 0),
        Size             = UDim2.new(0, 6, 0, 6),
        ZIndex           = 6,
        Parent           = item,
    })
    makeRound(dot, 3)

    -- Icon / Emoji
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = cfg2.Icon or "",
        TextSize   = 14,
        Position   = UDim2.new(0, 8, 0, 0),
        Size       = UDim2.new(0, 22, 1, 0),
        ZIndex     = 6,
        Parent     = item,
    })

    -- Title
    local itemTitle = make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = cfg2.Title or "Tab",
        TextColor3 = C.TextSub,
        Font       = F.UISemi,
        TextSize   = 13,
        Position   = UDim2.new(0, 36, 0, 0),
        Size       = UDim2.new(1, -44, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 6,
        Parent     = item,
    })

    -- Content page
    local page = make("Frame", {
        Name             = "Page_" .. (cfg2.Title or ""),
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Visible          = false,
        ZIndex           = 2,
        Parent           = self._content,
    })

    -- Tab object
    local tab = {
        _item      = item,
        _indicator = indicator,
        _dot       = dot,
        _title     = itemTitle,
        _page      = page,
        _win       = self,
        _sections  = {},
        _cols      = {},   -- column frames
    }

    -- Page inner layout (columns: left + right, each scrollable)
    local colLeft = makeScroll(page, {
        Position  = UDim2.new(0, 0, 0, 0),
        Size      = UDim2.new(0.5, -1, 1, 0),
        ZIndex    = 3,
    })
    makePad(colLeft, 12, 12, 12, 12)
    makeList(colLeft, Enum.FillDirection.Vertical, 8)

    local divider = make("Frame", {
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, -1, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        ZIndex           = 3,
        Parent           = page,
    })

    local colRight = makeScroll(page, {
        Position  = UDim2.new(0.5, 1, 0, 0),
        Size      = UDim2.new(0.5, -1, 1, 0),
        ZIndex    = 3,
    })
    makePad(colRight, 12, 12, 12, 12)
    makeList(colRight, Enum.FillDirection.Vertical, 8)

    tab._colLeft  = colLeft
    tab._colRight = colRight
    tab._divider  = divider

    -- Activate function
    function tab:Activate()
        -- deactivate all
        for _, t in ipairs(self._win._tabs) do
            t._page.Visible                  = false
            tween(t._item, TI.Fast, { BackgroundTransparency = 1 })
            tween(t._title, TI.Fast, { TextColor3 = C.TextSub })
            tween(t._dot, TI.Fast, { BackgroundColor3 = C.DotInactive })
            t._indicator.Visible = false
        end
        -- activate self
        self._page.Visible = true
        tween(self._item, TI.Fast, { BackgroundTransparency = 0 })
        tween(self._title, TI.Fast, { TextColor3 = C.Text })
        tween(self._dot, TI.Fast, { BackgroundColor3 = C.DotActive })
        self._indicator.Visible = true
        self._win._activeTab = self
    end

    -- Click
    item.MouseButton1Click:Connect(function()
        tab:Activate()
    end)
    item.MouseEnter:Connect(function()
        if self._win._activeTab ~= tab then
            tween(item, TI.Fast, { BackgroundTransparency = 0.6 })
            tween(itemTitle, TI.Fast, { TextColor3 = C.Text })
        end
    end)
    item.MouseLeave:Connect(function()
        if self._win._activeTab ~= tab then
            tween(item, TI.Fast, { BackgroundTransparency = 1 })
            tween(itemTitle, TI.Fast, { TextColor3 = C.TextSub })
        end
    end)

    table.insert(self._tabs, tab)
    table.insert(self._cats[catName], tab)

    -- Auto-activate first tab
    if #self._tabs == 1 then tab:Activate() end

    setmetatable(tab, { __index = TabAPI })
    return tab
end

-- ═══════════════════════════════════════════════════════
--  TAB API  (sections, elements)
-- ═══════════════════════════════════════════════════════
TabAPI = {}
TabAPI.__index = TabAPI

--[[
    tab:Section("MAIN")            → left column
    tab:Section("OTHER", "right")  → right column
    returns SectionObject with element methods
]]
function TabAPI:Section(title, col)
    col = col or "left"
    local parent = col == "right" and self._colRight or self._colLeft

    -- Section container
    local sec = make("Frame", {
        Name             = "Sec_" .. (title or ""),
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        ZIndex           = 3,
        Parent           = parent,
    })
    makeList(sec, Enum.FillDirection.Vertical, 0)

    if title and title ~= "" then
        -- Section header
        local hdr = make("Frame", {
            BackgroundColor3 = Color3.fromHex("#181b24"),
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 0, 28),
            ZIndex           = 4,
            Parent           = sec,
        })
        makePad(hdr, 0, 10, 0, 10)
        make("TextLabel", {
            BackgroundTransparency = 1,
            Text       = title,
            TextColor3 = C.TextDim,
            Font       = F.Cat,
            TextSize   = 10,
            Size       = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            LetterSpacing  = 2,
            ZIndex     = 5,
            Parent     = hdr,
        })
    end

    -- Elements container
    local elems = make("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        ZIndex           = 3,
        Parent           = sec,
    })
    makeList(elems, Enum.FillDirection.Vertical, 0)

    -- Section proxy
    local secObj = {
        _frame = sec,
        _elems = elems,
        _tab   = self,
        _win   = self._win,
    }
    setmetatable(secObj, { __index = SectionAPI })
    table.insert(self._sections, secObj)
    return secObj
end

-- ═══════════════════════════════════════════════════════
--  SECTION API  (elements)
-- ═══════════════════════════════════════════════════════
SectionAPI = {}
SectionAPI.__index = SectionAPI

-- ── Row builder (base for all elements) ──────────────────
local function makeRow(parent, zIndex)
    local row = make("Frame", {
        BackgroundColor3       = C.Row,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 38),
        ZIndex                 = zIndex or 4,
        Parent                 = parent,
    })
    -- bottom separator
    make("Frame", {
        BackgroundColor3 = C.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = zIndex or 4,
        Parent           = row,
    })
    makePad(row, 0, 10, 0, 10)

    -- hover
    row.MouseEnter:Connect(function()
        tween(row, TI.Fast, { BackgroundTransparency = 0 })
    end)
    row.MouseLeave:Connect(function()
        tween(row, TI.Fast, { BackgroundTransparency = 1 })
    end)

    return row
end

local function makeRowTitle(parent, title, desc, zIndex)
    local lbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = title or "",
        TextColor3 = C.Text,
        Font       = F.UI,
        TextSize   = 13,
        Size       = UDim2.new(0.5, 0, 0, 18),
        Position   = UDim2.new(0, 0, 0.5, desc and -10 or -9),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = zIndex or 5,
        Parent     = parent,
    })
    if desc and desc ~= "" then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Text       = desc,
            TextColor3 = C.TextDim,
            Font       = F.UI,
            TextSize   = 11,
            Size       = UDim2.new(0.6, 0, 0, 14),
            Position   = UDim2.new(0, 0, 0.5, 2),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = zIndex or 5,
            Parent     = parent,
        })
    end
    return lbl
end

-- ── TOGGLE ───────────────────────────────────────────────
--[[
    sec:Toggle({
        Flag     = "RageEnabled",
        Title    = "Enabled",
        Desc     = "",
        Default  = true,
        Locked   = false,
        Dots     = true,
        Callback = function(v) end,
    })
]]
function SectionAPI:Toggle(cfg3)
    cfg3 = cfg3 or {}
    local flag    = cfg3.Flag
    local val     = self._win._config:get(flag, cfg3.Default)
    if type(val) ~= "boolean" then val = cfg3.Default == true end

    local row = makeRow(self._elems)
    makeRowTitle(row, cfg3.Title, cfg3.Desc)

    -- right side
    local right = make("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position    = UDim2.new(1, 0, 0.5, 0),
        Size        = UDim2.new(0, 60, 0, 20),
        ZIndex      = 5,
        Parent      = row,
    })
    makeList(right, Enum.FillDirection.Horizontal, 6)

    -- dots btn
    if cfg3.Dots ~= false then
        local dots = makeDotsBtn(right, 6)
        dots.MouseButton1Click:Connect(function()
            openContextMenu(dots, {
                { Title = "Always", Callback = function() end },
                { Title = "On Key", Callback = function() end },
                { Divider = true },
                { Title = cfg3.Locked and "Unlock" or "Lock",
                  Callback = function() end },
            }, self._win._gui)
        end)
    end

    -- Toggle switch
    local track = make("Frame", {
        BackgroundColor3 = val and C.ToggleOn or C.ToggleOff,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 36, 0, 20),
        ZIndex           = 5,
        Parent           = right,
    })
    makeRound(track, 10)

    local knob = make("Frame", {
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = C.ToggleKnob,
        BorderSizePixel  = 0,
        Position         = val and UDim2.new(0, 18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size             = UDim2.new(0, 16, 0, 16),
        ZIndex           = 6,
        Parent           = track,
    })
    makeRound(knob, 8)

    local function setVal(v, animate)
        val = v
        self._win._config:set(flag, v)
        local targetPos = v and UDim2.new(0, 18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local targetCol = v and C.ToggleOn or C.ToggleOff
        if animate then
            tween(knob,  TI.Fast, { Position = targetPos })
            tween(track, TI.Fast, { BackgroundColor3 = targetCol })
        else
            knob.Position           = targetPos
            track.BackgroundColor3  = targetCol
        end
        if cfg3.Callback then cfg3.Callback(v) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            if not cfg3.Locked then setVal(not val, true) end
        end
    end)
    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            if not cfg3.Locked then setVal(not val, true) end
        end
    end)

    return {
        Set = function(_, v) setVal(v, true) end,
        Get = function() return val end,
    }
end

-- ── SLIDER ───────────────────────────────────────────────
--[[
    sec:Slider({
        Flag    = "FieldOfView",
        Title   = "Field of View",
        Min     = 0,
        Max     = 180,
        Default = 90,
        Step    = 0.5,
        Suffix  = "°",
        Dots    = true,
        Callback= function(v) end,
    })
]]
function SectionAPI:Slider(cfg3)
    cfg3 = cfg3 or {}
    local flag = cfg3.Flag
    local mn   = cfg3.Min or 0
    local mx   = cfg3.Max or 100
    local step = cfg3.Step or 1
    local dec  = getDecimals(step)
    local val  = clamp(self._win._config:get(flag, cfg3.Default or mn), mn, mx)

    local row = makeRow(self._elems)
    row.Size = UDim2.new(1, 0, 0, 50)
    makeRowTitle(row, cfg3.Title, cfg3.Desc)

    -- Value label (top right)
    local valLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = formatNum(val, dec) .. (cfg3.Suffix or ""),
        TextColor3 = C.TextSub,
        Font       = F.Mono,
        TextSize   = 12,
        AnchorPoint= Vector2.new(1, 0),
        Position   = UDim2.new(1, 0, 0, 8),
        Size       = UDim2.new(0, 60, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex     = 5,
        Parent     = row,
    })

    -- Dots
    if cfg3.Dots ~= false then
        local dots = makeDotsBtn(row, 6)
        dots.AnchorPoint = Vector2.new(1, 0)
        dots.Position    = UDim2.new(1, -62, 0, 6)
        dots.MouseButton1Click:Connect(function()
            openContextMenu(dots, {
                { Title = "Set Value...", Callback = function() end },
                { Divider = true },
                { Title = "Reset",        Callback = function()
                    setSliderVal(cfg3.Default or mn, true)
                end },
            }, self._win._gui)
        end)
    end

    -- Track
    local trackBg = make("Frame", {
        BackgroundColor3 = C.SliderTrack,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, -10),
        Size             = UDim2.new(1, 0, 0, 4),
        ZIndex           = 5,
        Parent           = row,
    })
    makeRound(trackBg, 2)

    local fill = make("Frame", {
        BackgroundColor3 = C.SliderFill,
        BorderSizePixel  = 0,
        Size             = UDim2.new((val - mn) / (mx - mn), 0, 1, 0),
        ZIndex           = 6,
        Parent           = trackBg,
    })
    makeRound(fill, 2)

    local knob = make("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.SliderKnob,
        BorderSizePixel  = 0,
        Position         = UDim2.new((val - mn) / (mx - mn), 0, 0.5, 0),
        Size             = UDim2.new(0, 12, 0, 12),
        ZIndex           = 7,
        Parent           = trackBg,
    })
    makeRound(knob, 6)
    make("UIStroke", { Color = Color3.fromHex("#3a3f58"), Thickness = 1.5, Parent = knob })

    local function setSliderVal(v, animate)
        v   = clamp(round(v, step), mn, mx)
        val = v
        self._win._config:set(flag, v)
        local t = (v - mn) / (mx - mn)
        if animate then
            tween(fill,  TI.Fast, { Size = UDim2.new(t, 0, 1, 0) })
            tween(knob,  TI.Fast, { Position = UDim2.new(t, 0, 0.5, 0) })
        else
            fill.Size     = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, 0, 0.5, 0)
        end
        valLbl.Text = formatNum(v, dec) .. (cfg3.Suffix or "")
        if cfg3.Callback then cfg3.Callback(v) end
    end

    local dragging = false
    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local rel = inp.Position.X - trackBg.AbsolutePosition.X
            setSliderVal(mn + (rel / trackBg.AbsoluteSize.X) * (mx - mn))
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = inp.Position.X - trackBg.AbsolutePosition.X
            setSliderVal(mn + (rel / trackBg.AbsoluteSize.X) * (mx - mn))
        end
    end)

    return {
        Set = function(_, v) setSliderVal(v, true) end,
        Get = function() return val end,
    }
end

-- ── DROPDOWN ─────────────────────────────────────────────
--[[
    sec:Dropdown({
        Flag   = "Target",
        Title  = "Target",
        Values = { "Highest Damage", "Closest", "Random" },
        Default = "Highest Damage",
        Multi  = false,
        Callback = function(v) end,
    })
    -- Advanced (arrows → subpanel):
    sec:Dropdown({
        Title  = "Pitch",
        Arrow  = true,   -- show › arrow (opens right panel style)
        Values = { "Down", "Up", "Zero", "Fake" },
        Callback = function(v) end,
    })
]]
function SectionAPI:Dropdown(cfg3)
    cfg3 = cfg3 or {}
    local flag  = cfg3.Flag
    local multi = cfg3.Multi
    local vals  = cfg3.Values or {}
    local saved = self._win._config:get(flag, cfg3.Default)
    local current = saved or (multi and {} or (vals[1] and (type(vals[1])=="table" and vals[1].Title or vals[1])))

    local row = makeRow(self._elems)
    makeRowTitle(row, cfg3.Title, cfg3.Desc)

    -- Value display + arrow
    local right = make("TextButton", {
        BackgroundColor3       = Color3.fromHex("#1a1d27"),
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, 0, 0.5, 0),
        Size                   = UDim2.new(0, 130, 0, 24),
        AutoButtonColor        = false,
        Text                   = "",
        ZIndex                 = 5,
        Parent                 = row,
    })
    makeRound(right, 5)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = right })
    makePad(right, 0, 8, 0, 8)

    local currentLbl = make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = multi and (type(current)=="table" and table.concat(current,", ") or "") or tostring(current or ""),
        TextColor3 = C.TextSub,
        Font       = F.UI,
        TextSize   = 12,
        Size       = UDim2.new(1, -16, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        ZIndex     = 6,
        Parent     = right,
    })
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = "∨",
        TextColor3 = C.TextDim,
        Font       = F.UIBold,
        TextSize   = 10,
        AnchorPoint= Vector2.new(1, 0.5),
        Position   = UDim2.new(1, 0, 0.5, 0),
        Size       = UDim2.new(0, 14, 1, 0),
        ZIndex     = 6,
        Parent     = right,
    })

    local function onSelect(picked)
        current = picked
        self._win._config:set(flag, picked)
        if multi and type(picked) == "table" then
            currentLbl.Text = table.concat(picked, ", ")
        else
            currentLbl.Text = tostring(picked)
        end
        if cfg3.Callback then cfg3.Callback(picked) end
    end

    right.MouseButton1Click:Connect(function()
        openDropdown(right, vals, current, multi, onSelect, self._win._gui)
    end)
    right.MouseEnter:Connect(function()
        tween(right, TI.Fast, { BackgroundColor3 = C.RowHover })
    end)
    right.MouseLeave:Connect(function()
        tween(right, TI.Fast, { BackgroundColor3 = Color3.fromHex("#1a1d27") })
    end)

    -- Arrow row variant (like Pitch › / Yaw › in NL anti-aim)
    if cfg3.Arrow then
        right:Destroy()
        local arrow = make("TextLabel", {
            BackgroundTransparency = 1,
            Text       = "›",
            TextColor3 = C.TextDim,
            Font       = F.UIBold,
            TextSize   = 18,
            AnchorPoint= Vector2.new(1, 0.5),
            Position   = UDim2.new(1, 0, 0.5, 0),
            Size       = UDim2.new(0, 20, 1, 0),
            ZIndex     = 5,
            Parent     = row,
        })
        row.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                openDropdown(row, vals, current, multi, onSelect, self._win._gui)
            end
        end)
    end

    return {
        Set = function(_, v) onSelect(v) end,
        Get = function() return current end,
    }
end

-- ── BUTTON ───────────────────────────────────────────────
--[[
    sec:Button({
        Title    = "Execute",
        Color    = Color3.fromHex("#5865f2"),
        Callback = function() end,
    })
]]
function SectionAPI:Button(cfg3)
    cfg3 = cfg3 or {}

    local row = makeRow(self._elems)
    row.BackgroundTransparency = 1

    local btn = make("TextButton", {
        BackgroundColor3 = cfg3.Color or C.Elevated or Color3.fromHex("#1e2135"),
        BorderSizePixel  = 0,
        Text             = cfg3.Title or "Button",
        TextColor3       = cfg3.TextColor or C.Text,
        Font             = F.UISemi,
        TextSize         = 13,
        Size             = UDim2.new(1, 0, 0, 30),
        AutoButtonColor  = false,
        ZIndex           = 5,
        Parent           = row,
    })
    makeRound(btn, 6)

    btn.MouseEnter:Connect(function()
        tween(btn, TI.Fast, { BackgroundColor3 = (cfg3.Color or Color3.fromHex("#1e2135")):Lerp(Color3.new(1,1,1), 0.08) })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TI.Fast, { BackgroundColor3 = cfg3.Color or Color3.fromHex("#1e2135") })
    end)
    btn.MouseButton1Click:Connect(function()
        if cfg3.Callback then cfg3.Callback() end
    end)

    return btn
end

-- ── INPUT ────────────────────────────────────────────────
--[[
    sec:Input({
        Flag        = "PlayerName",
        Title       = "Player",
        Placeholder = "Enter name...",
        Default     = "",
        Callback    = function(v) end,
    })
]]
function SectionAPI:Input(cfg3)
    cfg3 = cfg3 or {}
    local flag = cfg3.Flag
    local val  = self._win._config:get(flag, cfg3.Default or "")

    local row = makeRow(self._elems)
    row.Size  = UDim2.new(1, 0, 0, 52)
    makeRowTitle(row, cfg3.Title, cfg3.Desc)

    local box = make("TextBox", {
        BackgroundColor3   = Color3.fromHex("#0e1014"),
        BorderSizePixel    = 0,
        PlaceholderText    = cfg3.Placeholder or "Enter value...",
        PlaceholderColor3  = C.TextDim,
        Text               = tostring(val),
        TextColor3         = C.Text,
        Font               = F.UI,
        TextSize           = 12,
        AnchorPoint        = Vector2.new(0, 1),
        Position           = UDim2.new(0, 0, 1, -8),
        Size               = UDim2.new(1, 0, 0, 22),
        ZIndex             = 5,
        ClearTextOnFocus   = false,
        Parent             = row,
    })
    makeRound(box, 5)
    makePad(box, 0, 8, 0, 8)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = box })

    box.FocusLost:Connect(function()
        val = box.Text
        self._win._config:set(flag, val)
        if cfg3.Callback then cfg3.Callback(val) end
    end)

    box.Focused:Connect(function()
        tween(box, TI.Fast, { BackgroundColor3 = Color3.fromHex("#14161e") })
        make("UIStroke", { Color = C.Accent, Thickness = 1, Parent = box })
    end)
    box.FocusLost:Connect(function()
        tween(box, TI.Fast, { BackgroundColor3 = Color3.fromHex("#0e1014") })
    end)

    return {
        Set = function(_, v) box.Text = tostring(v); val = v end,
        Get = function() return val end,
    }
end

-- ── COLORPICKER ──────────────────────────────────────────
--[[
    sec:Colorpicker({
        Flag     = "ESP_Color",
        Title    = "ESP Color",
        Default  = Color3.fromHex("#5865f2"),
        Callback = function(col) end,
    })
]]
function SectionAPI:Colorpicker(cfg3)
    cfg3 = cfg3 or {}
    local flag = cfg3.Flag
    local val  = self._win._config:get(flag, cfg3.Default or C.Accent)
    if type(val) ~= "userdata" then val = cfg3.Default or C.Accent end

    local row = makeRow(self._elems)
    makeRowTitle(row, cfg3.Title, cfg3.Desc)

    local preview = make("TextButton", {
        BackgroundColor3 = val,
        BorderSizePixel  = 0,
        Text             = "",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, 0, 0.5, 0),
        Size             = UDim2.new(0, 24, 0, 24),
        AutoButtonColor  = false,
        ZIndex           = 5,
        Parent           = row,
    })
    makeRound(preview, 5)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = preview })

    preview.MouseButton1Click:Connect(function()
        openColorPicker(val, function(c)
            val = c
            preview.BackgroundColor3 = c
            self._win._config:set(flag, c)
            if cfg3.Callback then cfg3.Callback(c) end
        end, self._win._gui)
    end)

    return {
        Set = function(_, c) val = c; preview.BackgroundColor3 = c end,
        Get = function() return val end,
    }
end

-- ── KEYBIND ──────────────────────────────────────────────
--[[
    sec:Keybind({
        Flag     = "AimbotKey",
        Title    = "Activation Key",
        Default  = "Mouse2",
        Callback = function(key) end,
    })
]]
function SectionAPI:Keybind(cfg3)
    cfg3 = cfg3 or {}
    local flag = cfg3.Flag
    local val  = self._win._config:get(flag, cfg3.Default or "None")

    local row = makeRow(self._elems)
    makeRowTitle(row, cfg3.Title, cfg3.Desc)

    local kbBtn = make("TextButton", {
        BackgroundColor3 = Color3.fromHex("#1a1d27"),
        BorderSizePixel  = 0,
        Text             = "[" .. tostring(val) .. "]",
        TextColor3       = C.Accent,
        Font             = F.Mono,
        TextSize         = 12,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, 0, 0.5, 0),
        Size             = UDim2.new(0, 80, 0, 24),
        AutoButtonColor  = false,
        ZIndex           = 5,
        Parent           = row,
    })
    makeRound(kbBtn, 5)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = kbBtn })

    kbBtn.MouseButton1Click:Connect(function()
        kbBtn.Text      = "[...]"
        kbBtn.TextColor3 = C.Yellow
        openKeybindPicker(val, function(key)
            val = key
            kbBtn.Text       = "[" .. key .. "]"
            kbBtn.TextColor3 = C.Accent
            self._win._config:set(flag, key)
            if cfg3.Callback then cfg3.Callback(key) end
        end, self._win._gui)
    end)

    return {
        Set = function(_, k) val = k; kbBtn.Text = "[" .. k .. "]" end,
        Get = function() return val end,
    }
end

-- ── LABEL (text / description) ───────────────────────────
function SectionAPI:Label(cfg3)
    cfg3 = cfg3 or {}
    local row = make("Frame", {
        BackgroundTransparency = 1,
        Size   = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
        Parent = self._elems,
    })
    makePad(row, 6, 10, 6, 10)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text        = cfg3.Title or "",
        TextColor3  = cfg3.Color or C.TextSub,
        Font        = cfg3.Bold and F.UISemi or F.UI,
        TextSize    = cfg3.Size or 12,
        TextWrapped = true,
        Size        = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex      = 5,
        Parent      = row,
    })
end

-- ── SEPARATOR ────────────────────────────────────────────
function SectionAPI:Separator()
    make("Frame", {
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = 4,
        Parent           = self._elems,
    })
end

-- ═══════════════════════════════════════════════════════
--  WINDOW METHODS: notify, config helpers
-- ═══════════════════════════════════════════════════════

local notifyQueue = {}
local notifyOffset = 0

function WindowMeta:Notify(cfg2)
    cfg2 = cfg2 or {}
    notifyOffset = notifyOffset + 1
    local idx = notifyOffset

    local toast = make("Frame", {
        BackgroundColor3 = Color3.fromHex("#1a1d2a"),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(1, 1),
        Position         = UDim2.new(1, -16, 1, -(16 + (idx-1)*80)),
        Size             = UDim2.new(0, 0, 0, 64),
        ZIndex           = 200,
        ClipsDescendants = true,
        Parent           = self._gui,
    })
    makeRound(toast, 10)
    make("UIStroke", { Color = C.Border, Thickness = 1, Parent = toast })
    makeShadow(toast, 12)

    -- Accent bar left
    make("Frame", {
        BackgroundColor3 = cfg2.Color or C.Accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 3, 1, 0),
        ZIndex           = 201,
        Parent           = toast,
    })

    makePad(toast, 12, 14, 12, 18)

    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = cfg2.Title or "",
        TextColor3 = C.Text,
        Font       = F.UIBold,
        TextSize   = 13,
        Size       = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 202,
        Parent     = toast,
    })
    make("TextLabel", {
        BackgroundTransparency = 1,
        Text       = cfg2.Content or "",
        TextColor3 = C.TextSub,
        Font       = F.UI,
        TextSize   = 12,
        Size       = UDim2.new(1, 0, 0, 16),
        Position   = UDim2.new(0, 0, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 202,
        Parent     = toast,
    })

    -- Animate in
    tween(toast, TI.Cubic, { Size = UDim2.new(0, 280, 0, 64) })

    -- Auto dismiss
    local dur = cfg2.Duration or 3.5
    task.delay(dur, function()
        if toast and toast.Parent then
            tween(toast, TI.Med, { Size = UDim2.new(0, 280, 0, 0) })
            task.delay(0.25, function()
                if toast and toast.Parent then toast:Destroy() end
                notifyOffset = math.max(0, notifyOffset - 1)
            end)
        end
    end)
end

function WindowMeta:_saveConfig(name)
    name = name or "default"
    local ok, err = self._config:save(name)
    self:Notify({
        Title   = ok and "Config Saved" or "Save Failed",
        Content = ok and ("→ " .. name) or tostring(err),
        Color   = ok and C.Green or C.Red,
    })
end

function WindowMeta:_loadConfig(name)
    name = name or "default"
    local ok = self._config:load(name)
    self:Notify({
        Title   = ok and "Config Loaded" or "Load Failed",
        Content = ok and ("← " .. name) or "File not found",
        Color   = ok and C.Green or C.Red,
    })
end

function WindowMeta:_resetConfig()
    self._config.flags = {}
    self:Notify({ Title="Config Reset", Content="All flags cleared", Color=C.Yellow })
end

function WindowMeta:GetFlag(f) return self._config:get(f) end
function WindowMeta:SetFlag(f, v) self._config:set(f, v) end

function WindowMeta:SetToggleKey(key)
    -- disconnect old, set new
    for i, conn in ipairs(self._connections) do
        conn:Disconnect()
        self._connections[i] = nil
    end
    local conn = UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == key then
            self._open = not self._open
            self._win.Visible = self._open
        end
    end)
    table.insert(self._connections, conn)
end

function WindowMeta:Destroy()
    for _, c in ipairs(self._connections) do c:Disconnect() end
    if self._gui then self._gui:Destroy() end
end

-- ═══════════════════════════════════════════════════════
--  RETURN
-- ═══════════════════════════════════════════════════════
return NeverLua
