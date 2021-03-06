if not getgenv().theme then
    getgenv().theme = {
        main = Color3.fromRGB(37, 37, 37),
        secondary = Color3.fromRGB(40, 40, 40),
        accent = Color3.fromRGB(255, 255, 255),
        accent2 = Color3.fromRGB(161, 161, 161),
        off = Color3.fromRGB(255, 45, 45),
        on = Color3.fromRGB(0, 255, 102)
    }
end

local utils = {}
local library = {}
library.flags = {}
library.destroyed = false
library.funcstorage = {}
library.objstorage = {}
library.binding = false
library.tabinfo = {button = nil, tab = nil}
library.binds = {}

local services =
    setmetatable(
    {},
    {
        __index = function(index, service)
            return game:GetService(service)
        end,
        __newindex = function(index, value)
            index[value] = nil
            return
        end
    }
)

local players = services.Players
local player = players.LocalPlayer
local mouse = player:GetMouse()

function utils:Tween(obj, tinf, data)
    local tweenInfo = TweenInfo.new(tinf[1], Enum.EasingStyle[tinf[2]], Enum.EasingDirection[tinf[3]])
    services.TweenService:Create(obj, tweenInfo, data):Play()
end

function utils:Ripple(obj)
    spawn(
        function()
            if obj.ClipsDescendants ~= true then
                obj.ClipsDescendants = true
            end
            local Ripple = Instance.new("ImageLabel")
            Ripple.Name = "Ripple"
            Ripple.Parent = obj
            Ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Ripple.BackgroundTransparency = 1.000
            Ripple.ZIndex = 8
            Ripple.Image = "rbxassetid://2708891598"
            Ripple.ImageTransparency = 0.800
            Ripple.ScaleType = Enum.ScaleType.Fit
            Ripple.ImageColor3 = getgenv().theme.accent
            Ripple.Position =
                UDim2.new(
                (mouse.X - Ripple.AbsolutePosition.X) / obj.AbsoluteSize.X,
                0,
                (mouse.Y - Ripple.AbsolutePosition.Y) / obj.AbsoluteSize.Y,
                0
            )
            self:Tween(
                Ripple,
                {1, "Linear", "InOut"},
                {Position = UDim2.new(-5.5, 0, -5.5, 0), Size = UDim2.new(12, 0, 12, 0)}
            )
            wait(0.5)
            self:Tween(Ripple, {.5, "Linear", "InOut"}, {ImageTransparency = 1})
            wait(.5)
            Ripple:Destroy()
        end
    )
end

function utils:Drag(frame, hold)
    if not hold then
        hold = frame
    end
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position =
            UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    hold.InputBegan:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position

                input.Changed:Connect(
                    function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end
                )
            end
        end
    )

    frame.InputChanged:Connect(
        function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end
    )

    services.UserInputService.InputChanged:Connect(
        function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end
    )
end

function library:UpdateToggle(flag, state)
    if library.flags[flag] == nil then
        return
    end
    local obj = library.objstorage[flag]
    local curFlag = library.flags[flag]
    state = state or not curFlag
    local func = library.funcstorage[flag]
    if curFlag == state then
        return
    end
    library.flags[flag] = state
    utils:Tween(
        obj.ToggleDisplay,
        {.15, "Linear", "InOut"},
        {
            BackgroundColor3 = (state and getgenv().theme.on) or getgenv().theme.off
        }
    )
    func(state)
end

