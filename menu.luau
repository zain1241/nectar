--!nonstrict
local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data, farming, convert
if loaded and loaded.data and loaded.farming and loaded.convert then
	data, farming, convert = loaded.data, loaded.farming, loaded.convert
else
	data = require(script.Parent:WaitForChild("data"))
	farming = require(script.Parent:WaitForChild("farming"))
	convert = require(script.Parent:WaitForChild("convert"))
end

local mod = { data = data, farming = farming }
local actives = data.actives

local menu = {}

local Instance_new = Instance.new
local UDim_new = UDim.new
local UDim2_new = UDim2.new
local UDim2_fromScale = UDim2.fromScale
local UDim2_fromOffset = UDim2.fromOffset
local Vector2_new = Vector2.new
local Color3_fromRGB = Color3.fromRGB
local ColorSequence_new = ColorSequence.new
local TweenInfo_new = TweenInfo.new
local t_insert = table.insert
local t_sort = table.sort
local t_concat = table.concat
local s_lower = string.lower
local s_find = string.find
local s_gsub = string.gsub
local m_clamp = math.clamp
local m_round = math.round
local m_floor = math.floor
local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local pairs = pairs
local type = type
local pcall = pcall
local task_spawn = task.spawn
local task_wait = task.wait
local task_delay = task.delay

local FillDir_H = Enum.FillDirection.Horizontal
local FillDir_V = Enum.FillDirection.Vertical
local Sort_Layout = Enum.SortOrder.LayoutOrder
local HAlign_Left = Enum.HorizontalAlignment.Left
local HAlign_Center = Enum.HorizontalAlignment.Center
local HAlign_Right = Enum.HorizontalAlignment.Right
local VAlign_Top = Enum.VerticalAlignment.Top
local VAlign_Center = Enum.VerticalAlignment.Center
local VAlign_Bottom = Enum.VerticalAlignment.Bottom
local TextX_Left = Enum.TextXAlignment.Left
local TextX_Center = Enum.TextXAlignment.Center
local TextX_Right = Enum.TextXAlignment.Right
local Trunc_End = Enum.TextTruncate.AtEnd
local Scale_Fit = Enum.ScaleType.Fit
local Auto_Y = Enum.AutomaticSize.Y
local Auto_X = Enum.AutomaticSize.X
local ZIndex_Sibling = Enum.ZIndexBehavior.Sibling
local UIS_Mouse1 = Enum.UserInputType.MouseButton1
local UIS_Touch = Enum.UserInputType.Touch
local UIS_MouseMove = Enum.UserInputType.MouseMovement
local UIS_End = Enum.UserInputState.End
local Font_Medium = Enum.Font.BuilderSansMedium
local Font_Bold = Enum.Font.BuilderSansBold
local Font_ExtraBold = Enum.Font.BuilderSansExtraBold
local Easing_Quart = Enum.EasingStyle.Quart
local Easing_Sine = Enum.EasingStyle.Sine
local EasingDir_Out = Enum.EasingDirection.Out
local EasingDir_InOut = Enum.EasingDirection.InOut

local WHITE = Color3_fromRGB(255, 255, 255)
local DIM = Color3_fromRGB(120, 120, 125)
local MUTED = Color3_fromRGB(160, 160, 165)
local NAV_OFF = Color3_fromRGB(80, 76, 83)
local ROW_BG = Color3_fromRGB(26, 24, 29)
local ARROW_BG = Color3_fromRGB(24, 23, 25)
local BTN_OFF = Color3_fromRGB(42, 40, 45)
local BTN_ACTIVE = Color3_fromRGB(68, 63, 75)
local ROW_SELECTED = Color3_fromRGB(37, 35, 39)
local PREVIEW_BG = Color3_fromRGB(28, 26, 31)
local BG_DARK = Color3_fromRGB(10, 9, 11)
local SCROLLBAR = Color3_fromRGB(30, 30, 33)
local CHECK_ICON = "rbxassetid://3642321726"
local DEFAULT_ICON = "rbxassetid://1554410815"
local PINK_SEQ = ColorSequence_new(Color3_fromRGB(194, 49, 142), Color3_fromRGB(242, 96, 190))

local tweenservice = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sections = {}
local navigationButtons = {}
local activeSection = "Home"

menu.colors = {
	main = BG_DARK,
	active_button = Color3_fromRGB(28, 26, 31),
	card = Color3_fromRGB(16, 15, 18),
	preview = PREVIEW_BG,
	button_off = BTN_OFF,
	button_on = Color3_fromRGB(255, 198, 74),
}

local function makeCorner(parent, r, bl, br, tl, tr)
	if not parent then return end
	r = r or UDim_new(0.08, 0)
	local c = Instance_new("UICorner")
	c.BottomLeftRadius = bl or r
	c.BottomRightRadius = br or r
	c.TopLeftRadius = tl or r
	c.TopRightRadius = tr or r
	c.Parent = parent
	return c
end

local function makeList(parent, padding, fill, halign, valign)
	local l = Instance_new("UIListLayout")
	l.SortOrder = Sort_Layout
	l.Padding = padding or UDim_new(0, 0)
	l.FillDirection = fill or FillDir_V
	l.HorizontalAlignment = halign or HAlign_Left
	l.VerticalAlignment = valign or VAlign_Top
	l.Parent = parent
	return l
end

local function makeShadow(parent)
	local s = Instance_new("UIShadow")
	s.BlurRadius = UDim_new(0.1, 0)
	s.Color = Color3_fromRGB(0, 0, 0)
	s.Transparency = 0.8
	s.Parent = parent
	return s
end

local function makeGradientShimmer(parent)
	local g = Instance_new("UIGradient")
	g.Color = PINK_SEQ
	g.Rotation = 0
	g.Offset = Vector2_new(-1, 0)
	g.Parent = parent
	tweenservice:Create(g, TweenInfo_new(1.8, Easing_Sine, EasingDir_InOut, -1, true), {
		Offset = Vector2_new(1, 0),
	}):Play()
	return g
end

function menu.main_create()
	local s = playerGui:FindFirstChild("ScreenGui")
	if not s then
		s = Instance_new("ScreenGui")
		s.Name = "ScreenGui"
		s.ResetOnSpawn = false
		s.IgnoreGuiInset = false
		s.ZIndexBehavior = ZIndex_Sibling
		s.Parent = playerGui
	end

	local old = s:FindFirstChild("EggHuntLayerVisualOnly")
	if old then old:Destroy() end

	local f = Instance_new("Frame")
	f.Name = "EggHuntLayerVisualOnly"
	f.AnchorPoint = Vector2_new(0.5, 0.5)
	f.BackgroundTransparency = 1
	f.Position = actives["position_script"] or UDim2_new(0.22, 0, 0.5, 0)
	f.Size = UDim2_new(0.351, 0, 0.435, 0)
	f.ZIndex = 1000
	f.Parent = s
	makeList(f, UDim_new(0, 0), FillDir_H, HAlign_Left, VAlign_Top)

	local m = Instance_new("Frame")
	m.Name = "Main"
	m.AnchorPoint = Vector2_new(0.5, 0.5)
	m.BackgroundColor3 = BG_DARK
	m.BorderSizePixel = 0
	m.BackgroundTransparency = 0.04
	m.Size = UDim2_new(0.773, 0, 1, 0)
	m.LayoutOrder = 1
	m.ZIndex = 1001
	m.Parent = f
	makeShadow(m)
	makeCorner(m, UDim_new(0, 0), UDim_new(0, 0), UDim_new(0.03, 0), UDim_new(0, 0), UDim_new(0.03, 0))

	local c = Instance_new("Frame")
	c.Name = "Content"
	c.AnchorPoint = Vector2_new(0.5, 0.5)
	c.BackgroundTransparency = 1
	c.Position = UDim2_new(0.5, 0, 0.5, 0)
	c.Size = UDim2_new(1, 0, 1, 0)
	c.ZIndex = 1001
	c.Parent = m
	makeCorner(c, UDim_new(0, 0), UDim_new(0, 0), UDim_new(0.03, 0), UDim_new(0, 0), UDim_new(0.03, 0))

	local t = Instance_new("Frame")
	t.Name = "Tab"
	t.AnchorPoint = Vector2_new(0.5, 0.5)
	t.BackgroundColor3 = BG_DARK
	t.BorderSizePixel = 0
	t.BackgroundTransparency = 0.04
	t.Size = UDim2_new(0.227, 0, 1, 0)
	t.LayoutOrder = 0
	t.ZIndex = 1001
	t.Parent = f
	makeList(t, UDim_new(0, 0), FillDir_V, HAlign_Right, VAlign_Top)
	makeShadow(t)
	makeCorner(t, UDim_new(0.08, 0), UDim_new(0.08, 0), UDim_new(0, 0), UDim_new(0.08, 0), UDim_new(0, 0))
