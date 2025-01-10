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

local itemDefs, itemLists = VFS.Include("LuaRules/Configs/rk_item_defs.lua")

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_DISABLE_COLOR = {0.1, 0.1, 0.1, 0.85}
local BUTTON_DISABLE_FOCUS_COLOR = {0.1, 0.1, 0.1, 0.85}

-- Defined upon learning the appropriate colors
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR
local BUTTON_BORDER_COLOR

local inventoryWidth = 7
local inventoryHeight = 2

local ARMY_BUTTON_SIZE = 65
local INV_BUTTON_SIZE = 80

local FONT_LARGE = 32
local FONT_MED = 18
local FONT_SMALL = 14
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local oldShopOpen = false
local mainWindow = false
local activeButton = false
local activeItem = false
local armyFunctions = false
local perkFunctions = false
local wantFullReset = false
local wantContinueToNextRound = false

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


local function GetShopName(shopItem)
	if not shopItem then
		return ""
	end
	local def = itemDefs[shopItem]
	local shopName = def.humanName
	if def.isTurret then
		shopName = shopName .. '-'
	elseif def.isMount then
		shopName = '-' .. shopName
	end
	return shopName
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
			padding = {0, 0, 0, 0},
		}
		activeButton.HitTest = function (self, x, y) return false end
	end
	activeItem = newItem
	activeButton:SetCaption(GetShopName(newItem))
	activeButton:Invalidate()
	screen0:AddChild(activeButton)
	activeButton:BringToFront()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakeModuleEntry(holder, i, item)
	local moduleCtrl = Button:New {
		parent = holder,
		x = ARMY_BUTTON_SIZE + 45 + i*ARMY_BUTTON_SIZE,
		y = 50,
		width = ARMY_BUTTON_SIZE,
		height = ARMY_BUTTON_SIZE,
		caption = "empty",
		padding = {0, 0, 0, 0},
	}
	if item then
		moduleCtrl:SetCaption(GetShopName(item))
		unitFuncs.AddItem(item, "module", i)
	else
		moduleCtrl.OnClick = {function (self)
			unitFuncs.OnClickEmptySlot(self, "module", i)
		end}
	end
	return moduleCtrl
end

local function InitialiseUnitEntry(holder, unitFuncs, combo, turret, mount, modules)
	local teamID = Spring.GetMyTeamID()
	local comboCtrl, turretCtrl, mountCtrl = false, false, false
	if combo then
		local comboName = itemDefs[combo].humanName
		comboCtrl = Button:New {
			parent = holder,
			x = 25,
			y = 50,
			width = ARMY_BUTTON_SIZE,
			height = ARMY_BUTTON_SIZE,
			caption = comboName,
			padding = {0, 0, 0, 0},
		}
		SetButtonState(comboCtrl, true)
		unitFuncs.AddItem(combo, "combo")
	else
		turretCtrl = Button:New {
			parent = holder,
			x = 25,
			y = 50,
			width = ARMY_BUTTON_SIZE,
			height = ARMY_BUTTON_SIZE,
			caption = "turret",
			padding = {0, 0, 0, 0},
		}
		mountCtrl = Button:New {
			parent = holder,
			x = ARMY_BUTTON_SIZE + 25,
			y = 50,
			width = ARMY_BUTTON_SIZE,
			height = ARMY_BUTTON_SIZE,
			caption = "chassis",
			padding = {0, 0, 0, 0},
		}
		if turret then
			turretCtrl:SetCaption(GetShopName(turret))
			unitFuncs.AddItem(turret, "turret")
		else
			turretCtrl.OnClick = {function (self)
				unitFuncs.OnClickEmptySlot(self, "turret")
			end}
		end
		if mount then
			mountCtrl:SetCaption(GetShopName(mount))
			unitFuncs.AddItem(mount, "mount")
		else
			mountCtrl.OnClick = {function (self)
				unitFuncs.OnClickEmptySlot(self, "mount")
			end}
		end
	end
	
	local moduleCtrls = {}
	for i = 1, perkFunctions.GetModuleLimit() do
		local item = modules and modules[i]
		moduleCtrls[i] = MakeModuleEntry(holder, i, item)
	end
	
	unitFuncs.RegisterItemControls(comboCtrl, turretCtrl, mountCtrl, moduleCtrls)
end

