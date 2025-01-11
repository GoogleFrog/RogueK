--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Rogue-K Main Menu",
		desc      = "Main menu, saving, loading etc for Rogue-K",
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

local oldPregame = false
local mainWindow = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupWindow()
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	
	local newMainWindow = Window:New{
		--parent = screen0,
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
	
	local label_text = TextBox:New{
		x = 36,
		right = 20,
		y = 32,
		parent = newMainWindow,
		autosize = false,
		align  = "center",
		valign = "top",
		text   = "Rogue-K",
		font   = {size = 20, color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, outlineWidth = 3},
	}
	local button_start = Button:New {
		y = "55%",
		bottom = "24%",
		x = "25%",
		right = "25%",
		classname = "action_button",
		parent = newMainWindow,
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		caption = "New Game",
		font   = {size = 20, color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, outlineWidth = 3},
		--tooltip = "Start a new game.",
		OnClick = {
			function()
				Spring.SendCommands("luarules rk_new_game")
				Spring.SendCommands("forcestart")
			end
		}
	}
	return newMainWindow
end

function widget:Update()
	local newPregame = (Spring.GetGameRulesParam("rk_preGame") == 1)
	if newPregame == oldPregame then
		return
	end
	oldPregame = newPregame
	
	if newPregame and not windowVisible then
		if not mainWindow then
			mainWindow = SetupWindow()
		end
		screen0:AddChild(mainWindow)
		windowVisible = true
	elseif not newPregame and windowVisible then
		windowVisible = false
		screen0:RemoveChild(mainWindow)
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
