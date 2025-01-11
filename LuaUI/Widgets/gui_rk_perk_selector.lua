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

local INV_WIDTH = 7
local INV_HEIGHT_BASE = 2

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
local activeLevel = false

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

local function SetActiveItem(newItem, newLevel)
	if not newItem then
		activeItem = false
		activeLevel = false
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
	activeLevel = newLevel
	activeButton:SetCaption(GetShopName(newItem))
	activeButton:Invalidate()
	screen0:AddChild(activeButton)
	activeButton:BringToFront()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakeModuleEntry(holder, i, item, level, unitFuncs)
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
		unitFuncs.AddItem(item, level, "module", i)
	else
		moduleCtrl.OnClick = {function (self)
			unitFuncs.OnClickEmptySlot(self, "module", i)
		end}
	end
	return moduleCtrl
end

local function InitialiseUnitEntry(holder, unitFuncs, unitData)
	if not unitData then
		return false
	end
	local teamID = Spring.GetMyTeamID()
	local comboCtrl, turretCtrl, mountCtrl = false, false, false
	if unitData.combo then
		local comboName = itemDefs[unitData.combo.name].humanName
		comboCtrl = Button:New {
			parent = holder,
			x = 25,
			y = 50,
			width = ARMY_BUTTON_SIZE,
			height = ARMY_BUTTON_SIZE,
			caption = comboName,
			padding = {0, 0, 0, 0},
		}
		unitFuncs.AddItem(unitData.combo.name, unitData.combo.level, "combo")
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
		if unitData.turret then
			turretCtrl:SetCaption(GetShopName(unitData.turret.name))
			unitFuncs.AddItem(unitData.turret.name, unitData.turret.level, "turret")
		else
			turretCtrl.OnClick = {function (self)
				unitFuncs.OnClickEmptySlot(self, "turret")
			end}
		end
		if unitData.mount then
			mountCtrl:SetCaption(GetShopName(unitData.mount.name))
			unitFuncs.AddItem(unitData.mount.name, unitData.mount.level, "mount")
		else
			mountCtrl.OnClick = {function (self)
				unitFuncs.OnClickEmptySlot(self, "mount")
			end}
		end
	end
	
	local moduleCtrls = {}
	for i = 1, perkFunctions.GetModuleLimit() do
		local item = unitData.modules and unitData.modules[i]
		moduleCtrls[i] = MakeModuleEntry(holder, i, item and item.name, item and item.level, unitFuncs)
	end
	
	unitFuncs.RegisterItemControls(comboCtrl, turretCtrl, mountCtrl, moduleCtrls)
	return true
end

local function InitialiseEmptyUnit(holder, unitFuncs)
	local newUnit
	local function ClickMakeUnit()
		if activeItem then
			local activeDef = itemDefs[activeItem]
			if activeDef.isCombo or activeDef.isTurret or activeDef.isMount then
				local unitData = {
					modules = {},
				}
				if activeDef.isCombo then
					unitData.combo = {
						name = activeItem,
						level = activeLevel,
					}
				end
				if activeDef.isTurret then
					unitData.turret = {
						name = activeItem,
						level = activeLevel,
					}
				end
				if activeDef.isMount then
					unitData.mount = {
						name = activeItem,
						level = activeLevel,
					}
				end
				InitialiseUnitEntry(holder, unitFuncs, unitData)
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

