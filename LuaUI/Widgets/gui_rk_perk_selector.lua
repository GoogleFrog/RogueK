--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Perk Selector",
		desc      = "Perk handling UI for Rogue-K",
		author    = "GoogleFrog",
		date      = "8 Jan 2025",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Chili classes
local Chili
local Button
local Label
local Checkbox
local Window
local Panel
local StackPanel
local TextBox
local Image
local Progressbar
local Control
local ScrollPanel

-- Chili instances
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_DISABLE_COLOR = {0.1, 0.1, 0.1, 0.85}
local BUTTON_DISABLE_FOCUS_COLOR = {0.1, 0.1, 0.1, 0.85}

-- Defined upon learning the appropriate colors
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR
local BUTTON_BORDER_COLOR

local inventoryWidth = 9
local inventoryHeight = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local oldShopOpen = false
local mainWindow = false
local activeButton = false
local activeItem = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetChiliMousePos()
	local mx, my = Spring.GetMouseState()
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	my = screenHeight - my
	if WG.uiScale and WG.uiScale ~= 1 then
		mx, my = mx/WG.uiScale, my/WG.uiScale
	end
	return mx, my
end

local function SetButtonState(button, disabled)
	button.disabled = disabled
	if disabled then
		button.backgroundColor = BUTTON_DISABLE_COLOR
		button.focusColor = BUTTON_DISABLE_FOCUS_COLOR
		button.borderColor = BUTTON_DISABLE_FOCUS_COLOR
	else
		button.backgroundColor = BUTTON_COLOR
		button.focusColor = BUTTON_FOCUS_COLOR
		button.borderColor = BUTTON_BORDER_COLOR
	end
	button:Invalidate()
end

local function SetActiveItem(newItem)
	if not newItem then
		activeItem = false
		if activeButton then
			screen0:RemoveChild(activeButton)
		end
		return
	end
	local mx, my = GetChiliMousePos()
	if not activeButton then
		activeButton = Button:New {
			parent = holder,
			x = mx - 40,
			y = my - 40,
			width = 80,
			height = 80,
			caption = newItem,
			padding = {0, 0, 0, 0},
		}
		activeButton.HitTest = function (self, x, y) return false end
	end
	activeItem = newItem
	activeButton:SetCaption(newItem)
	activeButton:Invalidate()
	screen0:AddChild(activeButton)
	activeButton:BringToFront()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetUnitEntry(parent, index)
	local holder = Control:New {
		parent = parent,
		x = 0,
		y = (index-1)*130,
		right = 0,
		height = 130,
		padding = { 0, 0, 0, 0 },
	}
	local unitNameBox = TextBox:New {
		parent = holder,
		x = 8,
		right = 0,
		y = 16,
		padding = { 4, 4, 4, 4 },
		fontSize = 20,
		text = "Empty Slot",
	}
	
	local turret = Button:New {
		parent = holder,
		x = 5,
		y = 55,
		width = 70,
		height = 70,
		caption = "turret",
		padding = {0, 0, 0, 0},
	}
	local mount = Button:New {
		parent = holder,
		x = 80,
		y = 55,
		width = 70,
		height = 70,
		caption = "mount",
		padding = {0, 0, 0, 0},
	}
end

local function GetArmyWindow(parent)
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	local teamID = Spring.GetMyTeamID()
	local window = Window:New{
		parent = parent,
		width = "43%",
		height = "80%",
		classname = "main_window_small",
		right = "5%",
		y = "10%",
		dockable = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {0, 0, 0, 0},
	}
	local invButtons = {}
	local inventory = {}
	
	local function ClickInventoryButtion(index)
		if activeItem then
			local newItem = inventory[index]
			invButtons[index].caption = activeItem
			inventory[index] = activeItem
			SetButtonState(invButtons[index], false)
			SetActiveItem(newItem)
		elseif inventory[index] then
			invButtons[index].caption = ""
			SetButtonState(invButtons[index], true)
			SetActiveItem(inventory[index])
			inventory[index] = false
		end
	end
	
	local index = 1
	for j = 1, inventoryHeight do
		for i = 1, inventoryWidth do
			local item = Spring.GetTeamRulesParam(teamID, "rk_inv_item_" .. index)
			local myIndex = index
			local button = Button:New {
				x = i*80- 30,
				y = j*80 + 520,
				width = 80,
				height = 80,
				caption = item or "",
				padding = {0, 0, 0, 0},
				parent = window,
				OnClick = {function (self) 
					ClickInventoryButtion(myIndex)
				end}
			}
			if not item then
				SetButtonState(button, true)
			end
			inventory[index] = item or false
			invButtons[index] = button
			index = index + 1
		end
	end
	
	local unitPanel = ScrollPanel:New {
		parent = window,
		x = 25,
		y = 25,
		right = 25,
		bottom = "30%",
		padding = { 4, 4, 4, 4 },
		scrollbarSize = 6,
		horizontalScrollbar = false,
	}
	
	local units = {}
	for i = 1, 4 do
		units[i] = GetUnitEntry(unitPanel, i)
	end
	
	local externalFuncs = {}
	function externalFuncs.AddToInventory(item)
		for i = 1, #inventory do
			if not inventory[i] then
				inventory[i] = item
				invButtons[i].caption = item
				SetButtonState(invButtons[i], false)
				break
			end
		end
	end
	
	return externalFuncs