local function InitialiseEmptyUnit(holder, unitFuncs)
	local newUnit
	local function ClickMakeUnit()
		if activeItem then
			local activeDef = itemDefs[activeItem]
			if activeDef.isCombo or activeDef.isTurret or activeDef.isMount then
				if activeDef.isCombo then
					InitialiseUnitEntry(holder, unitFuncs, activeItem, false, false)
				end
				if activeDef.isTurret then
					InitialiseUnitEntry(holder, unitFuncs, false, activeItem, false)
				end
				if activeDef.isMount then
					InitialiseUnitEntry(holder, unitFuncs, false, false, activeItem)
				end
				newUnit:Dispose()
				SetActiveItem(false)
			end
		end
	end
	newUnit = Button:New {
		parent = holder,
		x = 25,
		y = 25,
		right = 25,
		bottom = 25,
		font = {size = FONT_MED},
		caption = "New unit: Place a turret, chassis or all-in-one here.",
		OnClick = {function (self)
			ClickMakeUnit()
		end},
		padding = {0, 0, 0, 0},
	}
end

local function GetUnitEntry(parent, index)
	local teamID = Spring.GetMyTeamID()
	local holder = Control:New {
		parent = parent,
		x = 0,
		y = (index-1)*(55 + ARMY_BUTTON_SIZE),
		right = 0,
		height = (55 + ARMY_BUTTON_SIZE),
		padding = { 0, 0, 0, 0 },
	}
	local nameCtrl = TextBox:New {
		parent = holder,
		x = 8,
		right = 0,
		y = 16,
		padding = { 4, 4, 4, 4 },
		fontSize = 20,
		text = "",
	}
	
	local comboCtrl, turretCtrl, mountCtrl, moduleCtrls = false, false, false, false, {}
	
	local combo = Spring.GetTeamRulesParam(teamID, "rk_unit_combo_" .. index)
	local mount = (not combo) and Spring.GetTeamRulesParam(teamID, "rk_unit_mount_" .. index)
	local turret = (not combo) and Spring.GetTeamRulesParam(teamID, "rk_unit_turret_" .. index)
	local modules = {}
	
	for i = 1, perkFunctions.GetModuleLimit() do
		modules[i] = Spring.GetTeamRulesParam(teamID, "rk_unit_module_" .. index .. "_" .. i)
	end
	
	local internalFuncs = {}
	local externalFuncs = {}
	
	local function IsItemCompatible(newItem)
		-- TODO: eg no +damage on constructors, or experience from lasers or laser-weilders.
		return true
	end
	
	local function UpdateName()
		if not nameCtrl then
			return
		end
		if turret and mount then
			nameCtrl:SetText(itemDefs[turret].humanName .. itemDefs[mount].humanName)
		elseif turret then
			nameCtrl:SetText(GetShopName(turret))
		elseif mount then
			nameCtrl:SetText(GetShopName(mount))
		elseif combo then
			nameCtrl:SetText(GetShopName(combo))
		end
	end
	
	function internalFuncs.AddItem(item, slotType, slotIndex)
		local added = false
		if slotType == "turret" and itemDefs[item].isTurret and IsItemCompatible(item) then
			turret = item
			added = true
			UpdateName()
		elseif slotType == "mount" and itemDefs[item].isMount and IsItemCompatible(item) then
			mount = item
			added = true
			UpdateName()
		elseif slotType == "combo" and itemDefs[item].isCombo and IsItemCompatible(item) then
			combo = item
			added = true
			UpdateName()
		elseif slotType == "module" and itemDefs[item].isModule and IsItemCompatible(item) then
			modules[slotIndex] = item
			added = true
		end
		return added
	end
	
	function internalFuncs.RegisterItemControls(newCombo, newTurret, newMount, newModules)
		comboCtrl, turretCtrl, mountCtrl, moduleCtrls = newCombo, newTurret, newMount, newModules
	end
	
	function internalFuncs.OnClickEmptySlot(slotCtrl, slotType, slotIndex)
		if not activeItem then
			return
		end
		if internalFuncs.AddItem(activeItem, slotType, slotIndex) then
			slotCtrl:SetCaption(GetShopName(activeItem))
			SetActiveItem(false)
		end
	end
	
	if (combo or mount or turret) then
		InitialiseUnitEntry(holder, internalFuncs, combo, turret, mount, modules)
	else
		InitialiseEmptyUnit(holder, internalFuncs)
	end
	
	function externalFuncs.NotifyUnitPerkUpdate(item)
		if item == "perk_module_limit" then
			if moduleCtrls then
				for i = 1, perkFunctions.GetModuleLimit() do
					if not moduleCtrls[i] then
						moduleCtrls[i] = MakeModuleEntry(holder, i, false)
					end
				end
			end
		end
	end
	
	function externalFuncs.Serialise()
		if not (combo or turret or mount) then
			return false
		end
		local unitStr = ""
		if combo then
			unitStr = unitStr .. "combo|" .. combo .. "|"
		end
		if turret then
			unitStr = unitStr .. "turret|" .. turret .. "|"
		end
		if mount then
			unitStr = unitStr .. "mount|" .. mount .. "|"
		end
		unitStr = unitStr .. "modules"
		for i = 1, moduleLimit do
			if modules[i] then
				unitStr = "|" .. modules[i]
			end
		end
		return unitStr
	end
	
	return externalFuncs