end

function menu.main_nav()
	local frame = playerGui:FindFirstChild("ScreenGui"):FindFirstChild("EggHuntLayerVisualOnly")
	local s = frame:FindFirstChild("Tab")

	local b1 = Instance_new("Frame")
	b1.Name = "Back"
	b1.BackgroundTransparency = 1
	b1.Size = UDim2_new(1, 0, 0.106, 0)
	b1.ZIndex = 1002
	b1.Parent = s

	local n = Instance_new("Frame")
	n.Name = "Nav"
	n.BackgroundTransparency = 1
	n.Size = UDim2_new(0.961, 0, 0.716, 0)
	n.ZIndex = 1002
	n.Parent = s

	local t = Instance_new("Frame")
	t.Name = "Stats"
	t.BackgroundTransparency = 1
	t.Size = UDim2_new(1, 0, 0.16, 0)
	t.ZIndex = 1002
	t.Parent = s
	makeList(t, UDim_new(0, 0), FillDir_H, HAlign_Center, VAlign_Bottom)

	local b = Instance_new("TextButton")
	b.AnchorPoint = Vector2_new(0.5, 0.5)
	b.BackgroundColor3 = Color3_fromRGB(16, 16, 17)
	b.BackgroundTransparency = 0
	b.Text = ""
	b.Size = UDim2_new(0.912, 0, 0.664, 0)
	b.ZIndex = 1003
	b.Parent = t
	makeList(b, UDim_new(0, 0), FillDir_H, HAlign_Left, VAlign_Center)
	makeCorner(b, UDim_new(0.3, 0))

	local f1 = Instance_new("Frame")
	f1.Name = "f1"
	f1.BackgroundTransparency = 1
	f1.Size = UDim2_new(0.5, 0, 1, 0)
	f1.LayoutOrder = 0
	f1.ZIndex = 1004
	f1.Parent = b
	makeList(f1, UDim_new(0, 0), FillDir_H, HAlign_Center, VAlign_Center)

	local f1i = Instance_new("ImageLabel")
	f1i.BackgroundColor3 = Color3_fromRGB(12, 12, 13)
	f1i.BackgroundTransparency = 0
	f1i.BorderSizePixel = 0
	f1i.Size = UDim2_new(0.489, 0, 0.791, 0)
	f1i.ScaleType = Scale_Fit
	f1i.ZIndex = 1005
	f1i.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=100&h=100"
	f1i.Parent = f1
	makeCorner(f1i, UDim_new(1, 0))

	local f2 = Instance_new("Frame")
	f2.Name = "f2"
	f2.BackgroundTransparency = 1
	f2.Size = UDim2_new(0.5, 0, 1, 0)
	f2.LayoutOrder = 1
	f2.ZIndex = 1004
	f2.Parent = b
	makeList(f2, UDim_new(0, 0), FillDir_V, HAlign_Left, VAlign_Center)

	local tp = Instance_new("TextLabel")
	tp.Name = "tp"
	tp.AutomaticSize = Auto_X
	tp.BackgroundTransparency = 1
	tp.BorderSizePixel = 0
	tp.Size = UDim2_new(0.773, 0, 0.323, 0)
	tp.ZIndex = 1005
	tp.Font = Font_Medium
	tp.Text = "#" .. player.Name
	tp.LayoutOrder = 1
	tp.TextColor3 = Color3_fromRGB(69, 66, 72)
	tp.TextScaled = true
	tp.TextXAlignment = TextX_Left
	tp.Parent = f2

	local tt = Instance_new("TextLabel")
	tt.Name = "tt"
	tt.AutomaticSize = Auto_X
	tt.BackgroundTransparency = 1
	tt.BorderSizePixel = 0
	tt.Size = UDim2_new(0.773, 0, 0.323, 0)
	tt.ZIndex = 1005
	tt.Font = Font_Bold
	tt.Text = ""
	tt.LayoutOrder = 0
	tt.TextColor3 = WHITE
	tt.TextScaled = true
	tt.TextXAlignment = TextX_Left
	tt.Parent = f2

	task_spawn(function()
		while tt.Parent do
			tt.Text = DateTime.now():FormatLocalTime("HH:mm", "ru-ru")
			task_wait(1)
		end
	end)

	makeList(b1, UDim_new(0.04, 0), FillDir_H, HAlign_Center, VAlign_Center)

	local b1t = Instance_new("TextLabel")
	b1t.Name = "b1t"
	b1t.BackgroundTransparency = 1
	b1t.BorderSizePixel = 0
	b1t.Size = UDim2_new(0.468, 0, 0.37, 0)
	b1t.ZIndex = 1004
	b1t.Font = Font_Bold
	b1t.Text = actives["script_name"]
	b1t.LayoutOrder = 0
	b1t.TextColor3 = WHITE
	b1t.TextScaled = true
	b1t.TextXAlignment = TextX_Right
	b1t.Parent = b1

	local f2i = Instance_new("ImageLabel")
	f2i.BackgroundTransparency = 1
	f2i.BorderSizePixel = 0
	f2i.Size = UDim2_new(0.177, 0, 0.659, 0)
	f2i.ScaleType = Scale_Fit
	f2i.LayoutOrder = -1
	f2i.ZIndex = 1004
	f2i.Image = "rbxassetid://15505167958"
	f2i.Parent = b1

	local b1b = Instance_new("TextButton")
	b1b.AnchorPoint = Vector2_new(0.5, 0.5)
	b1b.BackgroundColor3 = ARROW_BG
	b1b.BackgroundTransparency = 0
	b1b.LayoutOrder = 1
	b1b.Font = Font_ExtraBold
	b1b.TextScaled = true
	b1b.TextXAlignment = TextX_Center
	b1b.Text = "<"
	b1b.TextColor3 = WHITE
	b1b.Size = UDim2_new(0.153, 0, 0.542, 0)
	b1b.ZIndex = 1004
	b1b.Parent = b1
	makeCorner(b1b, UDim_new(0.4, 0))

	local main = frame.Main
	local mainSize = main.Size
	local clicked = false
	main.ClipsDescendants = true

	local tweenQOut = TweenInfo_new(0.2, Easing_Quart, EasingDir_Out)

	b1b.MouseButton1Click:Connect(function()
		if clicked then return end
		clicked = true

		if main.Visible then
			local af = n:FindFirstChild("NavAutoFarm")
			if af then af.Visible = true end

			tweenservice:Create(main, tweenQOut, {
				Size = UDim2_new(0, 0, mainSize.Y.Scale, mainSize.Y.Offset),
			}):Play()

			tweenservice:Create(main.UICorner, tweenQOut, {
				BottomLeftRadius = UDim_new(0.03, 0),
				BottomRightRadius = UDim_new(0.03, 0),
				TopLeftRadius = UDim_new(0.03, 0),
				TopRightRadius = UDim_new(0.03, 0),
			}):Play()

			s.Back.TextButton.Text = ">"

			task_delay(0.3, function()
				main.Visible = false
				tweenservice:Create(s.UICorner, tweenQOut, {
					BottomLeftRadius = UDim_new(0.08, 0),
					BottomRightRadius = UDim_new(0.08, 0),
					TopLeftRadius = UDim_new(0.08, 0),
					TopRightRadius = UDim_new(0.08, 0),
				}):Play()
				clicked = false
			end)
		else
			local af = n:FindFirstChild("NavAutoFarm")
			if af then af.Visible = false end

			main.Visible = true
			main.Size = UDim2_new(0, 0, mainSize.Y.Scale, mainSize.Y.Offset)

			tweenservice:Create(s.UICorner, tweenQOut, {
				BottomLeftRadius = UDim_new(0.08, 0),
				BottomRightRadius = UDim_new(0, 0),
				TopLeftRadius = UDim_new(0.08, 0),
				TopRightRadius = UDim_new(0, 0),
			}):Play()

			tweenservice:Create(main.UICorner, tweenQOut, {
				BottomLeftRadius = UDim_new(0, 0),
				BottomRightRadius = UDim_new(0.03, 0),
				TopLeftRadius = UDim_new(0, 0),
				TopRightRadius = UDim_new(0.03, 0),
			}):Play()

			s.Back.TextButton.Text = "<"

			tweenservice:Create(main, tweenQOut, { Size = mainSize }):Play()

			task_delay(0.3, function()
				clicked = false
			end)
		end
	end)

	makeList(n, UDim_new(0.02, 0), FillDir_V, HAlign_Left, VAlign_Top)

	local afButton = Instance_new("TextButton")
	afButton.Name = "NavAutoFarm"
	afButton.BackgroundColor3 = WHITE
	afButton.BackgroundTransparency = 0.85
	afButton.BorderSizePixel = 0
	afButton.Text = ""
	afButton.Size = UDim2_new(0.954, 0, 0.087, 0)
	afButton.LayoutOrder = 100
	afButton.ZIndex = 1004
	afButton.Visible = false
	afButton.Parent = n
	makeGradientShimmer(afButton)
	makeCorner(afButton, UDim_new(0, 7))

	local afText = Instance_new("TextLabel")
	afText.Name = "TextLabel"
	afText.BackgroundTransparency = 1
	afText.BorderSizePixel = 0
	afText.Position = UDim2_new(0, 10, 0, 0)
	afText.Size = UDim2_new(0.62, -10, 1, 0)
	afText.ZIndex = 1005
	afText.Font = Font_Bold
	afText.Text = "Auto Farm"
	afText.TextColor3 = WHITE
	afText.TextScaled = false
	afText.TextSize = 15
	afText.TextXAlignment = TextX_Left
	afText.Parent = afButton

	local afToggle = Instance_new("TextButton")
	afToggle.Name = "TextButton"
	afToggle.AnchorPoint = Vector2_new(1, 0.5)
	afToggle.BackgroundColor3 = Color3_fromRGB(30, 12, 26)
	afToggle.Interactable = false
	afToggle.BackgroundTransparency = 0
	afToggle.AutoButtonColor = false
	afToggle.BorderSizePixel = 0
	afToggle.Position = UDim2_new(1, -7, 0.5, 0)
	afToggle.Size = UDim2_new(0, 18, 0, 18)
	afToggle.ZIndex = 1005
	afToggle.Text = ""
	afToggle.Parent = afButton
	makeCorner(afToggle, UDim_new(0.3, 0))

	local afCheck = Instance_new("ImageLabel")
	afCheck.Name = "ImageLabel"
	afCheck.AnchorPoint = Vector2_new(0.5, 0.5)
	afCheck.BackgroundTransparency = 1
	afCheck.BorderSizePixel = 0
	afCheck.Position = UDim2_new(0.5, 0, 0.5, 0)
	afCheck.Size = UDim2_new(0.721, 0, 0.721, 0)
	afCheck.ZIndex = 1006
	afCheck.Image = CHECK_ICON
	afCheck.ScaleType = Scale_Fit
	afCheck.Visible = false
	afCheck.Parent = afToggle

	local function afUpdate()
		afCheck.Visible = actives["auto_farm"] == true
	end
	afUpdate()

	afButton.MouseButton1Click:Connect(function()
		actives["auto_farm"] = not (actives["auto_farm"] == true)
		afUpdate()
		if farming.farm then farming.farm() end
		if farming.startPlanterLoop then
			if actives["auto_farm"] == true and actives["planter_auto"] == true then
				farming.startPlanterLoop()
			else
				farming.stopPlanterLoop()
			end
		end
	end)

	task_spawn(function()
		while afButton.Parent do
			afUpdate()
			task_wait(0.15)
		end
	end)

	afButton.Visible = not main.Visible
	main:GetPropertyChangedSignal("Visible"):Connect(function()
		afButton.Visible = not main.Visible
	end)

	local function showsel(name)
		activeSection = name
		for sectionName, page in pairs(sections) do
			page.Visible = sectionName == name
		end
		for sectionName, button in pairs(navigationButtons) do
			local on = sectionName == name
			button.BackgroundTransparency = on and 0 or 1
			button.textname.TextColor3 = on and WHITE or NAV_OFF
			button.icon.ImageColor3 = on and WHITE or NAV_OFF
		end
	end

	local function addNavigation(name, icon, order)
		local b = Instance_new("TextButton")
		b.Name = "Button-" .. name
		b.BackgroundColor3 = Color3_fromRGB(28, 26, 31)
		b.BackgroundTransparency = 1
		b.BorderSizePixel = 0
		b.Size = UDim2_new(0.855, 0, 0.087, 0)
		b.LayoutOrder = order
		b.ZIndex = 1004
		b.Parent = n
		b.Text = ""
		b.TextXAlignment = TextX_Left
		makeList(b, UDim_new(0.06, 0), FillDir_H, HAlign_Left, VAlign_Center)
		makeCorner(b, UDim_new(0.3, 0))

		local p = Instance_new("UIPadding")
		p.PaddingLeft = UDim_new(0.04, 0)
		p.PaddingRight = UDim_new(0, 0)
		p.PaddingTop = UDim_new(0, 0)
		p.PaddingBottom = UDim_new(0, 0)
		p.Parent = b

		local i = Instance_new("ImageLabel")
		i.Name = "icon"
		i.AnchorPoint = Vector2_new(0.5, 0.5)
		i.BackgroundTransparency = 1
		i.LayoutOrder = 0
		i.Size = UDim2_new(0.114, 0, 0.489, 0)
		i.Image = icon
		i.ImageColor3 = WHITE
		i.ScaleType = Scale_Fit
		i.ZIndex = 1004
		i.Parent = b

		local t = Instance_new("TextLabel")
		t.Name = "textname"
		t.AutomaticSize = Auto_X
		t.BackgroundTransparency = 1
		t.BorderSizePixel = 0
		t.LayoutOrder = 1
		t.Size = UDim2_new(0.319, 0, 0.61, 0)
		t.ZIndex = 1004
		t.Font = Font_Medium
		t.Text = name
		t.TextColor3 = WHITE
		t.TextScaled = true
		t.TextXAlignment = TextX_Left
		t.Parent = b

		b.MouseButton1Click:Connect(function()
			showsel(name)
		end)

		navigationButtons[name] = b
	end

	addNavigation("Farming", "rbxassetid://15332137726", 1)
	--addNavigation("Planters", "rbxassetid://13060262529", 2)
	--addNavigation("Toys", "rbxassetid://102597526078163", 3)
	addNavigation("Config", "rbxassetid://4857706689", 4)

	showsel("Farming")