function library:UpdateSlider(flag, value, min, max)
    local slider = self.objstorage[flag]
    local bar = slider.SliderBar
    local box = slider.SliderText.SliderValHolder.SliderVal

    local percent = (mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X

    if value then
        percent = (value - min) / (max - min)
    end

    percent = math.clamp(percent, 0, 1)
    value = value or math.floor(min + (max - min) * percent)

    library.flags[flag] = value

    box.Text = tostring(value)

    utils:Tween(bar.SliderFill, {0.05, "Linear", "InOut"}, {Size = UDim2.new(percent, 0, 1, 0)})

    self.funcstorage[flag](tonumber(value))
    return tonumber(value)
end

local changingTab = false
function utils:ChangeTab(newData)
    if changingTab then
        return
    end
    local btn, tab = newData[1], newData[2]
    if not btn or not tab then
        return
    end
    if library.tabinfo.button == btn then
        return
    end
    changingTab = true
    local oldbtn, oldtab = library.tabinfo.button, library.tabinfo.tab
    library.tabinfo = {button = btn, tab = tab}
    local container = tab.Parent
    if container.ClipsDescendants == false then
        container.ClipsDescendants = true
    end
    local beforeSize = container.Size

    utils:Tween(container, {0.3, "Sine", "InOut"}, {Size = UDim2.new(beforeSize.X.Scale, beforeSize.X.Offset, 0, 0)})
    utils:Tween(oldbtn, {0.3, "Sine", "InOut"}, {TextColor3 = getgenv().theme.accent2})
    wait(0.3)
    oldtab.Visible = false
    tab.Visible = true
    utils:Tween(container, {0.3, "Sine", "InOut"}, {Size = beforeSize})
    utils:Tween(btn, {0.3, "Sine", "InOut"}, {TextColor3 = getgenv().theme.accent})
    wait(0.3)
    changingTab = false
end

local function bindPressed(bind, inp)
    local key = bind
    if typeof(key) == "Instance" then
        if key.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key.KeyCode then
            return true
        elseif tostring(key.UserInputType):find("MouseButton") and inp.UserInputType == key.UserInputType then
            return true
        end
    end
    if tostring(key):find "MouseButton1" then
        return key == inp.UserInputType
    else
        return key == inp.KeyCode
    end
end

services.UserInputService.InputBegan:Connect(
    function(input, gpe)
        if (not library.binding) and (not library.destroyed) and (not gpe) then
            for idx, binds in next, library.binds do
                local bind = binds.location[idx]
                if bind and bindPressed(bind, input) then
                    binds.callback()
                end
            end
        end
    end
)

function library:Init(title)
    title = title or "Library"
    local Vertex = Instance.new("ScreenGui")
    local Main = Instance.new("Frame")
    local MainC = Instance.new("UICorner")
    local Top = Instance.new("Frame")
    local TopC = Instance.new("UICorner")
    local TopL = Instance.new("UIListLayout")
    local Title = Instance.new("TextLabel")
    local TopP = Instance.new("UIPadding")
    local Side = Instance.new("Frame")
    local SideC = Instance.new("UICorner")
    local SideBtns = Instance.new("ScrollingFrame")
    local SideBtnsL = Instance.new("UIListLayout")
    local SideBtnsP = Instance.new("UIPadding")
    local TabHolder = Instance.new("Frame")
    local TabHolderC = Instance.new("UICorner")

    if syn and syn.protect_gui then
        syn.protect_gui(Vertex)
    end

    Vertex.Name = "Vertex"
    Vertex.Parent = (function()
        if gethui then
            return gethui()
        end
        if get_hidden_gui then
            return get_hidden_gui()
        end
        if services.RunService:IsStudio() then
            return services.Players.LocalPlayer:WaitForChild("PlayerGui")
        end
        return services.CoreGui
    end)()

    function library:DestroyUI()
        library.destroyed = true
        Vertex:Destroy()
    end

    local open = true
    local toggling = false

    Main.Name = services.HttpService:GenerateGUID(true)
    Main.Parent = Vertex
    Main.BackgroundColor3 = getgenv().theme.secondary
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 658, 0, 434)
    Main.ClipsDescendants = true
    Main.AnchorPoint = Vector2.new(0.5, 0.5)

    local before = nil

    function library:ToggleUI()
        if toggling then
            return
        end
        open = not open
        toggling = true
        if open then
            utils:Tween(
                Main,
                {0.5, "Sine", "InOut"},
                {
                    Position = before
                }
            )
            wait(0.5)
            toggling = false
        else
            before = Main.Position
            utils:Tween(
                Main,
                {0.5, "Sine", "InOut"},
                {
                    Position = UDim2.new(1.3, 0, before.Y.Scale, before.Y.Offset)
                }
            )
            wait(0.5)
            toggling = false
        end
    end

    MainC.CornerRadius = UDim.new(0, 4)
    MainC.Name = "MainC"
    MainC.Parent = Main

    Top.Name = "Top"
    Top.Parent = Main
    Top.BackgroundColor3 = getgenv().theme.main
    Top.BorderSizePixel = 0
    Top.Position = UDim2.new(0, 6, 0, 6)
    Top.Size = UDim2.new(0, 646, 0, 36)

    utils:Drag(Main, Top)

    TopC.CornerRadius = UDim.new(0, 4)
    TopC.Name = "TopC"
    TopC.Parent = Top

    TopL.Name = "TopL"
    TopL.Parent = Top
    TopL.FillDirection = Enum.FillDirection.Horizontal
    TopL.SortOrder = Enum.SortOrder.LayoutOrder
    TopL.VerticalAlignment = Enum.VerticalAlignment.Center

    Title.Name = "Title"
    Title.Parent = Top
    Title.BackgroundColor3 = getgenv().theme.accent
    Title.BackgroundTransparency = 1.000
    Title.Position = UDim2.new(0.0185758509, 0, 0.111111112, 0)
    Title.Size = UDim2.new(0, 49, 0, 28)
    Title.Font = Enum.Font.GothamBold
    Title.Text = title
    Title.TextColor3 = getgenv().theme.accent
    Title.TextSize = 16.000
    Title.TextXAlignment = Enum.TextXAlignment.Left

    TopP.Name = "TopP"
    TopP.Parent = Top
    TopP.PaddingLeft = UDim.new(0, 12)

    Side.Name = "Side"
    Side.Parent = Main
    Side.BackgroundColor3 = getgenv().theme.main
    Side.BorderSizePixel = 0
    Side.Position = UDim2.new(0, 6, 0, 48)
    Side.Size = UDim2.new(0, 190, 0, 380)

    SideC.CornerRadius = UDim.new(0, 4)
    SideC.Name = "SideC"
    SideC.Parent = Side

    SideBtns.Name = "SideBtns"
    SideBtns.Parent = Side
    SideBtns.Active = true
    SideBtns.BackgroundColor3 = getgenv().theme.accent
    SideBtns.BackgroundTransparency = 1.000
    SideBtns.BorderSizePixel = 0
    SideBtns.Size = UDim2.new(0, 190, 0, 380)
    SideBtns.ScrollBarThickness = 0

    SideBtnsL.Name = "SideBtnsL"
    SideBtnsL.Parent = SideBtns
    SideBtnsL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SideBtnsL.SortOrder = Enum.SortOrder.LayoutOrder
    SideBtnsL.Padding = UDim.new(0, 5)

    SideBtnsP.Name = "SideBtnsP"
    SideBtnsP.Parent = SideBtns
    SideBtnsP.PaddingTop = UDim.new(0, 7)

    TabHolder.Name = "TabHolder"
    TabHolder.Parent = Main
    TabHolder.BackgroundColor3 = getgenv().theme.main
    TabHolder.BorderSizePixel = 0
    TabHolder.Position = UDim2.new(0, 202, 0, 48)
    TabHolder.Size = UDim2.new(0, 450, 0, 380)

    TabHolderC.CornerRadius = UDim.new(0, 4)
    TabHolderC.Name = "TabHolderC"
    TabHolderC.Parent = TabHolder

    SideBtnsL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
        function()
            SideBtns.CanvasSize = UDim2.new(0, 0, 0, SideBtnsL.AbsoluteContentSize.Y + 9)
        end
    )

    local tabs = {}

    function tabs:Tab(title)
        title = title or "Tab"
        local TabBtn = Instance.new("TextButton")
        local TabBtnC = Instance.new("UICorner")
        local Tab = Instance.new("ScrollingFrame")
        local TabL = Instance.new("UIListLayout")
        local TabP = Instance.new("UIPadding")

        TabBtn.Name = "TabBtn"
        TabBtn.Parent = SideBtns
        TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        TabBtn.BackgroundTransparency = 1.000
        TabBtn.BorderColor3 = Color3.fromRGB(27, 42, 53)
        TabBtn.BorderSizePixel = 0
        TabBtn.Position = UDim2.new(0.0315789469, 0, 0.0236842111, 0)
        TabBtn.Size = UDim2.new(0, 178, 0, 29)
        TabBtn.AutoButtonColor = false
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.Text = title
        TabBtn.TextColor3 = (library.tabinfo.button == nil and getgenv().theme.accent) or getgenv().theme.accent2
        TabBtn.TextSize = 14.000

        TabBtnC.CornerRadius = UDim.new(0, 4)
        TabBtnC.Name = "TabBtnC"
        TabBtnC.Parent = TabBtn

        Tab.Name = "Tab"
        Tab.Parent = TabHolder
        Tab.Active = true
        Tab.BackgroundColor3 = getgenv().theme.accent
        Tab.BackgroundTransparency = 1.000
        Tab.BorderSizePixel = 0
        Tab.Size = UDim2.new(0, 450, 0, 380)
        Tab.ScrollBarThickness = 0
        Tab.Visible = (library.tabinfo.tab == nil)

        TabL.Name = "TabL"
        TabL.Parent = Tab
        TabL.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabL.SortOrder = Enum.SortOrder.LayoutOrder
        TabL.Padding = UDim.new(0, 5)

        TabP.Name = "TabP"
        TabP.Parent = Tab
        TabP.PaddingTop = UDim.new(0, 7)

        TabBtn.MouseButton1Click:Connect(
            function()
                utils:Ripple(TabBtn)
                utils:ChangeTab({TabBtn, Tab})
            end
        )

        TabL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
            function()
                Tab.CanvasSize = UDim2.new(0, 0, 0, TabL.AbsoluteContentSize.Y + 12)
            end
        )

        if library.tabinfo.button == nil then
            library.tabinfo.button = TabBtn
        end

        if library.tabinfo.tab == nil then
            library.tabinfo.tab = Tab
        end

        local objects = {}

        function objects:Button(text, callback)
            text = text or "Button"
            callback = callback or function()
                end
            local Btn = Instance.new("TextButton")
            local BtnC = Instance.new("UICorner")

            Btn.Name = "Btn"
            Btn.Parent = Tab
            Btn.BackgroundColor3 = getgenv().theme.secondary
            Btn.BorderColor3 = Color3.fromRGB(27, 42, 53)
            Btn.BorderSizePixel = 0
            Btn.Position = UDim2.new(0, 0, 0.0249999985, 0)
            Btn.Size = UDim2.new(0, 440, 0, 34)
            Btn.AutoButtonColor = false
            Btn.Font = Enum.Font.GothamSemibold
            Btn.Text = "   " .. text
            Btn.TextColor3 = getgenv().theme.accent
            Btn.TextSize = 14.000
            Btn.TextXAlignment = Enum.TextXAlignment.Left

            BtnC.CornerRadius = UDim.new(0, 4)
            BtnC.Name = "BtnC"
            BtnC.Parent = Btn

            Btn.MouseButton1Click:Connect(
                function()
                    utils:Ripple(Btn)
                    callback()
                end
            )
        end

        function objects:Toggle(text, flag, enabled, callback)
            text = text or "Toggle"
            assert(flag, "flag is a required argument")
            enabled = enabled or false
            callback = callback or function()
                end

            local Toggle = Instance.new("TextButton")
            local ToggleC = Instance.new("UICorner")
            local ToggleDisplay = Instance.new("Frame")
            local ToggleDisplayC = Instance.new("UICorner")

            library.objstorage[flag] = Toggle
            library.funcstorage[flag] = callback
            library.flags[flag] = false

            Toggle.Name = "Toggle"
            Toggle.Parent = Tab
            Toggle.BackgroundColor3 = getgenv().theme.secondary
            Toggle.BorderColor3 = Color3.fromRGB(27, 42, 53)
            Toggle.BorderSizePixel = 0
            Toggle.Position = UDim2.new(0, 0, 0.0249999985, 0)
            Toggle.Size = UDim2.new(0, 440, 0, 34)
            Toggle.AutoButtonColor = false
            Toggle.Font = Enum.Font.GothamSemibold
            Toggle.Text = "   " .. text
            Toggle.TextColor3 = getgenv().theme.accent
            Toggle.TextSize = 14.000
            Toggle.TextXAlignment = Enum.TextXAlignment.Left

            ToggleC.CornerRadius = UDim.new(0, 4)
            ToggleC.Name = "ToggleC"
            ToggleC.Parent = Toggle

            ToggleDisplay.Name = "ToggleDisplay"
            ToggleDisplay.Parent = Toggle
            ToggleDisplay.BackgroundColor3 = Color3.fromRGB(255, 44, 44)
            ToggleDisplay.BorderSizePixel = 0
            ToggleDisplay.Position = UDim2.new(0.918181837, 0, 0.117647059, 0)
            ToggleDisplay.Size = UDim2.new(0, 26, 0, 26)

            ToggleDisplayC.CornerRadius = UDim.new(0, 4)
            ToggleDisplayC.Name = "ToggleDisplayC"
            ToggleDisplayC.Parent = ToggleDisplay

            if enabled then
                library:UpdateToggle(flag, enabled)
            end

            ToggleDisplay.InputBegan:Connect(
                function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        utils:Ripple(ToggleDisplay)
                        library:UpdateToggle(flag)
                    end
                end
            )
        end

        function objects:Box(text, flag, default, callback)
            text = text or "Textbox"
            assert(flag, "flag is a required argument")
            assert(default, "default is a required argument")
            callback = callback or function()
                end

            library.flags[flag] = default

            local Textbox = Instance.new("TextButton")
            local TextboxC = Instance.new("UICorner")
            local TextboxHolder = Instance.new("Frame")
            local TextboxHolderL = Instance.new("UIListLayout")
            local TextInp = Instance.new("TextBox")
            local TextInpC = Instance.new("UICorner")

            TextInp:GetPropertyChangedSignal("TextBounds"):Connect(
                function()
                    TextInp.Size = UDim2.new(0, TextInp.TextBounds.X + 18, 0, 26)
                end
            )

            Textbox.Name = "Textbox"
            Textbox.Parent = Tab
            Textbox.BackgroundColor3 = getgenv().theme.secondary
            Textbox.BorderColor3 = Color3.fromRGB(27, 42, 53)
            Textbox.BorderSizePixel = 0
            Textbox.Position = UDim2.new(-0.0377777778, 0, 0.0184210502, 0)
            Textbox.Size = UDim2.new(0, 440, 0, 34)
            Textbox.AutoButtonColor = false
            Textbox.Font = Enum.Font.GothamSemibold
            Textbox.Text = "   " .. text
            Textbox.TextColor3 = getgenv().theme.accent
            Textbox.TextSize = 14.000
            Textbox.TextXAlignment = Enum.TextXAlignment.Left

            TextboxC.CornerRadius = UDim.new(0, 4)
            TextboxC.Name = "TextboxC"
            TextboxC.Parent = Textbox

            TextboxHolder.Name = "TextboxHolder"
            TextboxHolder.Parent = Textbox
            TextboxHolder.BackgroundColor3 = getgenv().theme.accent
            TextboxHolder.BackgroundTransparency = 1.000
            TextboxHolder.BorderSizePixel = 0
            TextboxHolder.Position = UDim2.new(0.752252221, 0, 0, 0)
            TextboxHolder.Size = UDim2.new(0, 103, 0, 34)

            TextboxHolderL.Name = "TextboxHolderL"
            TextboxHolderL.Parent = TextboxHolder
            TextboxHolderL.FillDirection = Enum.FillDirection.Horizontal
            TextboxHolderL.HorizontalAlignment = Enum.HorizontalAlignment.Right
            TextboxHolderL.SortOrder = Enum.SortOrder.LayoutOrder
            TextboxHolderL.VerticalAlignment = Enum.VerticalAlignment.Center

            TextInp.Name = "TextInp"
            TextInp.Parent = TextboxHolder
            TextInp.BackgroundColor3 = getgenv().theme.main
            TextInp.BorderSizePixel = 0
            TextInp.Position = UDim2.new(-0.0199999996, 0, 0.117647059, 0)
            TextInp.Size = UDim2.new(0, 102, 0, 26)
            TextInp.Font = Enum.Font.Gotham
            TextInp.Text = default
            TextInp.TextColor3 = getgenv().theme.accent
            TextInp.TextSize = 14.000

            TextInpC.CornerRadius = UDim.new(0, 4)
            TextInpC.Name = "TextInpC"
            TextInpC.Parent = TextInp

            TextInp.FocusLost:Connect(
                function()
                    if TextInp.Text == "" then
                        TextInp.Text = library.flags[flag]
                    end
                    library.flags[flag] = TextInp.Text
                    callback(TextInp.Text)
                end
            )
        end

        function objects:Label(text)
            text = text or "Label"

            local Label = Instance.new("TextButton")
            local LabelC = Instance.new("UICorner")

            Label.Name = "Label"
            Label.Parent = Tab
            Label.BackgroundColor3 = getgenv().theme.secondary
            Label.BorderColor3 = Color3.fromRGB(27, 42, 53)
            Label.BorderSizePixel = 0
            Label.Position = UDim2.new(0, 0, 0.0249999985, 0)
            Label.Size = UDim2.new(0, 440, 0, 34)
            Label.AutoButtonColor = false
            Label.Font = Enum.Font.GothamSemibold
            Label.Text = "   " .. text
            Label.TextColor3 = getgenv().theme.accent
            Label.TextSize = 14.000
            Label.TextXAlignment = Enum.TextXAlignment.Left

            LabelC.CornerRadius = UDim.new(0, 4)
            LabelC.Name = "LabelC"
            LabelC.Parent = Label

            return Label
        end

        function objects:Slider(text, flag, default, min, max, callback)
            assert(flag, "flag is a required argument")
            assert(default, "default is a required argument")
            assert(min, "min is a required argument")
            assert(max, "max is a required argument")
            callback = callback or function()
                end
            text = text or "Slider"
            local value = default or min

            local Slider = Instance.new("TextButton")
            local SliderC = Instance.new("UICorner")
            local SliderText = Instance.new("TextButton")
            local SliderValHolder = Instance.new("Frame")
            local SliderValHolderL = Instance.new("UIListLayout")
            local SliderVal = Instance.new("TextBox")
            local SliderValC = Instance.new("UICorner")
            local SliderBar = Instance.new("Frame")
            local SliderBarC = Instance.new("UICorner")
            local SliderFill = Instance.new("Frame")
            local SliderFillC = Instance.new("UICorner")

            library.objstorage[flag] = Slider
            library.funcstorage[flag] = callback
            library.flags[flag] = value

            Slider.Name = "Slider"
            Slider.Parent = Tab
            Slider.BackgroundColor3 = getgenv().theme.secondary
            Slider.BorderColor3 = Color3.fromRGB(27, 42, 53)
            Slider.BorderSizePixel = 0
            Slider.Position = UDim2.new(0.0111111114, 0, 0.428947359, 0)
            Slider.Size = UDim2.new(0, 440, 0, 51)
            Slider.AutoButtonColor = false
            Slider.Font = Enum.Font.GothamSemibold
            Slider.Text = ""
            Slider.TextColor3 = getgenv().theme.accent
            Slider.TextSize = 14.000

            SliderC.CornerRadius = UDim.new(0, 4)
            SliderC.Name = "SliderC"
            SliderC.Parent = Slider

            SliderText.Name = "SliderText"
            SliderText.Parent = Slider
            SliderText.BackgroundColor3 = getgenv().theme.secondary
            SliderText.BackgroundTransparency = 1.000
            SliderText.BorderColor3 = Color3.fromRGB(27, 42, 53)
            SliderText.BorderSizePixel = 0
            SliderText.Size = UDim2.new(0, 444, 0, 34)
            SliderText.AutoButtonColor = false
            SliderText.Font = Enum.Font.GothamSemibold
            SliderText.Text = "   " .. text
            SliderText.TextColor3 = getgenv().theme.accent
            SliderText.TextSize = 14.000
            SliderText.TextXAlignment = Enum.TextXAlignment.Left

            SliderValHolder.Name = "SliderValHolder"
            SliderValHolder.Parent = SliderText
            SliderValHolder.BackgroundColor3 = getgenv().theme.accent
            SliderValHolder.BackgroundTransparency = 1.000
            SliderValHolder.BorderSizePixel = 0
            SliderValHolder.Position = UDim2.new(0.752252281, 0, 0, 0)
            SliderValHolder.Size = UDim2.new(0, 100, 0, 34)

            SliderValHolderL.Name = "SliderValHolderL"
            SliderValHolderL.Parent = SliderValHolder
            SliderValHolderL.FillDirection = Enum.FillDirection.Horizontal
            SliderValHolderL.HorizontalAlignment = Enum.HorizontalAlignment.Right
            SliderValHolderL.SortOrder = Enum.SortOrder.LayoutOrder
            SliderValHolderL.VerticalAlignment = Enum.VerticalAlignment.Center

            SliderVal.Name = "SliderVal"
            SliderVal.Parent = SliderValHolder
            SliderVal.BackgroundColor3 = getgenv().theme.main
            SliderVal.BorderSizePixel = 0
            SliderVal.Position = UDim2.new(0.449999988, 0, 0.117647059, 0)
            SliderVal.Size = UDim2.new(0, 55, 0, 26)
            SliderVal.Font = Enum.Font.Gotham
            SliderVal.Text = value
            SliderVal.TextColor3 = getgenv().theme.accent
            SliderVal.TextSize = 14.000

            SliderValC.CornerRadius = UDim.new(0, 4)
            SliderValC.Name = "SliderValC"
            SliderValC.Parent = SliderVal

            SliderBar.Name = "SliderBar"
            SliderBar.Parent = Slider
            SliderBar.BackgroundColor3 = getgenv().theme.main
            SliderBar.BorderSizePixel = 0
            SliderBar.Position = UDim2.new(0, 6, 0, 34)
            SliderBar.Size = UDim2.new(0, 428, 0, 10)

            SliderBarC.CornerRadius = UDim.new(0, 4)
            SliderBarC.Name = "SliderBarC"
            SliderBarC.Parent = SliderBar

            SliderFill.Name = "SliderFill"
            SliderFill.Parent = SliderBar
            SliderFill.BackgroundColor3 = getgenv().theme.accent
            SliderFill.BorderSizePixel = 0
            SliderFill.Size = UDim2.new(0, 66, 0, 10)

            SliderFillC.CornerRadius = UDim.new(0, 4)
            SliderFillC.Name = "SliderFillC"
            SliderFillC.Parent = SliderFill

            SliderVal.Size = UDim2.new(0, SliderVal.TextBounds.X + 18, 0, 26)

            SliderVal:GetPropertyChangedSignal("TextBounds"):Connect(
                function()
                    utils:Tween(
                        SliderVal,
                        {0.05, "Linear", "InOut"},
                        {
                            Size = UDim2.new(0, SliderVal.TextBounds.X + 18, 0, 26)
                        }
                    )
                end
            )

            library:UpdateSlider(flag, value, min, max)
            local dragging = false

            SliderBar.InputBegan:Connect(
                function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        library:UpdateSlider(flag, nil, min, max)
                        dragging = true
                    end
                end
            )

            SliderBar.InputEnded:Connect(
                function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end
            )

            services.UserInputService.InputChanged:Connect(
                function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        library:UpdateSlider(flag, nil, min, max)
                    end
                end
            )

            local boxFocused = false
            local allowed = {
                [""] = true,
                ["-"] = true
            }

            SliderVal.Focused:Connect(
                function()
                    boxFocused = true
                end
            )

            SliderVal.FocusLost:Connect(
                function()
                    boxFocused = false
                    if not tonumber(SliderVal.Text) then
                        library:UpdateSlider(flag, default or min, min, max)
                    end
                end
            )

            SliderVal:GetPropertyChangedSignal("Text"):Connect(
                function()
                    if not boxFocused then
                        return
                    end
                    SliderVal.Text = SliderVal.Text:gsub("%D+", "")
                    local text = SliderVal.Text

                    if not tonumber(text) then
                        SliderVal.Text = SliderVal.Text:gsub("%D+", "")
                    elseif not allowed[text] then
                        if tonumber(text) > max then
                            text = max
                            SliderVal.Text = tostring(max)
                        end
                        library:UpdateSlider(flag, tonumber(text) or value, min, max)
                    end
                end
            )
        end

        function objects:Keybind(text, flag, default, kbOnly, callback)
            assert(text, "text is a required arg")
            assert(flag, "flag is a required arg")
            assert(default, "default is a required arg")
            kbOnly = kbOnly or false
            callback = callback or function()
                end

            library.flags[flag] = default

            local banned = {
                Return = true,
                Space = true,
                Tab = true,
                Unknown = true
            }

            local shortNames = {
                RightControl = "RightCtrl",
                LeftControl = "LeftCtrl",
                LeftShift = "LShift",
                RightShift = "RShift",
                MouseButton1 = "Mouse1",
                MouseButton2 = "Mouse2"
            }

            local allowed = {
                MouseButton1 = true,
                MouseButton2 = true
            }

            local nm = (default and (shortNames[default.Name] or default.Name) or "None")

            local Keybind = Instance.new("TextButton")
            local KeybindC = Instance.new("UICorner")
            local KeybindHolder = Instance.new("Frame")
            local KeybindHolderL = Instance.new("UIListLayout")
            local KeybindVal = Instance.new("TextButton")
            local KeybindValC = Instance.new("UICorner")

            Keybind.Name = "Keybind"
            Keybind.Parent = Tab
            Keybind.BackgroundColor3 = getgenv().theme.secondary
            Keybind.BorderColor3 = Color3.fromRGB(27, 42, 53)
            Keybind.BorderSizePixel = 0
            Keybind.Position = UDim2.new(0, 0, 0.0249999985, 0)
            Keybind.Size = UDim2.new(0, 440, 0, 34)
            Keybind.AutoButtonColor = false
            Keybind.Font = Enum.Font.GothamSemibold
            Keybind.Text = "   " .. text
            Keybind.TextColor3 = getgenv().theme.accent
            Keybind.TextSize = 14.000
            Keybind.TextXAlignment = Enum.TextXAlignment.Left

            KeybindC.CornerRadius = UDim.new(0, 4)
            KeybindC.Name = "KeybindC"
            KeybindC.Parent = Keybind

            KeybindHolder.Name = "KeybindHolder"
            KeybindHolder.Parent = Keybind
            KeybindHolder.BackgroundColor3 = getgenv().theme.accent
            KeybindHolder.BackgroundTransparency = 1.000
            KeybindHolder.BorderSizePixel = 0
            KeybindHolder.Position = UDim2.new(0.752252221, 0, 0, 0)
            KeybindHolder.Size = UDim2.new(0, 103, 0, 34)

            KeybindHolderL.Name = "KeybindHolderL"
            KeybindHolderL.Parent = KeybindHolder
            KeybindHolderL.FillDirection = Enum.FillDirection.Horizontal
            KeybindHolderL.HorizontalAlignment = Enum.HorizontalAlignment.Right
            KeybindHolderL.SortOrder = Enum.SortOrder.LayoutOrder
            KeybindHolderL.VerticalAlignment = Enum.VerticalAlignment.Center

            KeybindVal.Name = "KeybindVal"
            KeybindVal.Parent = KeybindHolder
            KeybindVal.BackgroundColor3 = getgenv().theme.main
            KeybindVal.BorderSizePixel = 0
            KeybindVal.Position = UDim2.new(0.339805812, 0, 0.117647059, 0)
            KeybindVal.Size = UDim2.new(0, 68, 0, 26)
            KeybindVal.AutoButtonColor = false
            KeybindVal.Font = Enum.Font.Gotham
            KeybindVal.Text = nm
            KeybindVal.TextColor3 = getgenv().theme.accent
            KeybindVal.TextSize = 14.000

            KeybindVal.Size = UDim2.new(0, KeybindVal.TextBounds.X + 18, 0, 26)

            KeybindVal:GetPropertyChangedSignal("TextBounds"):Connect(
                function()
                    utils:Tween(
                        KeybindVal,
                        {0.05, "Linear", "InOut"},
                        {
                            Size = UDim2.new(0, KeybindVal.TextBounds.X + 18, 0, 26)
                        }
                    )
                end
            )

            KeybindValC.CornerRadius = UDim.new(0, 4)
            KeybindValC.Name = "KeybindValC"
            KeybindValC.Parent = KeybindVal

            KeybindVal.MouseButton1Click:Connect(
                function()
                    library.binding = true

                    KeybindVal.Text = "..."
                    local a, b = services.UserInputService.InputBegan:wait()
                    local name = tostring(a.KeyCode.Name)
                    local typeName = tostring(a.UserInputType.Name)

                    if
                        (a.UserInputType ~= Enum.UserInputType.Keyboard and (allowed[a.UserInputType.Name]) and
                            (not kbOnly)) or
                            (a.KeyCode and (not banned[a.KeyCode.Name]))
                     then
                        local name =
                            (a.UserInputType ~= Enum.UserInputType.Keyboard and a.UserInputType.Name or a.KeyCode.Name)
                        library.flags[flag] = (a)
                        KeybindVal.Text = shortNames[name] or name
                    else
                        if (library.flags[flag]) then
                            if
                                (not pcall(
                                    function()
                                        return library.flags[flag].UserInputType
                                    end
                                ))
                             then
                                local name = tostring(library.flags[flag])
                                KeybindValText = shortNames[name] or name
                            else
                                local name =
                                    (library.flags[flag].UserInputType ~= Enum.UserInputType.Keyboard and
                                    library.flags[flag].UserInputType.Name or
                                    library.flags[flag].KeyCode.Name)
                                KeybindValText = shortNames[name] or name
                            end
                        end
                    end

                    wait(0.1)
                    library.binding = false
                end
            )

            if library.flags[flag] then
                KeybindValText = shortNames[tostring(library.flags[flag].Name)] or tostring(library.flags[flag].Name)
            end

            library.binds[flag] = {
                location = library.flags,
                callback = callback
            }
        end

        function objects:Dropdown(text, flag, options, callback)
            assert(flag, "flag is a required argument")
            assert(options, "options is a required argument")
            callback = callback or function()
                end
            text = text or "Dropdown"
            local selectedOption = nil
            local optionsStorage = {}

            if type(options) ~= "table" or not options[1] then
                options = {"No options provided"}
            end

            library.flags[flag] = options[1]

            local DropdownTop = Instance.new("TextButton")
            local DropdownTopC = Instance.new("UICorner")
            local Back = Instance.new("ImageButton")
            local DropdownBottom = Instance.new("TextButton")
            local DropdownBottomC = Instance.new("UICorner")
            local DropdownObjects = Instance.new("ScrollingFrame")
            local DropdownObjectsList = Instance.new("UIListLayout")
            local DropdownObjectsPadding = Instance.new("UIPadding")

            DropdownTop.Name = "DropdownTop"
            DropdownTop.Parent = Tab
            DropdownTop.BackgroundColor3 = getgenv().theme.secondary
            DropdownTop.BorderColor3 = Color3.fromRGB(27, 42, 53)
            DropdownTop.BorderSizePixel = 0
            DropdownTop.Position = UDim2.new(0, 0, 0.0249999985, 0)
            DropdownTop.Size = UDim2.new(0, 440, 0, 34)
            DropdownTop.AutoButtonColor = false
            DropdownTop.Font = Enum.Font.GothamSemibold
            DropdownTop.Text = "   " .. text .. " (" .. options[1] .. ")"
            DropdownTop.TextColor3 = getgenv().theme.accent
            DropdownTop.TextSize = 14.000
            DropdownTop.TextXAlignment = Enum.TextXAlignment.Left

            DropdownTopC.CornerRadius = UDim.new(0, 4)
            DropdownTopC.Name = "DropdownTopC"
            DropdownTopC.Parent = DropdownTop

            Back.Name = "Back"
            Back.Parent = DropdownTop
            Back.BackgroundColor3 = getgenv().theme.accent
            Back.BackgroundTransparency = 1.000
            Back.BorderSizePixel = 0
            Back.Position = UDim2.new(0.913636327, 0, 0.0882352963, 0)
            Back.Rotation = -90.000
            Back.Size = UDim2.new(0, 28, 0, 28)
            Back.Image = "rbxassetid://4370337241"
            Back.ScaleType = Enum.ScaleType.Fit

            DropdownBottom.Name = "DropdownBottom"
            DropdownBottom.Parent = Tab
            DropdownBottom.BackgroundColor3 = getgenv().theme.secondary
            DropdownBottom.BorderColor3 = Color3.fromRGB(27, 42, 53)
            DropdownBottom.BorderSizePixel = 0
            DropdownBottom.ClipsDescendants = true
            DropdownBottom.Position = UDim2.new(0.0111111114, 0, 0.176315784, 0)
            DropdownBottom.Size = UDim2.new(0, 440, 0, 0)
            DropdownBottom.Visible = false
            DropdownBottom.AutoButtonColor = false
            DropdownBottom.Font = Enum.Font.GothamSemibold
            DropdownBottom.Text = ""
            DropdownBottom.TextColor3 = getgenv().theme.accent
            DropdownBottom.TextSize = 14.000
            DropdownBottom.TextXAlignment = Enum.TextXAlignment.Left

            DropdownBottomC.CornerRadius = UDim.new(0, 4)
            DropdownBottomC.Name = "DropdownBottomC"
            DropdownBottomC.Parent = DropdownBottom

            DropdownObjects.Name = "DropdownObjects"
            DropdownObjects.Parent = DropdownBottom
            DropdownObjects.Active = true
            DropdownObjects.BackgroundColor3 = getgenv().theme.accent
            DropdownObjects.BackgroundTransparency = 1.000
            DropdownObjects.Size = UDim2.new(1, 0, 1, 0)
            DropdownObjects.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropdownObjects.ScrollBarThickness = 0

            DropdownObjectsList.Name = "DropdownObjectsList"
            DropdownObjectsList.Parent = DropdownObjects
            DropdownObjectsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            DropdownObjectsList.SortOrder = Enum.SortOrder.LayoutOrder
            DropdownObjectsList.Padding = UDim.new(0, 4)

            DropdownObjectsPadding.Name = "DropdownObjectsPadding"
            DropdownObjectsPadding.Parent = DropdownObjects
            DropdownObjectsPadding.PaddingTop = UDim.new(0, 3)

            DropdownObjectsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
                function()
                    DropdownObjects.CanvasSize = UDim2.new(0, 0, 0, DropdownObjectsList.AbsoluteContentSize.Y + 8)
                end
            )

            local isOpen = false
            local function toggleDropdown()
                isOpen = not isOpen
                if not isOpen then
                    spawn(
                        function()
                            wait(.3)
                            DropdownBottom.Visible = false
                        end
                    )
                else
                    DropdownBottom.Visible = true
                end
                local openTo = 172
                if DropdownObjectsList.AbsoluteContentSize.Y + 8 < openTo then
                    openTo = DropdownObjectsList.AbsoluteContentSize.Y + 8
                end
                DropdownTop.Text = ("   %s (%s)"):format(text, isOpen and "..." or library.flags[flag])
                utils:Tween(
                    Back,
                    {0.3, "Sine", "InOut"},
                    {
                        Rotation = (isOpen and 90) or -90
                    }
                )
                utils:Tween(
                    DropdownBottom,
                    {0.3, "Sine", "InOut"},
                    {
                        Size = UDim2.new(0, 447, 0, isOpen and openTo or 0)
                    }
                )
            end

            DropdownObjectsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
                function()
                    if not isOpen then
                        return
                    end
                    local openTo = 172
                    if DropdownObjectsList.AbsoluteContentSize.X + 8 < openTo then
                        openTo = DropdownObjectsList.AbsoluteContentSize.Y + 8
                    end
                    utils:Tween(
                        DropdownBottom,
                        {0.3, "Sine", "InOut"},
                        {
                            Size = UDim2.new(0, 447, 0, isOpen and openTo or 0)
                        }
                    )
                end
            )

            Back.MouseButton1Click:Connect(
                function()
                    toggleDropdown()
                end
            )
            for _, v in pairs(options) do
                local Option = Instance.new("TextButton")
                local OptionC = Instance.new("UICorner")

                Option.Name = "Option"
                Option.Parent = DropdownObjects
                Option.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                Option.BackgroundTransparency = 1.000
                Option.BorderColor3 = Color3.fromRGB(27, 42, 53)
                Option.BorderSizePixel = 0
                Option.Position = UDim2.new(0.0136363637, 0, 0.0176470596, 0)
                Option.Size = UDim2.new(0, 428, 0, 24)
                Option.AutoButtonColor = false
                Option.Font = Enum.Font.GothamSemibold
                Option.Text = v
                Option.TextColor3 = (selectedOption == nil and getgenv().theme.accent) or getgenv().theme.accent2
                Option.TextSize = 14.000

                OptionC.CornerRadius = UDim.new(0, 4)
                OptionC.Name = "OptionC"
                OptionC.Parent = Option

                selectedOption = Option
                table.insert(optionsStorage, Option)

                Option.MouseButton1Click:Connect(
                    function()
                        if Option ~= selectedOption then
                            selectedOption.TextColor3 = getgenv().theme.accent2
                            Option.TextColor3 = getgenv().theme.accent
                            selectedOption = Option
                        end
                        library.flags[flag] = v
                        spawn(toggleDropdown)
                        spawn(
                            function()
                                callback(Option.Text)
                            end
                        )
                    end
                )
            end
            local eee = {}
            function eee:refresh(new)
                for _, v in pairs(optionsStorage) do
                    v:Destroy()
                end
                optionsStorage = {}
                selectedOption = nil
                if type(new) ~= "table" or not new[1] then
                    new = {"No options provided"}
                end
                for _, v in pairs(new) do
                    local Option = Instance.new("TextButton")
                    local OptionC = Instance.new("UICorner")

                    Option.Name = "Option"
                    Option.Parent = DropdownObjects
                    Option.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    Option.BackgroundTransparency = 1.000
                    Option.BorderColor3 = Color3.fromRGB(27, 42, 53)
                    Option.BorderSizePixel = 0
                    Option.Position = UDim2.new(0.0136363637, 0, 0.0176470596, 0)
                    Option.Size = UDim2.new(0, 428, 0, 24)
                    Option.AutoButtonColor = false
                    Option.Font = Enum.Font.GothamSemibold
                    Option.Text = v
                    Option.TextColor3 = (selectedOption == nil and getgenv().theme.accent) or getgenv().theme.accent2
                    Option.TextSize = 14.000

                    OptionC.CornerRadius = UDim.new(0, 4)
                    OptionC.Name = "OptionC"
                    OptionC.Parent = Option

                    selectedOption = Option
                    table.insert(optionsStorage, Option)

                    Option.MouseButton1Click:Connect(
                        function()
                            if Option ~= selectedOption then
                                selectedOption.TextColor3 = getgenv().theme.accent2
                                Option.TextColor3 = getgenv().theme.accent
                                selectedOption = Option
                            end
                            library.flags[flag] = v
                            spawn(toggleDropdown)
                            spawn(
                                function()
                                    callback(Option.Text)
                                end
                            )
                        end
                    )
                end
            end
            return eee
        end

        return objects
    end

    return tabs
end

return library
