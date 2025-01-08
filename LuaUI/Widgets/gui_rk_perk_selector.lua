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

-- Chili instances
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local oldShopOpen = false
local mainWindow = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupWindow()
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	
	local newMainWindow = Window:New{
		--parent = screen0,
		name  = 'rk_main_menu',
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
	
	Window:New{
		parent = newMainWindow,
		name  = 'rk_main_menu',
		width = 280,
		height = 320,
		classname = "main_window_small",
		x = screenWidth/2 - 140,
		y = screenHeight/2 - 160,
		dockable = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {0, 0, 0, 0},
		--itemMargin  = {0, 0, 0, 0},
	}
	
	return newMainWindow
end

function widget:Update()
	if mainWindow and windowVisible then
		mainWindow:BringToFront()
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
	screen0 = Chili.Screen0
end