end

function menu.dop_create()
	local sg = playerGui:FindFirstChild("ScreenGui")
	if not sg then return end
	local f = sg:FindFirstChild("EggHuntLayerVisualOnly")
	if not f then return end
	local m = f:FindFirstChild("Main")
	if not m then return end

	sections = {}
	menu.dop_objects = {}
	if not actives then
		actives = {}
		data.actives = actives
	end

	local active_slider

	local function corner(parent, r, bl, br, tl, tr)
		if not parent then return end
		r = r or UDim_new(0.08, 0)
		local c = Instance_new("UICorner")
		c.BottomLeftRadius = bl or r
		c.BottomRightRadius = br or r
		c.TopLeftRadius = tl or r
		c.TopRightRadius = tr or r
		c.Parent = parent
		return c
	end

	local function save(d, v1, v2, v3)
		if not d then return end
		if d.key ~= nil then
			actives[d.key] = v1
		end
		local cb = d.callback
		if cb ~= nil then
			task_spawn(cb, v1, v2, v3)
		end
	end

	local function addtext(parent, d, order)
		if not parent or not d then return end

		local t = Instance_new("TextLabel")
		t.Name = d.name or "Text"
		t.BackgroundColor3 = PREVIEW_BG
		t.BackgroundTransparency = d.background_transparency or 0
		t.BorderSizePixel = 0
		t.Size = d.size or UDim2_new(1, 0, 0, 30)
		t.LayoutOrder = order or 0
		t.ZIndex = 1004
		t.Font = d.font or Font_Medium
		t.Text = tostring(d.text or "Text")
		t.TextColor3 = d.text_color or WHITE
		t.TextScaled = d.text_scaled ~= false
		t.TextWrapped = true
		t.TextXAlignment = d.text_x_alignment or TextX_Left
		t.Parent = parent
		t:SetAttribute("search_text", s_lower(tostring(d.text or "")))

		corner(t, d.corner)

		local p = Instance_new("UIPadding")
		p.PaddingLeft = UDim_new(0.03, 0)
		p.PaddingRight = UDim_new(0.03, 0)
		p.Parent = t

		local o = { frame = t, text = t }
		function o.set(v)
			t.Text = tostring(v or "")
		end

		if d.id ~= nil then
			menu.dop_objects[d.id] = o
		end
		return o
	end

	local function addbutton(parent, d, order)
		if not parent or not d then return end

		local toggle = d.toggle ~= false
		local value = d.value

		if d.key ~= nil and actives[d.key] ~= nil then
			value = actives[d.key]
		end

		if toggle then
			value = value == true
			if d.key ~= nil and actives[d.key] == nil then
				actives[d.key] = value
			end
		end

		local r = Instance_new("TextButton")
		r.Name = d.name or "Preview"
		r.BackgroundColor3 = ROW_BG
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.Text = ""
		r.Size = UDim2_new(0.351, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent
		r:SetAttribute("search_text", s_lower(tostring(d.text or "")))
		corner(r, UDim_new(0, 7))

		local t = Instance_new("TextLabel")
		t.Name = "TextLabel"
		t.BackgroundTransparency = 1
		t.BorderSizePixel = 0
		t.Position = UDim2_new(0, 10, 0, 0)
		t.Size = UDim2_new(0.62, -10, 1, 0)
		t.ZIndex = 1005
		t.Font = Font_Bold
		t.Text = tostring(d.text or "er")
		t.TextColor3 = WHITE
		t.TextScaled = false
		t.TextSize = 15
		t.TextXAlignment = TextX_Left
		t.Parent = r

		local b = Instance_new("TextButton")
		b.Name = "TextButton"
		b.AnchorPoint = Vector2_new(1, 0.5)
		b.BackgroundColor3 = BTN_OFF
		b.Interactable = false
		b.BackgroundTransparency = 0
		b.AutoButtonColor = false
		b.BorderSizePixel = 0
		b.Position = UDim2_new(1, -7, 0.5, 0)
		b.Size = UDim2_new(0, 23, 0, 23)
		b.ZIndex = 1005
		b.Font = Font_Bold
		b.TextColor3 = Color3_fromRGB(92, 92, 98)
		b.TextScaled = true
		b.Text = ""
		b.Parent = r
		corner(b, UDim_new(0.3, 0))

		local c = Instance_new("ImageLabel")
		c.Name = "ImageLabel"
		c.AnchorPoint = Vector2_new(0.5, 0.5)
		c.BackgroundTransparency = 1
		c.BorderSizePixel = 0
		c.Position = UDim2_new(0.5, 0, 0.5, 0)
		c.Size = UDim2_new(0.721, 0, 0.721, 0)
		c.ZIndex = 1006
		c.Image = CHECK_ICON
		c.ScaleType = Scale_Fit
		c.Visible = false
		c.Parent = b

		local function update()
			if not toggle then return end
			if d.key ~= nil then
				value = actives[d.key] == true
			end
			c.Visible = value == true
		end

		local o = { frame = r, text = t, button = b }

		function o.set(v)
			if toggle then
				value = v == true
				save(d, value, b, r)
				update()
			else
				b.Text = tostring(v or "")
			end
		end

		function o.get()
			return value
		end

		r.MouseButton1Click:Connect(function()
			if toggle then
				value = not value
				save(d, value, b, r)
				update()
			else
				if d.key ~= nil and d.value ~= nil then
					actives[d.key] = d.value
				end
				local cb = d.callback
				if cb ~= nil then
					cb(d.value, b, r)
				end
			end
		end)

		update()

		if toggle and d.key ~= nil then
			task_spawn(function()
				while r.Parent do
					update()
					task_wait(0.15)
				end
			end)
		end

		if d.id ~= nil then
			menu.dop_objects[d.id] = o
		end
		return o
	end

	local function addinput(parent, d, order)
		if not parent or type(d) ~= "table" then return end

		local key = d.key or "input"
		local value = actives[key]
		if value == nil then
			value = d.value or ""
			actives[key] = value
		end

		local r = Instance_new("Frame")
		r.Name = d.name or "Input"
		r.BackgroundColor3 = ROW_BG
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.Size = UDim2_new(1.025, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent
		r:SetAttribute("search_text", s_lower(tostring(d.text or "")))
		corner(r, UDim_new(0, 7))

		local t = Instance_new("TextLabel")
		t.Name = "Label"
		t.BackgroundTransparency = 1
		t.Position = UDim2_new(0.02, 0, 0, 0)
		t.Size = UDim2_new(0.4, 0, 1, 0)
		t.ZIndex = 1005
		t.Font = Font_Bold
		t.Text = tostring(d.text or "Input")
		t.TextColor3 = WHITE
		t.TextSize = 14
		t.TextXAlignment = TextX_Left
		t.Parent = r

		local box = Instance_new("TextBox")
		box.Name = "TextBox"
		box.AnchorPoint = Vector2_new(1, 0.5)
		box.BackgroundColor3 = BTN_OFF
		box.BorderSizePixel = 0
		box.Position = UDim2_new(1, -8, 0.5, 0)
		box.Size = UDim2_new(0.55, 0, 0.7, 0)
		box.ZIndex = 1005
		box.ClipsDescendants = true
		box.Font = Font_Medium
		box.Text = tostring(value)
		box.PlaceholderText = tostring(d.placeholder or "")
		box.PlaceholderColor3 = DIM
		box.TextColor3 = WHITE
		box.TextSize = 13
		box.TextXAlignment = TextX_Center
		box.ClearTextOnFocus = false
		box.Parent = r
		corner(box, UDim_new(0, 6))

		local o = { frame = r, text = t, box = box }
		function o.set(v)
			box.Text = tostring(v or "")
			actives[key] = box.Text
		end
		function o.get()
			return box.Text
		end

		box:GetPropertyChangedSignal("Text"):Connect(function()
			actives[key] = box.Text
		end)

		if d.id ~= nil then
			menu.dop_objects[d.id] = o
		end
		return o
	end

	local function addslider(parent, d, order)
		if not parent or not d then return end

		local min = tonumber(d.min) or 0
		local max = tonumber(d.max) or 100
		local step = tonumber(d.step) or 1
		local value = tonumber(d.value) or min

		if max <= min then
			max = min + 1
		end

		if d.key ~= nil and tonumber(actives[d.key]) ~= nil then
			value = tonumber(actives[d.key])
		end

		local r = Instance_new("Frame")
		r.Name = d.name or "Slider"
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.BackgroundColor3 = ROW_BG
		r.Size = UDim2_new(1.025, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent
		r:SetAttribute("search_text", s_lower(tostring(d.text or "")))
		corner(r, UDim_new(0, 7))

		local t = Instance_new("TextLabel")
		t.Name = "Text"
		t.BackgroundTransparency = 1
		t.BorderSizePixel = 0
		t.Position = UDim2_new(0.02, 0, 0.26, 0)
		t.Size = UDim2_new(0.24, 0, 0.5, 0)
		t.ZIndex = 1005
		t.Font = d.font or Font_Bold
		t.Text = tostring(d.text or "Slider")
		t.TextColor3 = d.text_color or WHITE
		t.TextScaled = d.text_scaled ~= false
		t.TextXAlignment = TextX_Left
		t.Parent = r

		local v = Instance_new("TextLabel")
		v.Name = "Value"
		v.AnchorPoint = Vector2_new(1, 0.5)
		v.BackgroundTransparency = 1
		v.BorderSizePixel = 0
		v.Position = UDim2_new(0.97, 0, 0.5, 0)
		v.Size = UDim2_new(0.12, 0, 0.6, 0)
		v.ZIndex = 1005
		v.Font = d.value_font or Font_Bold
		v.TextColor3 = d.value_color or WHITE
		v.TextScaled = true
		v.TextXAlignment = TextX_Right
		v.Parent = r

		local b = Instance_new("Frame")
		b.Name = "Back"
		b.AnchorPoint = Vector2_new(1, 0.5)
		b.BackgroundColor3 = d.back_color or BTN_OFF
		b.BorderSizePixel = 0
		b.Position = UDim2_new(0.87, 0, 0.52, 0)
		b.Size = d.slider_size or UDim2_new(0.6, 0, 0.24, 0)
		b.ZIndex = 1005
		b.Active = true
		b.Parent = r
		corner(b, UDim_new(1, 0))

		local fill = Instance_new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = WHITE
		fill.BorderSizePixel = 0
		fill.Size = UDim2_new(0, 0, 1, 0)
		fill.ZIndex = 1006
		fill.Parent = b
		makeGradientShimmer(fill)
		corner(fill, UDim_new(1, 0))

		local function setvalue(n, fire)
			n = m_clamp(tonumber(n) or min, min, max)
			if step > 0 then
				n = m_clamp(m_round(n / step) * step, min, max)
			end
			value = n
			local alpha = (value - min) / (max - min)
			fill.Size = UDim2_new(alpha, 0, 1, 0)
			v.Text = d.format and tostring(d.format(value)) or tostring(value)
			if d.key ~= nil then
				actives[d.key] = value
			end
			if fire == true and d.callback ~= nil then
				d.callback(value, b, r)
			end
		end

		local function move(x)
			if b.AbsoluteSize.X <= 0 then return end
			local alpha = m_clamp((x - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
			setvalue(min + ((max - min) * alpha), true)
		end

		local o = { frame = r, text = t, value = v, back = b, fill = fill }
		function o.set(n, fire)
			setvalue(n, fire ~= false)
		end
		function o.get()
			return value
		end

		b.InputBegan:Connect(function(input)
			local it = input.UserInputType
			if it ~= UIS_Mouse1 and it ~= UIS_Touch then return end
			active_slider = move
			move(input.Position.X)
		end)

		setvalue(value, false)

		if d.id ~= nil then
			menu.dop_objects[d.id] = o
		end
		return o
	end

	local function addlistChose(parent, d, order)
		local list = d.list or data.zones
		local key = d.key or "field"
		local opened = d.opened == true
		local multi = d.multi == true

		local fields = {}
		local cards = {}
		local valid = {}
		local search = { tostring(d.text or "Field") }

		for _, v in ipairs(list) do
			local name, image
			if type(v) == "table" then
				name = v.name
				image = v.image
			else
				name = v
				image = ""
			end
			if type(name) == "string" and name ~= "" and name ~= "Ant Field" then
				fields[#fields + 1] = { name = name, image = tostring(image or "") }
				valid[name] = true
				search[#search + 1] = name
			end
		end

		local selected
		local selectedSet

		if multi then
			if type(actives[key]) ~= "table" then
				actives[key] = {}
			end
			selectedSet = actives[key]
			if selectedSet.__init ~= true then
				for i = 1, #fields do
					selectedSet[fields[i].name] = true
				end
				selectedSet.__init = true
			end
		else
			selected = d.value
			if selected == nil then
				selected = actives[key]
			end
			if selected == false or selected == "" then
				selected = nil
			end
			if selected ~= nil and valid[selected] ~= true then
				selected = nil
			end
			actives[key] = selected or false
		end

		local r = Instance_new("Frame")
		r.Name = d.name or "Preview"
		r.BackgroundColor3 = ROW_BG
		r.AutomaticSize = Auto_Y
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.Size = UDim2_new(1.025, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent
		r:SetAttribute("search_text", s_lower(t_concat(search, " ")))
		corner(r, UDim_new(0, 7))
		makeList(r, UDim_new(0, 5), FillDir_V, HAlign_Center, VAlign_Top)
		makeShadow(r)

		local useHeaderIcon = d.header_icon == true
		local headerSize = d.header_size or UDim2_new(0.962, 0, 0, 32)

		local h = Instance_new("TextButton")
		h.Name = "Header"
		h.BackgroundTransparency = 1
		h.BorderSizePixel = 0
		h.AutoButtonColor = true
		h.Size = headerSize
		h.LayoutOrder = 0
		h.ZIndex = 1004
		h.Font = Font_Bold
		h.TextColor3 = WHITE
		h.TextSize = 15
		h.TextTruncate = Trunc_End
		h.TextXAlignment = TextX_Left
		h.Parent = r

		local headerIcon
		if useHeaderIcon then
			headerIcon = Instance_new("ImageLabel")
			headerIcon.Name = "HeaderIcon"
			headerIcon.AnchorPoint = Vector2_new(0, 0.5)
			headerIcon.BackgroundTransparency = 1
			headerIcon.BorderSizePixel = 0
			headerIcon.Position = UDim2_new(-0.012, 6, 0.5, 0)
			headerIcon.Size = UDim2_fromOffset(21, 21)
			headerIcon.Image = ""
			headerIcon.ImageColor3 = WHITE
			headerIcon.ScaleType = Scale_Fit
			headerIcon.Visible = false
			headerIcon.ZIndex = 1006
			headerIcon.Parent = h
		end

		local h2 = Instance_new("TextButton")
		h2.Name = "Arrow"
		h2.BackgroundColor3 = ARROW_BG
		h2.BackgroundTransparency = 0
		h2.AnchorPoint = Vector2_new(0, 0)
		h2.Interactable = false
		h2.BorderSizePixel = 0
		h2.Position = UDim2_new(0.967, 0, 0.138, 0)
		h2.Size = UDim2_new(0.05, 0, 0.723, 0)
		h2.ZIndex = 1005
		h2.Font = Font_ExtraBold
		h2.Text = "<"
		h2.TextColor3 = WHITE
		h2.TextScaled = true
		h2.Parent = h
		corner(h2, d.radius or UDim_new(0.4, 0))

		local r1 = Instance_new("Frame")
		r1.Name = "Rows"
		r1.AutomaticSize = Auto_Y
		r1.BackgroundTransparency = 1
		r1.Size = UDim2_new(1, 0, 0, 0)
		r1.LayoutOrder = 1
		r1.ZIndex = 1004
		r1.Visible = opened
		r1.Parent = r

		local rl = Instance_new("UIListLayout")
		rl.SortOrder = Sort_Layout
		rl.Padding = UDim_new(0, 5)
		rl.Wraps = true
		rl.FillDirection = FillDir_H
		rl.HorizontalAlignment = HAlign_Left
		rl.VerticalAlignment = VAlign_Top
		rl.Parent = r1

		local rp = Instance_new("UIPadding")
		rp.PaddingLeft = UDim_new(0, 6)
		rp.PaddingRight = UDim_new(0, 6)
		rp.PaddingBottom = UDim_new(0, 7)
		rp.Parent = r1

		local function updateHeader()
			local label
			if multi then
				local total = #fields
				local count = 0
				for i = 1, total do
					if selectedSet[fields[i].name] then count = count + 1 end
				end
				label = tostring(d.text or "Field") .. ": " .. count .. "/" .. total
			else
				label = tostring(d.text or "Field") .. ": " .. tostring(selected or "Not Selected")
			end

			if headerIcon then
				h.Text = "          " .. label
			else
				h.Text = label
			end

			if not useHeaderIcon or not headerIcon then return end

			local selectedImage = ""
			if selected ~= nil then
				for i = 1, #list do
					local v = list[i]
					local vname = type(v) == "table" and v.name or v
					if vname == selected then
						selectedImage = type(v) == "table" and tostring(v.image or "") or ""
						break
					end
				end
			end

			local hasRealImage = selectedImage ~= "" and selectedImage ~= "rbxassetid://0"
			headerIcon.Image = hasRealImage and selectedImage or DEFAULT_ICON
			headerIcon.ImageColor3 = hasRealImage and WHITE or DIM
			headerIcon.Visible = true
		end

		local function updateOpened()
			h2.Text = opened and "<" or ">"
			r1.Visible = opened
		end

		local function updateCard(card, state)
			if card == nil then return end
			card.root.BackgroundColor3 = state and ROW_SELECTED or ROW_BG
			card.root.BackgroundTransparency = state and 0 or 0.2
			card.button.BackgroundColor3 = state and BTN_ACTIVE or BTN_OFF
			card.check.Visible = state == true
		end

		local function selectField(name)
			if multi then
				selectedSet[name] = not selectedSet[name]
				updateCard(cards[name], selectedSet[name] == true)
				updateHeader()
				if type(d.changed) == "function" then d.changed(selectedSet) end
				return
			end

			local old = selected
			local new = name
			if selected == name and d.allow_none ~= false then new = nil end
			if old == new then return end

			selected = new
			actives[key] = selected or false
			if old ~= nil then updateCard(cards[old], false) end
			if selected ~= nil then updateCard(cards[selected], true) end
			updateHeader()
			if type(d.changed) == "function" then d.changed(selected) end
		end

		local function create(field, layout)
			local b = Instance_new("TextButton")
			b.Name = field.name
			b.BackgroundColor3 = ROW_BG
			b.BackgroundTransparency = 0.2
			b.BorderSizePixel = 0
			b.Size = UDim2_new(0.333, -8, 0, 32)
			b.LayoutOrder = layout
			b.AutoButtonColor = true
			b.ZIndex = 1004
			b.Text = ""
			b.Parent = r1
			b:SetAttribute("search_text", s_lower(field.name))
			corner(b, UDim_new(0, 7))

			local hasReal = field.image ~= "" and field.image ~= "rbxassetid://0"
			local icon = Instance_new("ImageLabel")
			icon.Name = "Icon"
			icon.AnchorPoint = Vector2_new(0, 0.5)
			icon.BackgroundTransparency = 1
			icon.BorderSizePixel = 0
			icon.Position = UDim2_new(0, 6, 0.5, 0)
			icon.Size = UDim2_fromOffset(21, 21)
			icon.ZIndex = 1006
			icon.Image = hasReal and field.image or DEFAULT_ICON
			icon.ImageColor3 = hasReal and WHITE or DIM
			icon.ScaleType = Scale_Fit
			icon.Visible = true
			icon.Parent = b

			local t = Instance_new("TextLabel")
			t.Name = "TextLabel"
			t.BackgroundTransparency = 1
			t.BorderSizePixel = 0
			t.Position = UDim2_new(0, 32, 0, 0)
			t.Size = UDim2_new(1, -62, 1, 0)
			t.ZIndex = 1005
			t.Font = Font_Medium
			t.Text = field.name
			t.TextColor3 = WHITE
			t.TextSize = 13
			t.TextTruncate = Trunc_End
			t.TextXAlignment = TextX_Left
			t.Parent = b

			local h3 = Instance_new("Frame")
			h3.Name = "Selected"
			h3.AnchorPoint = Vector2_new(1, 0.5)
			h3.BackgroundColor3 = BTN_OFF
			h3.BorderSizePixel = 0
			h3.Position = UDim2_new(1, -5, 0.5, 0)
			h3.Size = UDim2_fromOffset(23, 23)
			h3.ZIndex = 1005
			h3.Parent = b
			corner(h3, UDim_new(0.3, 0))

			local check = Instance_new("ImageLabel")
			check.Name = "Check"
			check.AnchorPoint = Vector2_new(0.5, 0.5)
			check.BackgroundTransparency = 1
			check.BorderSizePixel = 0
			check.Position = UDim2_fromScale(0.5, 0.5)
			check.Size = UDim2_fromScale(0.72, 0.72)
			check.ZIndex = 1006
			check.Image = CHECK_ICON
			check.ScaleType = Scale_Fit
			check.Visible = false
			check.Parent = h3

			local card = { root = b, button = h3, check = check }
			cards[field.name] = card

			updateCard(card, (multi and selectedSet[field.name] == true) or (not multi and selected == field.name))

			b.MouseButton1Click:Connect(function()
				selectField(field.name)
			end)
		end

		for i = 1, #fields do
			create(fields[i], i)
		end

		h.MouseButton1Click:Connect(function()
			opened = not opened
			updateOpened()
		end)
		h2.MouseButton1Click:Connect(function()
			opened = not opened
			updateOpened()
		end)

		updateHeader()
		updateOpened()
		return r1
	end

	local function addtokenpriority(parent, d, order)
		if not parent or type(d) ~= "table" then return end

		local list = d.list or data.tokens or {}
		local key = d.key or "token_priorities"
		local defaultPriority = d.default_priority or 0

		local priorities = actives[key]
		if type(priorities) ~= "table" then
			priorities = {}
			actives[key] = priorities
		end

		for _, v in ipairs(list) do
			local name  = type(v) == "table" and v.name or v
			local prio  = type(v) == "table" and tonumber(v.priority) or nil
			if type(name) == "string" and name ~= "" and priorities[name] == nil then
				priorities[name] = prio or defaultPriority
			end
		end

		local r = Instance_new("Frame")
		r.Name = d.name or "TokenPriority"
		r.BackgroundColor3 = ROW_BG
		r.BackgroundTransparency = 0.2
		r.AutomaticSize = Auto_Y
		r.BorderSizePixel = 0
		r.Size = UDim2_new(1.025, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent
		r:SetAttribute("search_text", s_lower(tostring(d.text or "")))
		corner(r, UDim_new(0, 7))
		makeList(r, UDim_new(0, 5), FillDir_V, HAlign_Center, VAlign_Top)
		makeShadow(r)

		local h = Instance_new("TextButton")
		h.Name = "Header"
		h.BackgroundTransparency = 1
		h.BorderSizePixel = 0
		h.Size = d.header_size or UDim2_new(0.96, 0, 0, 32)
		h.LayoutOrder = 0
		h.ZIndex = 1004
		h.Font = Font_Bold
		h.Text = tostring(d.text or "Token Priority")
		h.TextColor3 = WHITE
		h.TextSize = 15
		h.TextXAlignment = TextX_Left
		h.Parent = r

		local h2 = Instance_new("TextButton")
		h2.Name = "Arrow"
		h2.BackgroundColor3 = ARROW_BG
		h2.AnchorPoint = Vector2_new(0, 0)
		h2.Interactable = false
		h2.BorderSizePixel = 0
		h2.Position = UDim2_new(0.967, 0, 0.138, 0)
		h2.Size = UDim2_new(0.05, 0, 0.723, 0)
		h2.ZIndex = 1005
		h2.Font = Font_ExtraBold
		h2.Text = "<"
		h2.TextColor3 = WHITE
		h2.TextScaled = true
		h2.Parent = h
		corner(h2, UDim_new(0.4, 0))

		local r1 = Instance_new("Frame")
		r1.Name = "Rows"
		r1.AutomaticSize = Auto_Y
		r1.BackgroundTransparency = 1
		r1.Size = UDim2_new(1, 0, 0, 0)
		r1.LayoutOrder = 1
		r1.ZIndex = 1004
		r1.Visible = d.opened ~= false
		r1.Parent = r

		local rl = Instance_new("UIListLayout")
		rl.SortOrder = Sort_Layout
		rl.Padding = UDim_new(0, 5)
		rl.Wraps = true
		rl.FillDirection = FillDir_H
		rl.HorizontalAlignment = HAlign_Left
		rl.VerticalAlignment = VAlign_Top
		rl.Parent = r1

		local rp = Instance_new("UIPadding")
		rp.PaddingLeft = UDim_new(0, 6)
		rp.PaddingRight = UDim_new(0, 6)
		rp.PaddingBottom = UDim_new(0, 7)
		rp.Parent = r1

		h.MouseButton1Click:Connect(function()
			r1.Visible = not r1.Visible
			h2.Text = r1.Visible and "<" or ">"
		end)
		h2.MouseButton1Click:Connect(function()
			r1.Visible = not r1.Visible
			h2.Text = r1.Visible and "<" or ">"
		end)

		local function rebuild()
			local items = {}
			for _, v in ipairs(list) do
				local name = type(v) == "table" and v.name or v
				local image = type(v) == "table" and (v.image or "") or ""
				if type(name) == "string" and name ~= "" then
					items[#items + 1] = {
						name = name,
						image = image,
						priority = tonumber(priorities[name]) or 0,
					}
				end
			end

			t_sort(items, function(a, b)
				if a.priority ~= b.priority then
					return a.priority > b.priority
				end
				return a.name < b.name
			end)

			for _, child in ipairs(r1:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end

			for i = 1, #items do
				local item = items[i]
				local hasImg = item.image ~= ""

				local row = Instance_new("Frame")
				row.Name = item.name
				row.BackgroundColor3 = ROW_BG
				row.BackgroundTransparency = 0.2
				row.BorderSizePixel = 0
				row.Size = UDim2_new(0.333, -8, 0, 32)
				row.LayoutOrder = i
				row.ZIndex = 1004
				row.Parent = r1
				corner(row, UDim_new(0, 7))

				local rp2 = Instance_new("UIPadding")
				rp2.PaddingLeft = UDim_new(0, 8)
				rp2.PaddingRight = UDim_new(0, 6)
				rp2.Parent = row

				if hasImg then
					local icon = Instance_new("ImageLabel")
					icon.Name = "Icon"
					icon.BackgroundTransparency = 1
					icon.BorderSizePixel = 0
					icon.Position = UDim2_new(0, 0, 0.5, -9)
					icon.Size = UDim2_fromOffset(18, 18)
					icon.Image = item.image
					icon.ScaleType = Scale_Fit
					icon.ZIndex = 1006
					icon.Parent = row
				end

				local nameLabel = Instance_new("TextLabel")
				nameLabel.Name = "NameLabel"
				nameLabel.BackgroundTransparency = 1
				nameLabel.BorderSizePixel = 0
				nameLabel.Position = UDim2_new(0, hasImg and 24 or 0, 0, 0)
				nameLabel.Size = UDim2_new(1, hasImg and -66 or -42, 1, 0)
				nameLabel.ZIndex = 1005
				nameLabel.Font = Font_Medium
				nameLabel.Text = item.name
				nameLabel.TextColor3 = WHITE
				nameLabel.TextSize = 14
				nameLabel.TextTruncate = Trunc_End
				nameLabel.TextXAlignment = TextX_Left
				nameLabel.Parent = row

				local pbox = Instance_new("TextBox")
				pbox.Name = "PriorityBox"
				pbox.AnchorPoint = Vector2_new(1, 0.5)
				pbox.BackgroundColor3 = BTN_OFF
				pbox.BorderSizePixel = 0
				pbox.Position = UDim2_new(1, 0, 0.5, 0)
				pbox.Size = UDim2_fromOffset(36, 22)
				pbox.ZIndex = 1005
				pbox.Font = Font_Bold
				pbox.Text = tostring(item.priority)
				pbox.TextColor3 = WHITE
				pbox.TextSize = 13
				pbox.TextXAlignment = TextX_Center
				pbox.ClearTextOnFocus = false
				pbox.Parent = row
				corner(pbox, UDim_new(0.3, 0))

				pbox:GetPropertyChangedSignal("Text"):Connect(function()
					local txt = pbox.Text
					local filtered = s_gsub(txt, "[^%d%-]", "")
					if filtered ~= txt then
						pbox.Text = filtered
					end
				end)

				pbox.FocusLost:Connect(function()
					local num = tonumber(pbox.Text) or 0
					num = m_floor(num)
					priorities[item.name] = num
					if type(d.changed) == "function" then
						d.changed(priorities)
					end
					rebuild()
				end)
			end
		end

		rebuild()
		return r
	end

	local function additem(parent, d, order)
		if not parent or not d then return end
		local kind = s_lower(tostring(d.type or "text"))
		if kind == "button" then
			return addbutton(parent, d, order)
		elseif kind == "slider" then
			return addslider(parent, d, order)
		elseif kind == "addlistchose" then
			return addlistChose(parent, d, order)
		elseif kind == "tokenpriority" then
			return addtokenpriority(parent, d, order)
		elseif kind == "input" then
			return addinput(parent, d, order)
		end
		return addtext(parent, d, order)
	end

	local function addlist(parent, d, order)
		if not parent or not d then return end

		local opened = d.opened ~= false

		local l = Instance_new("Frame")
		l.Name = "List-" .. tostring(d.name or order or "List")
		l.AutomaticSize = Auto_Y
		l.BackgroundColor3 = Color3_fromRGB(28, 26, 31)
		l.BackgroundTransparency = 0.6
		l.BorderSizePixel = 0
		l.Size = d.size or UDim2_new(1, -12, 0, 36)
		l.LayoutOrder = order or 0
		l.ZIndex = 1003
		l.ClipsDescendants = false
		l.Parent = parent

		local c = Instance_new("UICorner")
		c.CornerRadius = d.radius or UDim_new(0, 9)
		c.Parent = l

		makeList(l, UDim_new(0, 5), FillDir_V, HAlign_Center, VAlign_Top)
		makeShadow(l)

		local h = Instance_new("TextButton")
		h.Name = "Header"
		h.BackgroundTransparency = 1
		h.BorderSizePixel = 0
		h.Size = d.header_size or UDim2_new(0.976, 0, 0, 32)
		h.LayoutOrder = 0
		h.ZIndex = 1004
		h.Text = tostring(d.name or order or "List")
		h.Font = Font_Bold
		h.TextColor3 = WHITE
		h.TextScaled = false
		h.TextSize = 18
		h.TextXAlignment = TextX_Left
		h.Parent = l

		local h2 = Instance_new("TextButton")
		h2.Name = "TextButton"
		h2.BackgroundColor3 = ARROW_BG
		h2.BackgroundTransparency = 0
		h2.BorderSizePixel = 0
		h2.Position = UDim2_new(0.949, 0, 0.138, 0)
		h2.Size = UDim2_new(0.05, 0, 0.723, 0)
		h2.ZIndex = 1005
		h2.Font = Font_ExtraBold
		h2.Text = "<"
		h2.TextColor3 = WHITE
		h2.TextScaled = true
		h2.Parent = h
		corner(h2, d.radius or UDim_new(0.4, 0))

		if d.header_dynamic then
			h.Text = ""

			local dynHolder = Instance_new("Frame")
			dynHolder.Name = "DynHolder"
			dynHolder.BackgroundTransparency = 1
			dynHolder.Position = UDim2_new(0, 8, 0, 0)
			dynHolder.Size = UDim2_new(0.9, -8, 1, 0)
			dynHolder.ZIndex = 1005
			dynHolder.ClipsDescendants = true
			dynHolder.Parent = h

			local dhl = Instance_new("UIListLayout")
			dhl.SortOrder = Sort_Layout
			dhl.Padding = UDim_new(0, 6)
			dhl.FillDirection = FillDir_H
			dhl.VerticalAlignment = VAlign_Center
			dhl.HorizontalAlignment = HAlign_Left
			dhl.Parent = dynHolder

			local function refreshHeader()
				for _, cc in ipairs(dynHolder:GetChildren()) do
					if cc:IsA("ImageLabel") or cc:IsA("TextLabel") then
						cc:Destroy()
					end
				end

				local info = d.header_dynamic()
				if type(info) ~= "table" or type(info.elements) ~= "table" then return end

				for idx = 1, #info.elements do
					local el = info.elements[idx]
					if el.type == "text" and el.value and tostring(el.value) ~= "" then
						local tt = Instance_new("TextLabel")
						tt.BackgroundTransparency = 1
						tt.AutomaticSize = Auto_X
						tt.Size = UDim2_new(0, 0, 1, 0)
						tt.Font = Font_Bold
						tt.Text = tostring(el.value)
						tt.TextColor3 = el.color or WHITE
						tt.TextSize = 16
						tt.TextXAlignment = TextX_Left
						tt.ZIndex = 1005
						tt.LayoutOrder = idx
						tt.Parent = dynHolder
					elseif el.type == "icon" then
						local img = el.value
						local isReal = img and img ~= "" and img ~= "rbxassetid://0"
						local i = Instance_new("ImageLabel")
						i.BackgroundTransparency = 1
						i.Size = UDim2_fromOffset(21, 21)
						i.Image = isReal and img or DEFAULT_ICON
						i.ImageColor3 = isReal and WHITE or DIM
						i.ScaleType = Scale_Fit
						i.ZIndex = 1006
						i.LayoutOrder = idx
						i.Parent = dynHolder
					end
				end
			end

			refreshHeader()
			if d._ref then
				d._ref.refresh = refreshHeader
			end
		end

		local r = Instance_new("Frame")
		r.Name = "Rows"
		r.AutomaticSize = Auto_Y
		r.BackgroundTransparency = 1
		r.Size = UDim2_new(1, 0, 0, 0)
		r.LayoutOrder = 1
		r.ZIndex = 1004
		r.Visible = opened
		r.Parent = l

		local rl = Instance_new("UIListLayout")
		rl.SortOrder = Sort_Layout
		rl.Padding = UDim_new(0, 5)
		rl.Wraps = true
		rl.FillDirection = FillDir_H
		rl.HorizontalAlignment = HAlign_Left
		rl.VerticalAlignment = VAlign_Top
		rl.Parent = r

		local rp = Instance_new("UIPadding")
		rp.PaddingLeft = UDim_new(0, 6)
		rp.PaddingRight = UDim_new(0, 6)
		rp.PaddingBottom = UDim_new(0, 7)
		rp.PaddingTop = UDim_new(0, 0)
		rp.Parent = r

		local function update()
			h2.Text = opened and "<" or ">"
			r.Visible = opened
		end

		h.MouseButton1Click:Connect(function()
			opened = not opened
			update()
		end)
		h2.MouseButton1Click:Connect(function()
			opened = not opened
			update()
		end)

		local items = d.items
		if items then
			for i = 1, #items do
				additem(r, items[i], i)
			end
		end

		update()
		return l
	end

	local function addsection(name)
		if not name then return end

		local p = Instance_new("ScrollingFrame")
		p.Name = "Section-" .. tostring(name)
		p.BackgroundTransparency = 1
		p.BorderSizePixel = 0
		p.Position = UDim2_new(0, 6, 0, 8)
		p.Size = UDim2_new(1, -12, 1, -16)
		p.ZIndex = 1002
		p.Visible = false
		p.ClipsDescendants = true
		p.AutomaticCanvasSize = Auto_Y
		p.CanvasSize = UDim2_new()
		p.ScrollBarImageColor3 = SCROLLBAR
		p.ScrollBarThickness = 5
		p.ScrollingDirection = Enum.ScrollingDirection.Y
		p.Parent = m
		makeList(p, UDim_new(0, 8), FillDir_V, HAlign_Center, VAlign_Top)

		sections[name] = p
		return p
	end

	local setting = {
		{
			name = "Farming",
			lists = {
				{
					--settings
					name = "Farm",
					opened = true,
					--
					items = {
						{ type = "button", text = "Auto Farm", key = "auto_farm", callback = farming.farm },
						{ type = "button", text = "Sprinker", key = "sprinkler", callback = farming.farm },
						{ type = "button", text = "Tool", key = "dig", callback = farming.dig },
						{
							type = "addlistchose",
							text = "Field",
							key = "field",
							allow_none = false,
							header_icon = true,
							changed = function()
								if actives["auto_farm"] then
									mod.farming.farm()
								end
							end,
						},
						{
							type = "slider",
							text = "Speed",
							key = "walkspeed",
							min = 1,
							max = 120,
							step = 1,
						},
					},
				},
				{
					--settings
					name = "Field",
					opened = true,
					items = {
						{ type = "button", text = "Bubble", key = "bubble", callback = farming.farm },
						{ type = "button", text = "Priority Tokens", key = "no_priotiy_tokens", callback = farming.farm },
						{ type = "button", text = "Priority Drops", key = "no_priority_drops", callback = farming.farm },
						{ type = "button", text = "Massles", key = "massles" },
						{ type = "button", text = "Sprouts", key = "sprout" },
						{
							type = "slider",
							text = "Mssles(1stud)",
							key = "massles_slider",
							min = 1,
							max = 10,
							step = 1,
						},

						{
							type = "addlistchose",
							text = "Farm In",
							key = "position_field",
							list = mod.data.positions,
							allow_none = false,
							header_icon = true,
							changed = function()
								if actives["auto_farm"] then
									mod.farming.farm()
								end
							end,
						},

						{
							type = "tokenpriority",
							text = "Token Priority",
							key = "token_priorities",
							list = mod.data.token_priorities,
							opened = false,
							changed = function()
								if mod.data.actives.auto_farm then
									if mod.farming._prioDebounce then
										task.cancel(mod.farming._prioDebounce)
									end
									mod.farming._prioDebounce = task.delay(0.5, function()
										mod.farming.farm()
									end)
								end
							end,
						},

						{
							type = "tokenpriority",
							text = "Drops Priority",
							key = "drops_priorities",
							list = mod.data.drops_priorities,
							opened = false,
							changed = function()
								if mod.data.actives.auto_farm then
									if mod.farming._prioDebounce then
										task.cancel(mod.farming._prioDebounce)
									end
									mod.farming._prioDebounce = task.delay(0.5, function()
										mod.farming.farm()
									end)
								end
							end,
						},
					},
				},
				{
					--settings
					name = "Convert Honey",
					opened = true,
					--
					items = {
						{ type = "button", text = "Honey Mask", key = "honey_mask" },
						{ type = "button", text = "Balloon", key = "balloon" },
						{
							type = "addlistchose",
							text = "Standart Mask",
							key = "mask",
							list = mod.data.mask,
							allow_none = false,
							header_icon = true,
						},
						{
							type = "slider",
							text = "Backpack %(MAX)",
							key = "backpack",
							min = 10,
							max = 100,
							step = 1,
						},
						{
							type = "slider",
							text = "Auto Convert(Minutes)",
							key = "convert_interval",
							min = 1,
							max = 120,
							step = 1,
						},
						--{
						--	type = "addlistchose",
						--	text = "Field",
						--	key = "field",
						--	allow_none = false,
						--	header_icon = true,
						--	changed = function()
						--		if actives["auto_farm"] then
						--			mod.farming.farm()
						--		end
						--	end,
						--},
					},
				},
				--{
				--	--settings
				--	name = "Other",
				--	opened = true,
				--	--
				--	items = {
				--		{ type = "button", text = "Massles", key = "massles" },
				--		{
				--			type = "slider",
				--			text = "massles(1stud)",
				--			key = "massles_slider",
				--			min = 1,
				--			max = 10,
				--			step = 1,
				--		},
				--	},
				--},
			},
		},
		
		{
			name = "Config",
			lists = {
				{
					--settings
					name = "Hive",
					opened = true,
					--
					items = {
						{ type = "button", text = "Auto Hive", key = "auto_hive", callback = convert.autoHive },
					},
				},
			},
		},
	}

	local b1 = Instance_new("TextButton")
	b1.Name = "button_search"
	b1.BackgroundTransparency = 1
	b1.BorderSizePixel = 0
	b1.Size = UDim2_new(0.675, 0, 0.068, 0)
	b1.Text = ""
	b1.ZIndex = 1002
	b1.Parent = f.Tab.Nav
	b1.LayoutOrder = -1
	makeCorner(b1, UDim_new(0.3, 0))
	makeList(b1, UDim_new(0.06, 0), FillDir_H, HAlign_Center, VAlign_Center)

	local image = Instance_new("ImageLabel")
	image.Name = "image"
	image.BackgroundTransparency = 1
	image.Size = UDim2_new(0.14, 0, 0.78, 0)
	image.ZIndex = 1002
	image.LayoutOrder = 0
	image.Image = "rbxassetid://4359655183"
	image.ImageColor3 = Color3_fromRGB(51, 48, 53)
	image.ScaleType = Scale_Fit
	image.Parent = b1

	local bt = Instance_new("TextBox")
	bt.Name = "TextBox"
	bt.AutomaticSize = Auto_X
	bt.BackgroundTransparency = 1
	bt.BorderSizePixel = 0
	bt.LayoutOrder = 1
	bt.Size = UDim2_new(0.712, 0, 0.831, 0)
	bt.ShowNativeInput = true
	bt.Text = ""
	bt.PlaceholderText = "Search"
	bt.ZIndex = 1003
	bt.Font = Font_Medium
	bt.PlaceholderColor3 = Color3_fromRGB(51, 48, 53)
	bt.TextColor3 = Color3_fromRGB(179, 175, 184)
	bt.TextScaled = true
	bt.TextWrapped = true
	bt.TextXAlignment = TextX_Left
	bt.Parent = b1

	for i = 1, #setting do
		local v = setting[i]
		local p = addsection(v.name)
		local lists = v.lists
		if lists then
			for ii = 1, #lists do
				addlist(p, lists[ii], ii)
			end
		end
	end

	local search_page = addsection("Search")
	local search = b1.TextBox

	if search then
		local function clear_search()
			local children = search_page:GetChildren()
			for i = 1, #children do
				local v = children[i]
				if v:IsA("Frame") and string.sub(v.Name, 1, 5) == "List-" then
					v:Destroy()
				end
			end
		end

		local function update_search(raw)
			local text = s_lower(tostring(raw or ""))
			text = s_gsub(text, "^%s+", "")
			text = s_gsub(text, "%s+$", "")

			clear_search()

			if text == "" then
				search_page.Visible = false
				for name, page in pairs(sections) do
					page.Visible = name == activeSection
				end
				return
			end

			for _, page in pairs(sections) do
				page.Visible = false
			end

			local order = 0

			for si = 1, #setting do
				local section = setting[si]
				local lists = section.lists
				if lists then
					for li = 1, #lists do
						local list = lists[li]
						local items = list.items
						if items then
							local matched = {}
							local list_text = s_lower(tostring(list.name or ""))
							local section_text = s_lower(tostring(section.name or ""))
							local listHit = s_find(list_text, text, 1, true) ~= nil
							local sectionHit = s_find(section_text, text, 1, true) ~= nil

							for ii = 1, #items do
								local item = items[ii]
								if listHit or sectionHit or s_find(s_lower(tostring(item.text or "")), text, 1, true) ~= nil then
									matched[#matched + 1] = item
								end
							end

							if #matched > 0 then
								order += 1
								addlist(search_page, {
									name = tostring(section.name) .. " / " .. tostring(list.name),
									opened = true,
									items = matched,
								}, order)
							end
						end
					end
				end
			end

			search_page.Visible = true
		end

		search:GetPropertyChangedSignal("Text"):Connect(function()
			update_search(search.Text)
		end)
	end

	uis.InputChanged:Connect(function(input)
		if active_slider == nil then return end
		local it = input.UserInputType
		if it ~= UIS_MouseMove and it ~= UIS_Touch then return end
		active_slider(input.Position.X)
	end)

	uis.InputEnded:Connect(function(input)
		local it = input.UserInputType
		if it == UIS_Mouse1 or it == UIS_Touch then
			active_slider = nil
		end
	end)

	for name, page in pairs(sections) do
		page.Visible = name == activeSection
	end

	for name, button in pairs(navigationButtons) do
		local on = name == activeSection
		button.BackgroundTransparency = on and 0 or 1
		button.textname.TextColor3 = on and WHITE or NAV_OFF
		button.icon.ImageColor3 = on and WHITE or NAV_OFF
	end
end

function menu.input(window, dragObject)
	local dragging = false
	local dragStart
	local startPosition
	local dragInput

	dragObject = dragObject or window
	dragObject.Active = true

	dragObject.InputBegan:Connect(function(input)
		local it = input.UserInputType
		if it ~= UIS_Mouse1 and it ~= UIS_Touch then return end

		dragging = true
		dragStart = input.Position
		startPosition = window.Position

		input.Changed:Connect(function()
			if input.UserInputState == UIS_End then
				dragging = false
			end
		end)
	end)

	dragObject.InputChanged:Connect(function(input)
		local it = input.UserInputType
		if it == UIS_MouseMove or it == UIS_Touch then
			dragInput = input
		end
	end)

	uis.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput then return end
		local delta = input.Position - dragStart
		window.Position = UDim2_new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)
end

function menu.client_menu()
	menu.main_create()
	menu.main_nav()
	menu.dop_create()

	local frame = playerGui:FindFirstChild("ScreenGui"):FindFirstChild("EggHuntLayerVisualOnly")
	menu.input(frame, frame.Tab)
end

return menu