local function ReadUnitDataParams(teamID, index)
	local unitData = {
		modules = {},
	}
	local combo = Spring.GetTeamRulesParam(teamID, "rk_unit_combo_" .. index)
	local mount = Spring.GetTeamRulesParam(teamID, "rk_unit_mount_" .. index)
	local turret = Spring.GetTeamRulesParam(teamID, "rk_unit_turret_" .. index)
	if combo then
		unitData.combo = {
			name = combo,
			level = Spring.GetTeamRulesParam(teamID, "rk_unit_combo_level_" .. index) or 1
		}
	end
	if mount then
		unitData.mount = {
			name = mount,
			level = Spring.GetTeamRulesParam(teamID, "rk_unit_mount_level_" .. index) or 1
		}
	end
	if turret then
		unitData.turret = {
			name = turret,
			level = Spring.GetTeamRulesParam(teamID, "rk_unit_turret_level_" .. index) or 1
		}
	end
	for i = 1, perkFunctions.GetModuleLimit() do
		unitData.modules[i] = {
			name = Spring.GetTeamRulesParam(teamID, "rk_unit_module_" .. index .. "_" .. i),
			level = Spring.GetTeamRulesParam(teamID, "rk_unit_module_level_" .. index .. "_" .. i),
		}
	end
	if not (unitData.combo or unitData.mount or unitData.turret) then
		return false
	end
	return unitData
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
	local unitData = {
		modules = {},
	}
	
	local internalFuncs = {}
	local externalFuncs = {}
	
	local function IsItemCompatible(newItem, existingItem)
		-- TODO: eg no +damage on constructors, or experience from lasers or laser-weilders.
		return not existingItem
	end
	
	local function UpdateName()
		if not nameCtrl then
			return
		end
		if unitData.turret and unitData.mount then
			nameCtrl:SetText(itemDefs[unitData.turret.name].humanName .. itemDefs[unitData.mount.name].humanName)
		elseif unitData.turret then
			nameCtrl:SetText(GetShopName(unitData.turret.name))
		elseif unitData.mount then
			nameCtrl:SetText(GetShopName(unitData.mount.name))
		elseif unitData.combo then
			nameCtrl:SetText(GetShopName(unitData.combo.name))
		end
	end
	
	function internalFuncs.AddItem(item, level, slotType, slotIndex)
		local added = false
		if slotType == "turret" and itemDefs[item].isTurret and IsItemCompatible(item, unitData.turret) then
			unitData.turret = unitData.turret or {}
			unitData.turret.name = item
			unitData.turret.level = (unitData.turret.level or 0) + level
			added = true
			UpdateName()
		elseif slotType == "mount" and itemDefs[item].isMount and IsItemCompatible(item, unitData.mount) then
			unitData.mount = unitData.mount or {}
			unitData.mount.name = item
			unitData.mount.level = (unitData.mount.level or 0) + level
			added = true
			UpdateName()
		elseif slotType == "combo" and itemDefs[item].isCombo and IsItemCompatible(item, unitData.combo) then
			unitData.combo = unitData.combo or {}
			unitData.combo.name = item
			unitData.combo.level = (unitData.combo.level or 0) + level
			added = true
			UpdateName()
		elseif slotType == "module" and itemDefs[item].isModule and IsItemCompatible(item, unitData.modules[slotIndex]) then
			unitData.modules[slotIndex] = unitData.modules[slotIndex] or {}
			unitData.modules[slotIndex].name = item
			unitData.modules[slotIndex].level = (unitData.modules[slotIndex].level or 0) + level
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
		if internalFuncs.AddItem(activeItem, activeLevel, slotType, slotIndex) then
			slotCtrl:SetCaption(GetShopName(activeItem))
			SetActiveItem(false)
		end
	end
	
	if not InitialiseUnitEntry(holder, internalFuncs, ReadUnitDataParams(teamID, index)) then
		InitialiseEmptyUnit(holder, internalFuncs)
	end
	
	function externalFuncs.NotifyUnitPerkUpdate(item)
		if item == "perk_module_limit" then
			if moduleCtrls then
				for i = 1, perkFunctions.GetModuleLimit() do
					if not moduleCtrls[i] then
						moduleCtrls[i] = MakeModuleEntry(holder, i, false, false, internalFuncs)
					end
				end
			end
		end
	end
	
	function externalFuncs.Serialise()
		if not (unitData.combo or unitData.turret or unitData.mount) then
			return false
		end
		local unitStr = ""
		if unitData.combo then
			unitStr = unitStr .. "combo|" .. unitData.combo.name .. "|" .. unitData.combo.level .. "|"
		end
		if unitData.turret then
			unitStr = unitStr .. "turret|" .. unitData.turret.name .. "|" .. unitData.turret.level .. "|"
		end
		if unitData.mount then
			unitStr = unitStr .. "mount|" .. unitData.mount.name .. "|" .. unitData.mount.level .. "|"
		end
		unitStr = unitStr .. "modules"
		for i = 1, perkFunctions.GetModuleLimit() do
			if unitData.modules[i] then
				unitStr = "|" .. unitData.modules[i].name .. "|" .. unitData.modules[i].level
			end
		end
		return unitStr
	end
	
	return externalFuncs
end