end

local function GetBuyWindow(parent, armyFunctions)
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	local teamID = Spring.GetMyTeamID()
	local window = Window:New{
		parent = parent,
		width = "43%",
		height = "80%",
		classname = "main_window_small",
		x = "5%",
		y = "10%",
		dockable = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {0, 0, 0, 0},
	}
	
	local shopWidth = Spring.GetGameRulesParam("rk_shop_width")
	local shopHeight = Spring.GetGameRulesParam("rk_shop_height")
	local buttons = {}
	local shopItems = {}
	local selectionMade = false
	
	local inHighlightButton = false
	local function HighlightButton(x, y)
		inHighlightButton = true
		for i = 1, shopWidth do
			for j = 1, shopHeight do
				if i == x or j == y then
					if not (i == x and j == y) then -- Prevent recursion
						buttons[i][j]:MouseOver()
					end
				else
					buttons[i][j]:MouseOut()
				end
			end
		end
		inHighlightButton = false
	end
	
	local function SelectButton(x, y)
		if selectionMade then
			return
		end
		selectionMade = true
		for i = 1, shopWidth do
			for j = 1, shopHeight do
				local button = buttons[i][j]
				if i == x or j == y then
					button.caption = ""
					armyFunctions.AddToInventory(shopItems[i][j])
				end
				SetButtonState(button, true)
			end
		end
	end
	
	for i = 1, shopWidth do
		buttons[i] = {}
		shopItems[i] = {}
		for j = 1, shopHeight do
			local shopItem = Spring.GetTeamRulesParam(teamID, "rk_shop_item_" .. i .. "_" .. j)
			local button = Button:New {
				x = i*80,
				y = j*80,
				width = 80,
				height = 80,
				caption = shopItem,
				padding = {0, 0, 0, 0},
				parent = window,
				preserveChildrenOrder = true,
				OnClick = {function (self)
					SelectButton(i, j)
				end},
				OnMouseOver = {function (self)
					if not inHighlightButton then
						HighlightButton(i, j)
					end
				end},
				OnMouseOut = {function (self)
					if not inHighlightButton then
						HighlightButton(-1, -1)
					end
				end}
			}
			buttons[i][j] = button
			shopItems[i][j] = shopItem
		end
	end
end

local function AddMenuButtons(parent)
	local button = Button:New {
		x = 125,
		y = 25,
		width = 70,
		height = 40,
		caption = "Restart",
		padding = {0, 0, 0, 0},
		parent = parent,
		OnClick = {
			function (self) Spring.SendLuaMenuMsg("restartGame") end
		}
	}
	if not BUTTON_COLOR then
		BUTTON_COLOR = button.backgroundColor
	end
	if not BUTTON_FOCUS_COLOR then
		BUTTON_FOCUS_COLOR = button.focusColor
	end
	if not BUTTON_BORDER_COLOR then
		BUTTON_BORDER_COLOR = button.borderColor
	end
	
	local button = Button:New {
		x = 45,
		y = 25,
		width = 70,
		height = 40,
		caption = "Quit",
		padding = {0, 0, 0, 0},
		parent = parent,
		OnClick = {
			function (self) Spring.Reload("") end
		}
	}
end

local function SetupWindow()
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	
	local newMainWindow = Window:New{
		--parent = screen0,
		name  = 'rk_perk_window',
		classname = "window_black",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		dockable = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		noClickThrough = true,
		padding = {0, 0, 0, 0},
	}
	AddMenuButtons(newMainWindow)
	local armyFunctions = GetArmyWindow(newMainWindow)
	GetBuyWindow(newMainWindow, armyFunctions)
	
	return newMainWindow
end

function widget:Update()
	if mainWindow and windowVisible then
		mainWindow:BringToFront()
		if activeButton then
			local mx, my = GetChiliMousePos()
			activeButton:SetPos(mx - 40, my - 40)
			activeButton:BringToFront()
		end
	end
	local newShopOpen = (Spring.GetGameRulesParam("rk_in_shop") == 1)
	if newShopOpen == oldShopOpen then
		return
	end
	oldShopOpen = newShopOpen
	
	if newShopOpen and not windowVisible then
		if not mainWindow then
			mainWindow = SetupWindow()
		end
		screen0:AddChild(mainWindow)
		mainWindow:BringToFront()
		WG.SetMinimapVisibility(false)
		windowVisible = true
	elseif not newShopOpen and windowVisible then
		windowVisible = false
		screen0:RemoveChild(mainWindow)
		WG.SetMinimapVisibility(true)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	ScrollPanel = Chili.ScrollPanel
	screen0 = Chili.Screen0
end