end

local function GetArmyWindow(parent)
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	local teamID = Spring.GetMyTeamID()
	local window = Window:New{
		parent = parent,
		width = "35%",
		height = "90%",
		classname = "main_window_small",
		right = "5%",
		y = "5%",
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
			invButtons[index].caption = GetShopName(activeItem)
			inventory[index] = activeItem
			SetButtonState(invButtons[index], false)
			SetActiveItem(newItem)
		elseif inventory[index] then
			invButtons[index].caption = GetShopName(false)
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
				buttonType = "inventory",
				buttonIndex = myIndex,
				x = i*INV_BUTTON_SIZE - 30,
				bottom = (inventoryHeight - j)*INV_BUTTON_SIZE + 64,
				width = INV_BUTTON_SIZE,
				height = INV_BUTTON_SIZE,
				caption = GetShopName(item),
				padding = {0, 0, 0, 0},
				parent = window,
				OnClick = {function (self)
					ClickInventoryButtion(myIndex)
				end},
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
		horizontalScrollbar = true,
	}
	
	local units = {}
	for i = 1, perkFunctions.GetUnitLimit() do
		units[i] = GetUnitEntry(unitPanel, i)
	end
	
	local externalFuncs = {}
	function externalFuncs.AddToInventory(item)
		for i = 1, #inventory do
			if not inventory[i] then
				inventory[i] = item
				invButtons[i].caption = GetShopName(item)
				SetButtonState(invButtons[i], false)
				break
			end
		end
	end
	
	function externalFuncs.NotifyArmyPerkUpdate(item)
		if item == "perk_unit_limit" then
			for i = 1, perkFunctions.GetUnitLimit() do
				if not units[i] then
					units[i] = GetUnitEntry(unitPanel, i)
				end
			end
		elseif item == "perk_module_limit" then
			for i = 1, perkFunctions.GetUnitLimit() do
				units[i].NotifyUnitPerkUpdate(item)
			end
		end
	end
	
	function externalFuncs.SerialiseUnits(item)
		local serialised = {}
		for i = 1, #units do
			serialised[i] = units[i].Serialise()
		end
		return serialised
	end
	
	return externalFuncs
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetPerkWindow(parent)
	local teamID = Spring.GetMyTeamID()
	local perkPanel = ScrollPanel:New {
		parent = parent,
		x = 10,
		y = 10,
		right = 10,
		bottom = 10,
		padding = { 4, 4, 4, 4 },
		scrollbarSize = 6,
		horizontalScrollbar = true,
	}
	
	local perks = {}
	local perkButtons = {}
	local perkLevel = {}
	
	local cachedParameters = {}
	local externalFuncs = {}
	
	local function UpdateCache(item)
		if item == "perk_unit_limit" then
			cachedParameters.unitLimit = perkLevel[item]
		elseif item == "perk_module_limit" then
			cachedParameters.moduleLimit = perkLevel[item]
		end
	end
	
	function externalFuncs.AddPerk(item, levels)
		if not perkLevel[item] then
			local px = #perks % 3
			local py = (#perks - px) / 3
			local button = Button:New {
				parent = perkPanel,
				x = px*INV_BUTTON_SIZE + 8,
				y = py*INV_BUTTON_SIZE + 8,
				width = INV_BUTTON_SIZE,
				height = INV_BUTTON_SIZE,
				caption = GetShopName(item),
				padding = {0, 0, 0, 0},
			}
			perks[#perks + 1] = item
			perkButtons[item] = button
		end
		perkLevel[item] = (perkLevel[item] or 0) + (levels or 1)
		UpdateCache(item)
		if armyFunctions then
			armyFunctions.NotifyArmyPerkUpdate(item)
		end
	end
	
	local index = 1
	while index do
		local perk = Spring.GetTeamRulesParam(teamID, "rk_perk_" .. index)
		if perk then
			local level = Spring.GetTeamRulesParam(teamID, "rk_perk_level_" .. index) or 1
			externalFuncs.AddPerk(perk, level)
			index = index + 1
		else
			index = false
		end
	end
	
	function externalFuncs.GetUnitLimit()
		return cachedParameters.unitLimit or 1
	end
	
	function externalFuncs.GetModuleLimit()
		return cachedParameters.moduleLimit or 1
	end
	
	return externalFuncs
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetBuyWindow(parent)
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	local teamID = Spring.GetMyTeamID()
	local window = Window:New{
		parent = parent,
		width = "50%",
		height = "90%",
		classname = "main_window_small",
		x = "5%",
		y = "5%",
		dockable = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
	}
	local perkHolder = Control:New{
		parent = window,
		x = "70%",
		y = 5,
		right = 5,
		bottom = "45%",
		padding = {0, 0, 0, 0},
	}
	perkFunctions = GetPerkWindow(perkHolder)
	
	local shopWidth = Spring.GetGameRulesParam("rk_shop_width")
	local shopHeight = Spring.GetGameRulesParam("rk_shop_height")
	local buttons = {}
	local shopItems = {}
	local selectionMade = false
	
	local resetButton = Button:New {
		parent = window,
		x = 15,
		bottom = 15,
		width = INV_BUTTON_SIZE*2.5,
		height = INV_BUTTON_SIZE,
		caption = "Reset",
		font = {size = FONT_LARGE},
		padding = {0, 0, 0, 0},
	}
	local doneButton = Button:New {
		parent = window,
		right = 15,
		bottom = 15,
		width = INV_BUTTON_SIZE*2.5,
		height = INV_BUTTON_SIZE,
		caption = "Continue",
		font = {size = FONT_LARGE},
		padding = {0, 0, 0, 0},
	}
	SetButtonState(doneButton, true)
	SetButtonState(resetButton, true)
	
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
		SetButtonState(doneButton, false)
		SetButtonState(resetButton, false)
		doneButton.OnClick = {function (self)
			wantContinueToNextRound = true
		end}
		resetButton.OnClick = {function (self)
			wantFullReset = true
		end}
		
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
				caption = GetShopName(shopItem),
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddMenuButtons(parent)
	local button = Button:New {
		x = 225,
		y = 5,
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
		x = 145,
		y = 5,
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
	GetBuyWindow(newMainWindow, armyFunctions)
	armyFunctions = GetArmyWindow(newMainWindow)
	
	return newMainWindow
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SendFactionSpec()
	local units = armyFunctions.SerialiseUnits()
	for i = 1, #units do
		if units[i] then
			Spring.SendCommands("luarules rk_send_unit_spec " .. i .. " " .. units[i])
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update()
	local newShopOpen = (Spring.GetGameRulesParam("rk_in_shop") == 1)
	if wantFullReset and newShopOpen then
		wantFullReset = false
		mainWindow:Dispose()
		mainWindow = SetupWindow()
		screen0:AddChild(mainWindow)
	end
	if wantContinueToNextRound then
		if oldShopOpen and mainWindow then
			SendFactionSpec()
			oldShopOpen = false
			windowVisible = false
			screen0:RemoveChild(mainWindow)
			WG.SetMinimapVisibility(true)
		end
		return
	end
	
	if mainWindow and windowVisible then
		mainWindow:BringToFront()
		if activeButton then
			local mx, my = GetChiliMousePos()
			activeButton:SetPos(mx - 40, my - 40)
			activeButton:BringToFront()
		end
	end
	
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

function widget:MousePress(x, y, button)
	if button == 3 and activeItem and armyFunctions then
		armyFunctions.AddToInventory(activeItem)
		SetActiveItem(false)
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