local function AddInventoryButton(holder, teamID, item, gx, gy, index, ClickFunc)
	local button = Button:New {
		parent = holder,
		buttonType = "inventory",
		buttonIndex = index,
		x = gx*INV_BUTTON_SIZE - 55,
		y = gy*INV_BUTTON_SIZE - 60,
		width = INV_BUTTON_SIZE,
		height = INV_BUTTON_SIZE,
		caption = GetShopName(item),
		padding = {0, 0, 0, 0},
		OnClick = {function (self)
			ClickFunc(index)
		end},
	}
	if not item then
		SetButtonState(button, true)
	end
	return button
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
	local inventory = {}
	local invButtons = {}
	local inventoryHeight = INV_HEIGHT_BASE
	
	local inventoryHolder = Control:New {
		parent = window,
		x = 0,
		y = "70%",
		right = 0,
		bottom = 0,
		padding = { 0, 0, 0, 0 },
	}
	local inventoryPanel = ScrollPanel:New {
		parent = inventoryHolder,
		x = 25,
		y = 25,
		right = 25,
		bottom = 25,
		padding = { 4, 4, 4, 4 },
		borderColor = {0, 0, 0, 0},
		scrollbarSize = 6,
		horizontalScrollbar = true,
	}
	
	local function ClickInventoryButtion(index)
		if activeItem then
			local newItem = inventory[index]
			invButtons[index].caption = GetShopName(activeItem)
			inventory[index] = {
				name = activeItem,
				level = activeLevel,
			}
			SetButtonState(invButtons[index], false)
			if newItem then
				SetActiveItem(newItem.name, newItem.level)
			else
				SetActiveItem(false)
			end
		elseif inventory[index] then
			invButtons[index].caption = GetShopName(false)
			SetButtonState(invButtons[index], true)
			SetActiveItem(inventory[index].name, inventory[index].level)
			inventory[index] = false
		end
	end
	
	local invIndex = 1
	for j = 1, inventoryHeight do
		for i = 1, INV_WIDTH do
			local item = Spring.GetTeamRulesParam(teamID, "rk_inv_item_" .. invIndex) or false
			local level = Spring.GetTeamRulesParam(teamID, "rk_inv_item_level_" .. invIndex) or 0
			invButtons[invIndex] = AddInventoryButton(inventoryPanel, teamID, item, i, j, invIndex, ClickInventoryButtion)
			inventory[invIndex] = item and {
				name = item,
				level = level,
			}
			invIndex = invIndex + 1
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
	function externalFuncs.AddToInventory(item, level)
		for i = 1, #inventory do
			if not inventory[i] then
				inventory[i] = {
					name = item,
					level = level,
				}
				invButtons[i].caption = GetShopName(item)
				SetButtonState(invButtons[i], false)
				return
			end
		end
		inventoryHeight = inventoryHeight + 1
		for i = 1, INV_WIDTH do
			invButtons[invIndex] = AddInventoryButton(inventoryPanel, teamID, toAdd, i, inventoryHeight, invIndex, ClickInventoryButtion)
			inventory[invIndex] = (i == 1) and {
				name = item,
				level = level,
			}
			invIndex = invIndex + 1
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
	
	function externalFuncs.SerialiseInventory(item)
		local serialised = {}
		for i = 1, #inventory do
			if inventory[i] then
				serialised[#serialised + 1] = inventory[i].name .. "|" .. inventory[i].level
			end
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
	
	function externalFuncs.AddPerk(item, level)
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
		perkLevel[item] = (perkLevel[item] or 0) + (level or 1)
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
	
	function externalFuncs.SerialisePerks(item)
		local serialised = {}
		for i = 1, #perks do
			serialised[i] = perks[i] .. "|" .. perkLevel[perks[i]]
		end
		return serialised
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
	local shopItemLevel = {}
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
					armyFunctions.AddToInventory(shopItems[i][j], shopItemLevel[i][j])
				end
				SetButtonState(button, true)
			end
		end
	end
	
	for i = 1, shopWidth do
		buttons[i] = {}
		shopItems[i] = {}
		shopItemLevel[i] = {}
		for j = 1, shopHeight do
			local shopItem = Spring.GetTeamRulesParam(teamID, "rk_shop_item_" .. i .. "_" .. j)
			local level = Spring.GetTeamRulesParam(teamID, "rk_shop_item_level_" .. i .. "_" .. j)
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
			shopItemLevel[i][j] = level
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

local function SendDoneAndLoadout()
	local units = armyFunctions.SerialiseUnits()
	local perks = perkFunctions.SerialisePerks()
	local inventory = armyFunctions.SerialiseInventory()
	local sendData = #units .. " " .. #perks .. " " .. #inventory
	for i = 1, #units do
		sendData = sendData .. " " .. (units[i] or "nounit")
	end
	for i = 1, #perks do
		sendData = sendData .. " " .. (perks[i] or "noperk")
	end
	for i = 1, #inventory do
		sendData = sendData .. " " .. inventory[i]
	end
	Spring.SendCommands("luarules rk_send_next_round_and_loadout " .. sendData)
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
			SendDoneAndLoadout()
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
