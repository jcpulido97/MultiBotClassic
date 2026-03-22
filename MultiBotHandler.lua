-- TIMER --

local function MultiBotEnsureRuntimeState()
	if(MultiBot.auto == nil) then MultiBot.auto = {} end
	if(MultiBot.timer == nil) then MultiBot.timer = {} end

	if(MultiBot.auto.sort == nil) then MultiBot.auto.sort = false end
	if(MultiBot.auto.stats == nil) then MultiBot.auto.stats = false end
	if(MultiBot.auto.talent == nil) then MultiBot.auto.talent = false end
	if(MultiBot.auto.invite == nil) then MultiBot.auto.invite = false end
	if(MultiBot.auto.release == nil) then MultiBot.auto.release = false end

	if(MultiBot.timer.sort == nil) then MultiBot.timer.sort = {} end
	if(MultiBot.timer.stats == nil) then MultiBot.timer.stats = {} end
	if(MultiBot.timer.talent == nil) then MultiBot.timer.talent = {} end
	if(MultiBot.timer.invite == nil) then MultiBot.timer.invite = {} end

	if(MultiBot.timer.sort.elapsed == nil) then MultiBot.timer.sort.elapsed = 0 end
	if(MultiBot.timer.sort.interval == nil) then MultiBot.timer.sort.interval = 1 end
	if(MultiBot.timer.sort.index == nil) then MultiBot.timer.sort.index = 1 end
	if(MultiBot.timer.sort.needs == nil) then MultiBot.timer.sort.needs = 0 end

	if(MultiBot.timer.stats.elapsed == nil) then MultiBot.timer.stats.elapsed = 0 end
	if(MultiBot.timer.stats.interval == nil) then MultiBot.timer.stats.interval = 45 end

	if(MultiBot.timer.talent.elapsed == nil) then MultiBot.timer.talent.elapsed = 0 end
	if(MultiBot.timer.talent.interval == nil) then MultiBot.timer.talent.interval = 3 end

	if(MultiBot.timer.invite.elapsed == nil) then MultiBot.timer.invite.elapsed = 0 end
	if(MultiBot.timer.invite.interval == nil) then MultiBot.timer.invite.interval = 5 end
	if(MultiBot.timer.invite.roster == nil) then MultiBot.timer.invite.roster = "" end
	if(MultiBot.timer.invite.index == nil) then MultiBot.timer.invite.index = 1 end
	if(MultiBot.timer.invite.needs == nil) then MultiBot.timer.invite.needs = 0 end
end

local function MultiBotEnsureUnitControlState()
	if(MultiBot.unitControl == nil) then MultiBot.unitControl = {} end
	if(MultiBot.unitControl.actives == nil) then MultiBot.unitControl.actives = {} end
	if(MultiBot.unitControl.actives.order == nil) then MultiBot.unitControl.actives.order = {} end
	if(MultiBot.unitControl.actives.collapsed == nil) then MultiBot.unitControl.actives.collapsed = {} end
	if(MultiBot.unitControl.actives.pageStart == nil) then MultiBot.unitControl.actives.pageStart = 1 end
	return MultiBot.unitControl.actives
end

function MultiBot.GetActivePageSize()
	local tButton = nil
	if(MultiBot.frames ~= nil and MultiBot.frames["MultiBar"] ~= nil) then
		tButton = MultiBot.frames["MultiBar"].buttons["Units"]
	end
	if(tButton ~= nil and tButton.pageSize ~= nil) then return tButton.pageSize end
	return 10
end

function MultiBot.ClampActivePage()
	local tActives = MultiBotEnsureUnitControlState()
	local tPageSize = MultiBot.GetActivePageSize()
	local tLimit = table.getn(tActives.order)

	if(tLimit <= 0) then
		tActives.pageStart = 1
		return tActives.pageStart
	end

	if(tActives.pageStart < 1) then tActives.pageStart = 1 end

	local tLastPageStart = tLimit - tPageSize + 1
	if(tLastPageStart < 1) then tLastPageStart = 1 end
	if(tActives.pageStart > tLastPageStart) then tActives.pageStart = tLastPageStart end
	return tActives.pageStart
end

function MultiBot.GetOrderedActives(pFilter)
	local tActives = MultiBotEnsureUnitControlState()
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tOrder = {}

	for i = 1, table.getn(tActives.order) do
		local tName = tActives.order[i]
		local tButton = tUnits.buttons[tName]
		if(tButton ~= nil and (pFilter == nil or pFilter == "none" or tButton.class == pFilter)) then
			table.insert(tOrder, tName)
		end
	end

	return tOrder
end

function MultiBot.SetUnitCollapsed(pName, pCollapsed)
	if(pName == nil) then return false end
	local tActives = MultiBotEnsureUnitControlState()
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tButton = tUnits.buttons[pName]
	local tFrame = tUnits.frames[pName]

	if(pCollapsed) then
		tActives.collapsed[pName] = true
	else
		tActives.collapsed[pName] = nil
	end

	if(tButton ~= nil) then tButton.expanded = not pCollapsed end

	if(tFrame ~= nil) then
		if(pCollapsed or (tButton ~= nil and tButton.state == false)) then
			tFrame:Hide()
		else
			tFrame:Show()
		end
	end

	return true
end

function MultiBot.ApplyUnitCollapsed(pName)
	if(pName == nil) then return false end
	local tActives = MultiBotEnsureUnitControlState()
	return MultiBot.SetUnitCollapsed(pName, tActives.collapsed[pName] == true)
end

function MultiBot.CollapseUnitButton(pButton)
	if(pButton == nil) then return false end
	MultiBot.SetUnitCollapsed(pButton.name, true)
	return true
end

function MultiBot.ToggleUnitButtonFrame(pButton)
	if(pButton == nil or pButton.state == false) then return false end

	local tFrame = pButton.parent.frames[pButton.name]
	if(tFrame == nil) then
		MultiBot.SetUnitCollapsed(pButton.name, false)
		return true
	end

	local tExpanded = MultiBot.ShowHideSwitch(tFrame)
	MultiBot.SetUnitCollapsed(pButton.name, not tExpanded)
	return tExpanded
end

local function MultiBotSyncActiveClassIndex(pButton)
	if(pButton == nil) then return end
	if(MultiBot.index.classes.actives[pButton.class] == nil) then MultiBot.index.classes.actives[pButton.class] = {} end
	if(MultiBot.isActive(pButton.name) == false) then
		table.insert(MultiBot.index.classes.actives[pButton.class], pButton.name)
		table.insert(MultiBot.index.actives, pButton.name)
	end
end

local function MultiBotRemoveActiveByName(pName)
	if(pName == nil) then return end

	local tActives = MultiBotEnsureUnitControlState()
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tButton = tUnits.buttons[pName]
	local tFrame = tUnits.frames[pName]

	if(tButton ~= nil) then
		MultiBot.doRemove(MultiBot.index.classes.actives[tButton.class], pName)
		tButton.setDisable()
	end

	MultiBot.doRemove(MultiBot.index.actives, pName)
	MultiBot.doRemove(tActives.order, pName)
	if(tFrame ~= nil) then tFrame:Hide() end
end

local function MultiBotSetupActiveButton(pButton)
	pButton.doRight = function(pActiveButton)
		SendChatMessage(".playerbot bot remove " .. pActiveButton.name, "SAY")
		MultiBot.CollapseUnitButton(pActiveButton)
		pActiveButton.setDisable()
	end

	pButton.doLeft = function(pActiveButton)
		if(pActiveButton.state) then
			MultiBot.ToggleUnitButtonFrame(pActiveButton)
		else
			SendChatMessage(".playerbot bot add " .. pActiveButton.name, "SAY")
			pActiveButton.setEnable()
			MultiBot.SetUnitCollapsed(pActiveButton.name, false)
		end
	end

	return pButton
end

local function MultiBotSyncGroupUnit(pUnit)
	local tName = UnitName(pUnit)
	if(tName == nil or tName == UnitName("player")) then return end

	local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]

	if(tButton == nil) then
		local tLocalizedClass, tClass = UnitClass(pUnit)
		local tLevel = UnitLevel(pUnit)
		tButton = MultiBot.addActive(MultiBot.IF(tClass ~= nil, tClass, tLocalizedClass), tLevel, tName).setDisable()
		MultiBotSetupActiveButton(tButton)
	end

	MultiBotSyncActiveClassIndex(tButton)
	tButton.setEnable()
	MultiBot.ApplyUnitCollapsed(tButton.name)
end

local function MultiBotRefreshGroupRoster()
	local tActives = MultiBotEnsureUnitControlState()
	local tOrder = {}
	local tSeen = {}
	local tCount = GetNumRaidMembers()

	if(tCount > 0) then
		for i = 1, tCount do
			local tUnit = "raid" .. i
			local tName = UnitName(tUnit)
			if(tName ~= nil and tName ~= UnitName("player")) then
				table.insert(tOrder, tName)
				tSeen[tName] = true
				MultiBotSyncGroupUnit(tUnit)
			end
		end
	else
		tCount = GetNumPartyMembers()
		for i = 1, tCount do
			local tUnit = "party" .. i
			local tName = UnitName(tUnit)
			if(tName ~= nil and tName ~= UnitName("player")) then
				table.insert(tOrder, tName)
				tSeen[tName] = true
				MultiBotSyncGroupUnit(tUnit)
			end
		end
	end

	for i = table.getn(MultiBot.index.actives), 1, -1 do
		local tName = MultiBot.index.actives[i]
		if(tSeen[tName] ~= true) then
			MultiBotRemoveActiveByName(tName)
		end
	end

	tActives.order = tOrder
	MultiBot.ClampActivePage()

	local tUnits = MultiBot.frames["MultiBar"].buttons["Units"]
	if(tUnits.roster == "actives") then
		MultiBot.renderUnits(tUnits, false)
	end
end

MultiBot.RefreshGroupRoster = MultiBotRefreshGroupRoster

MultiBot:SetScript("OnUpdate", function(pSelf, pElapsed)
	MultiBotEnsureRuntimeState()

	if(MultiBot.auto.invite) then MultiBot.timer.invite.elapsed = MultiBot.timer.invite.elapsed + pElapsed end
	if(MultiBot.auto.talent) then MultiBot.timer.talent.elapsed = MultiBot.timer.talent.elapsed + pElapsed end
	if(MultiBot.auto.stats) then MultiBot.timer.stats.elapsed = MultiBot.timer.stats.elapsed + pElapsed end
	if(MultiBot.auto.sort) then MultiBot.timer.sort.elapsed = MultiBot.timer.sort.elapsed + pElapsed end
	
	if(MultiBot.auto.stats and MultiBot.timer.stats.elapsed >= MultiBot.timer.stats.interval) then
		for i = 1, GetNumPartyMembers() do SendChatMessage("stats", "WHISPER", nil, UnitName("party" .. i)) end
		MultiBot.timer.stats.elapsed = 0
	end
	
	if(MultiBot.auto.talent and MultiBot.timer.talent.elapsed >= MultiBot.timer.talent.interval) then
		MultiBot.talent.setTalents()
		MultiBot.timer.talent.elapsed = 0
		MultiBot.auto.talent = false
	end
	
	if(MultiBot.auto.invite and MultiBot.timer.invite.elapsed >= MultiBot.timer.invite.interval) then
		local tTable = MultiBot.index[MultiBot.timer.invite.roster]
		
		if(MultiBot.timer.invite.needs == 0 or MultiBot.timer.invite.index > table.getn(tTable)) then
			if(MultiBot.timer.invite.roster == "raidus") then
				MultiBot.timer.sort.elapsed = 0
				MultiBot.timer.sort.index = 1
				MultiBot.timer.sort.needs = 0
				MultiBot.auto.sort = true
			end
			
			MultiBot.timer.invite.elapsed = 0
			MultiBot.timer.invite.roster = ""
			MultiBot.timer.invite.index = 1
			MultiBot.timer.invite.needs = 0
			MultiBot.auto.invite = false
			return
		end
		
		if(MultiBot.isMember(tTable[MultiBot.timer.invite.index]) == false) then
			SendChatMessage(MultiBot.doReplace(MultiBot.info.inviting, "NAME", tTable[MultiBot.timer.invite.index]), "SAY")
			SendChatMessage(".playerbot bot add " .. tTable[MultiBot.timer.invite.index], "SAY")
			MultiBot.timer.invite.needs = MultiBot.timer.invite.needs - 1
		end
		
		MultiBot.timer.invite.index = MultiBot.timer.invite.index + 1
		MultiBot.timer.invite.elapsed = 0
	end
	
	if(MultiBot.auto.sort and MultiBot.timer.sort.elapsed >= MultiBot.timer.sort.interval) then
		MultiBot.timer.sort.index = MultiBot.raidus.doRaidSort(MultiBot.timer.sort.index)
		
		if(MultiBot.timer.sort.index == nil) then
			MultiBot.timer.sort.index = MultiBot.raidus.doRaidSortCheck()
		end
		
		if(MultiBot.timer.sort.index == nil) then
			SendChatMessage("Ready for Raid now.", "SAY")
			MultiBot.timer.sort.elapsed = 0
			MultiBot.timer.sort.index = 1
			MultiBot.timer.sort.needs = 0
			MultiBot.auto.sort = false
			return
		end
		
		MultiBot.timer.sort.elapsed = 0
	end
end)

-- HANDLER --

MultiBot:SetScript("OnEvent", function(_, event, ...)
	MultiBotEnsureRuntimeState()
	local arg1, arg2, arg3, arg4, arg5 = ...

	local function MultiBotSetSavedToggle(pButton, pEnabled)
		if(pEnabled) then
			pButton.setEnable()
		else
			pButton.setDisable()
		end
	end

	local function MultiBotRestoreMasters(pEnabled)
		local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Masters"]
		MultiBotSetSavedToggle(tButton, pEnabled)
		MultiBot.frames["MultiBar"].frames["Masters"]:Hide()
		if(pEnabled) then
			MultiBot.GM = true
			MultiBot.doRepos("Right", 38)
			MultiBot.frames["MultiBar"].buttons["Masters"]:Show()
		else
			MultiBot.frames["MultiBar"].buttons["Masters"]:Hide()
		end
	end

	local function MultiBotRestoreCreator(pEnabled)
		local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Creator"]
		MultiBotSetSavedToggle(tButton, pEnabled)
		MultiBot.frames["MultiBar"].frames["Left"].frames["Creator"]:Hide()
		if(pEnabled) then
			MultiBot.doRepos("Tanker", -34)
			MultiBot.doRepos("Attack", -34)
			MultiBot.doRepos("Mode", -34)
			MultiBot.doRepos("Stay", -34)
			MultiBot.doRepos("Follow", -34)
			MultiBot.doRepos("ExpandStay", -34)
			MultiBot.doRepos("ExpandFollow", -34)
			MultiBot.doRepos("Flee", -34)
			MultiBot.doRepos("Format", -34)
			MultiBot.doRepos("Beast", -34)
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Creator"]:Show()
		else
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Creator"]:Hide()
		end
	end

	local function MultiBotRestoreBeast(pEnabled)
		local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Beast"]
		MultiBotSetSavedToggle(tButton, pEnabled)
		MultiBot.frames["MultiBar"].frames["Left"].frames["Beast"]:Hide()
		if(pEnabled) then
			MultiBot.doRepos("Tanker", -34)
			MultiBot.doRepos("Attack", -34)
			MultiBot.doRepos("Mode", -34)
			MultiBot.doRepos("Stay", -34)
			MultiBot.doRepos("Follow", -34)
			MultiBot.doRepos("ExpandStay", -34)
			MultiBot.doRepos("ExpandFollow", -34)
			MultiBot.doRepos("Flee", -34)
			MultiBot.doRepos("Format", -34)
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Beast"]:Show()
		else
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Beast"]:Hide()
		end
	end

	local function MultiBotRestoreExpand(pEnabled)
		local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Expand"]
		MultiBotSetSavedToggle(tButton, pEnabled)
		if(pEnabled) then
			MultiBot.doRepos("Tanker", -34)
			MultiBot.doRepos("Attack", -34)
			MultiBot.doRepos("Mode", -34)
			MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandFollow"]:Show()
			MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandStay"]:Show()
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Follow"]:Hide()
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Stay"]:Hide()
		else
			MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandFollow"]:Hide()
			MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandStay"]:Hide()
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Follow"]:Show()
			MultiBot.frames["MultiBar"].frames["Left"].buttons["Stay"]:Show()
		end
	end

	local function MultiBotRestoreRTSC(pEnabled)
		local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["RTSC"]
		MultiBotSetSavedToggle(tButton, pEnabled)
		if(pEnabled) then
			MultiBot.frames["MultiBar"].frames["RTSC"]:Show()
		else
			MultiBot.frames["MultiBar"].frames["RTSC"]:Hide()
		end
	end

	local function MultiBotRestoreAttack(pName)
		local tParent = MultiBot.frames["MultiBar"].frames["Left"]
		local tFrame = tParent.frames["Attack"]
		local tButton = tParent.buttons["Attack"]
		local tAttack = tFrame.buttons[pName]
		local tActions = {
			["Attack"] = "do attack my target",
			["Ranged"] = "@ranged do attack my target",
			["Melee"] = "@melee do attack my target",
			["Healer"] = "@healer do attack my target",
			["Dps"] = "@dps do attack my target",
			["Tank"] = "@tank do attack my target",
		}
		if(tAttack == nil) then return end
		tButton.doLeft = function(pInnerButton)
			if(MultiBot.isTarget()) then MultiBot.ActionToGroup(tActions[pName]) end
		end
		tButton.setTexture(tAttack.texture)
		tFrame:Hide()
	end

	local function MultiBotRestoreFlee(pName)
		local tParent = MultiBot.frames["MultiBar"].frames["Left"]
		local tFrame = tParent.frames["Flee"]
		local tButton = tParent.buttons["Flee"]
		local tFlee = tFrame.buttons[pName]
		local tActions = {
			["Flee"] = "flee",
			["Ranged"] = "@ranged flee",
			["Melee"] = "@melee flee",
			["Healer"] = "@healer flee",
			["Dps"] = "@dps flee",
			["Tank"] = "@tank flee",
			["Target"] = "flee",
		}
		if(tFlee == nil) then return end
		tButton.doLeft = function(pInnerButton)
			MultiBot.ActionToGroup(tActions[pName])
		end
		tButton.setTexture(tFlee.texture)
		tFrame:Hide()
	end

	if(event == "PLAYER_LOGOUT") then
		local tX, tY = MultiBot.toPoint(MultiBot.frames["MultiBar"])
		MultiBotSave["MultiBarPoint"] = tX .. ", " .. tY
		
		local tX, tY = MultiBot.toPoint(MultiBot.inventory)
		MultiBotSave["InventoryPoint"] = tX .. ", " .. tY
		
		local tX, tY = MultiBot.toPoint(MultiBot.spellbook)
		MultiBotSave["SpellbookPoint"] = tX .. ", " .. tY
		
		local tX, tY = MultiBot.toPoint(MultiBot.itemus)
		MultiBotSave["ItemusPoint"] = tX .. ", " .. tY
		
		local tX, tY = MultiBot.toPoint(MultiBot.iconos)
		MultiBotSave["IconosPoint"] = tX .. ", " .. tY
		
		local tX, tY = MultiBot.toPoint(MultiBot.stats)
		MultiBotSave["StatsPoint"] = tX .. ", " .. tY
		
		local tX, tY = MultiBot.toPoint(MultiBot.reward)
		MultiBotSave["RewardPoint"] = tX .. ", " .. tY
		
		local tX, tY = MultiBot.toPoint(MultiBot.talent)
		MultiBotSave["TalentPoint"] = tX .. ", " .. tY
		
		local tPortal = MultiBot.frames["MultiBar"].frames["Masters"].frames["Portal"]
		MultiBotSave["MemoryGem1"] =  MultiBot.SavePortal(tPortal.buttons["Red"])
		MultiBotSave["MemoryGem2"] =  MultiBot.SavePortal(tPortal.buttons["Green"])
		MultiBotSave["MemoryGem3"] =  MultiBot.SavePortal(tPortal.buttons["Blue"])
		
		local tValue = MultiBot.doSplit(MultiBot.frames["MultiBar"].frames["Left"].buttons["Attack"].texture, "\\")[5]
		tValue = string.sub(tValue, 1, string.len(tValue) - 4)
		MultiBotSave["AttackButton"] = tValue
		
		local tValue = MultiBot.doSplit(MultiBot.frames["MultiBar"].frames["Left"].buttons["Flee"].texture, "\\")[5]
		tValue = string.sub(tValue, 1, string.len(tValue) - 4)
		MultiBotSave["FleeButton"] = tValue
		
		MultiBotSave["AutoRelease"] = MultiBot.IF(MultiBot.auto.release, "true", "false")
		MultiBotSave["NecroNet"] = MultiBot.IF(MultiBot.necronet.state, "true", "false")
		MultiBotSave["Reward"] = MultiBot.IF(MultiBot.reward.state, "true", "false")
		
		MultiBotSave["Masters"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Masters"].state, "true", "false")
		MultiBotSave["Creator"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Creator"].state, "true", "false")
		MultiBotSave["Beast"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Beast"].state, "true", "false")
		MultiBotSave["Expand"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Expand"].state, "true", "false")
		MultiBotSave["RTSC"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["RTSC"].state, "true", "false")
		
		return
	end
	
	-- ADDON:LOADED --
	
	if(event == "ADDON_LOADED" and (arg1 == "MultiBot" or arg1 == "MultiBotClassic")) then
		if(MultiBotSave["MultiBarPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["MultiBarPoint"], ", ")
			MultiBot.frames["MultiBar"].setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["InventoryPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["InventoryPoint"], ", ")
			MultiBot.inventory.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["SpellbookPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["SpellbookPoint"], ", ")
			MultiBot.spellbook.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["ItemusPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["ItemusPoint"], ", ")
			MultiBot.itemus.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["IconosPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["IconosPoint"], ", ")
			MultiBot.iconos.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["StatsPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["StatsPoint"], ", ")
			MultiBot.stats.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["RewardPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["RewardPoint"], ", ")
			MultiBot.reward.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["TalentPoint"] ~= nil) then
			local tPoint = MultiBot.doSplit(MultiBotSave["TalentPoint"], ", ")
			MultiBot.talent.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
		
		if(MultiBotSave["MemoryGem1"] ~= nil) then
			local tGem = MultiBot.frames["MultiBar"].frames["Masters"].frames["Portal"].buttons["Red"]
			MultiBot.LoadPortal(tGem, MultiBotSave["MemoryGem1"])
		end
		
		if(MultiBotSave["MemoryGem2"] ~= nil) then
			local tGem = MultiBot.frames["MultiBar"].frames["Masters"].frames["Portal"].buttons["Green"]
			MultiBot.LoadPortal(tGem, MultiBotSave["MemoryGem2"])
		end
		
		if(MultiBotSave["MemoryGem3"] ~= nil) then
			local tGem = MultiBot.frames["MultiBar"].frames["Masters"].frames["Portal"].buttons["Blue"]
			MultiBot.LoadPortal(tGem, MultiBotSave["MemoryGem3"])
		end
		
		if(MultiBotSave["AttackButton"] ~= nil) then
			local tMap = {
				["attack"] = "Attack",
				["attack_ranged"] = "Ranged",
				["attack_melee"] = "Melee",
				["attack_healer"] = "Healer",
				["attack_dps"] = "Dps",
				["attack_tank"] = "Tank",
			}
			MultiBotRestoreAttack(tMap[MultiBotSave["AttackButton"]])
		end
		
		if(MultiBotSave["FleeButton"] ~= nil) then
			local tMap = {
				["flee"] = "Flee",
				["flee_ranged"] = "Ranged",
				["flee_melee"] = "Melee",
				["flee_healer"] = "Healer",
				["flee_dps"] = "Dps",
				["flee_tank"] = "Tank",
				["flee_target"] = "Target",
			}
			MultiBotRestoreFlee(tMap[MultiBotSave["FleeButton"]])
		end
		
		if(MultiBotSave["AutoRelease"] ~= nil) then
			local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Release"]
			local tEnabled = MultiBotSave["AutoRelease"] == "true"
			MultiBotSetSavedToggle(tButton, tEnabled)
			MultiBot.auto.release = tEnabled
		end
		
		if(MultiBotSave["NecroNet"] ~= nil) then
			local tButton = MultiBot.frames["MultiBar"].frames["Masters"].buttons["NecroNet"]
			local tEnabled = MultiBotSave["NecroNet"] == "true"
			MultiBotSetSavedToggle(tButton, tEnabled)
			MultiBot.necronet.state = tEnabled
			if(tEnabled) then
				MultiBot.necronet.cont = 0
				MultiBot.necronet.area = 0
				MultiBot.necronet.zone = 0
			else
				for key, value in pairs(MultiBot.necronet.buttons) do value:Hide() end
			end
		end
		
		if(MultiBotSave["Reward"] ~= nil) then
			local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Reward"]
			local tEnabled = MultiBotSave["Reward"] == "true"
			MultiBotSetSavedToggle(tButton, tEnabled)
			MultiBot.reward.state = tEnabled
		end
		
		if(MultiBotSave["Masters"] ~= nil) then
			MultiBotRestoreMasters(MultiBotSave["Masters"] == "true")
		end
		
		if(MultiBotSave["Creator"] ~= nil) then
			MultiBotRestoreCreator(MultiBotSave["Creator"] == "true")
		end
		
		if(MultiBotSave["Beast"] ~= nil) then
			MultiBotRestoreBeast(MultiBotSave["Beast"] == "true")
		end
		
		if(MultiBotSave["Expand"] ~= nil) then
			MultiBotRestoreExpand(MultiBotSave["Expand"] == "true")
		end
		
		if(MultiBotSave["RTSC"] ~= nil) then
			MultiBotRestoreRTSC(MultiBotSave["RTSC"] == "true")
		end
		
		return
	end
	
	-- PLAYER:ENTERING --
	
	if(event == "PLAYER_ENTERING_WORLD") then
		MultiBotRefreshGroupRoster()
		return
	end

	if(event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED") then
		MultiBotRefreshGroupRoster()
		return
	end
	
	-- CHAT:SYSTEM --
	
	if(event == "CHAT_MSG_SYSTEM") then
		if(MultiBot.isInside(arg1, "Accountlevel", "account level", "niveau de compte", "等级")) then
			local tLevel = tonumber(MultiBot.doSplit(arg1, ": ")[2])
			if(tLevel ~= nil) then MultiBot.GM = tLevel > 1 end
			MultiBot.RaidPool("player")
		end
		
		if(MultiBot.isInside(arg1, "Possible strategies")) then
			local tStrategies = MultiBot.doSplit(arg1, ", ")
			SendChatMessage("=== STRATEGIES ===", "SAY")
			for i = 1, table.getn(tStrategies) do SendChatMessage(i .. " : " .. tStrategies[i], "SAY") end
			return
		end
		
		if(MultiBot.isInside(arg1, "Whisper any of")) then
			local tCommands = MultiBot.doSplit(arg1, ", ")
			SendChatMessage("=== WHISPER-COMMANDS ===", "SAY")
			for i = 1, table.getn(tCommands) do SendChatMessage(i .. " : " .. tCommands[i], "SAY") end
			return
		end
		
		if(MultiBot.auto.release == true) then
			if(MultiBot.isInside(arg1, "已经死亡")) then
				SendChatMessage("release", "WHISPER", nil, MultiBot.doReplace(arg1, "已经死亡。", ""))
				return
			end
			
			if(MultiBot.isInside(arg1, "ist tot", "has dies", "has died")) then
				SendChatMessage("release", "WHISPER", nil, MultiBot.doSplit(arg1, " ")[1])
				return
			end
		end
		
		if(string.sub(arg1, 1, 12) == "Bot roster: ") then
			local tLocClass, tClass, tLocRace, tRace, tSex, tName = GetPlayerInfoByGUID(UnitGUID("player"))
			tClass = MultiBot.toClass(tClass)
			
			local tPlayer = MultiBot.addSelf(tClass, tName).setDisable()
			tPlayer.class = tClass
			tPlayer.name = tName
			
			tPlayer.doLeft = function(pButton)
				SendChatMessage(".playerbot bot self", "SAY")
				MultiBot.OnOffSwitch(pButton)
			end
			
			-- PLAYERBOTS --
			
			local tTable = MultiBot.doSplit(string.sub(arg1, 13), ", ")
			
			for key, value in pairs(tTable) do
				if(value == "") then break end
				local tBot = MultiBot.doSplit(value, " ")
				local tName = string.sub(tBot[1], 2)
				local tClass = MultiBot.toClass(tBot[2])
				local tOnline = string.sub(tBot[1], 1, 1)
				
				local tPlayer = MultiBot.addPlayer(tClass, tName).setDisable()
				
				tPlayer.doRight = function(pButton)
					if(pButton.state == false) then return end
					SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
					MultiBot.CollapseUnitButton(pButton)
					pButton.setDisable()
				end
				
				tPlayer.doLeft = function(pButton)
					if(pButton.state) then
						MultiBot.ToggleUnitButtonFrame(pButton)
					else
						SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
						pButton.setEnable()
						MultiBot.SetUnitCollapsed(pButton.name, false)
					end
				end
			end
			
			-- MEMBERBOTS --
			
			for i = 1, 50 do
				local tName, tRank, tIndex, tLevel, tClass = GetGuildRosterInfo(i)
				
				-- Ensure that the Counter is not bigger than the Amount of Members in Guildlist
				if(tName ~= nil and tLevel ~= nil and tClass ~= nil and tName ~= UnitName("player")) then
					local tMember = MultiBot.addMember(tClass, tLevel, tName).setDisable()
					
					tMember.doRight = function(pButton)
						if(pButton.state == false) then return end
						SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
						MultiBot.CollapseUnitButton(pButton)
						pButton.setDisable()
					end
					
					tMember.doLeft = function(pButton)
						if(pButton.state) then
							MultiBot.ToggleUnitButtonFrame(pButton)
						else
							SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
							pButton.setEnable()
							MultiBot.SetUnitCollapsed(pButton.name, false)
						end
					end
				else
					break
				end
			end
			
			-- FRIENDBOTS --
			
			for i = 1, 50 do
				local tName, tLevel, tClass = GetFriendInfo(i)
				
				-- Ensure that the Counter is not bigger than the Amount of Members in Friendlist
				if(tName ~= nil and tLevel ~= nil and tClass ~= nil and tName ~= UnitName("player")) then
					local tFriend = MultiBot.addFriend(tClass, tLevel, tName).setDisable()
					
					tFriend.doRight = function(pButton)
						if(pButton.state == false) then return end
						SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
						MultiBot.CollapseUnitButton(pButton)
						pButton.setDisable()
					end
					
					tFriend.doLeft = function(pButton)
						if(pButton.state) then
							MultiBot.ToggleUnitButtonFrame(pButton)
						else
							SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
							pButton.setEnable()
							MultiBot.SetUnitCollapsed(pButton.name, false)
						end
					end
				else
					break
				end
			end
			
			-- REFRESH:RAID --
			
			if(GetNumRaidMembers() > 0) then
				MultiBotRefreshGroupRoster()
				return
			end
			
			-- REFRESH:GROUP --
			
			if(GetNumPartyMembers() > 0) then
				MultiBotRefreshGroupRoster()
				return
			end
			
			return
		end
		
		if(MultiBot.isInside(arg1, "player already logged in")) then
			local tName = string.sub(arg1, 6, string.find(arg1, " ", 6) - 1)
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			
			if(MultiBot.isMember(tName)) then
				tButton.waitFor = "CO"
				SendChatMessage(MultiBot.doReplace(MultiBot.info.combat, "NAME", tName), "SAY")
				SendChatMessage("co ?", "WHISPER", nil, tName)
				tButton.setEnable()

				local tMaster = MultiBot.frames["MultiBar"].buttons["Units"]
				if(tMaster.roster == "actives") then
					MultiBot.renderUnits(tMaster, false)
				end

				return
			end
			
			if(GetNumPartyMembers() == 4) then ConvertToRaid() end
			InviteUnit(tName)
			return
		end
		
		if(MultiBot.isInside(arg1, "remove: ")) then
			local tName = string.sub(arg1, 9, string.find(arg1, " ", 9) - 1)
			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].frames[tName]
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			
			if(MultiBot.isInside(arg1, "not your bot")) then
				SendChatMessage("leave", "WHISPER", nil, tName)
			end
			
			MultiBotRemoveActiveByName(tButton.name)
			MultiBot.CollapseUnitButton(tButton)
			tButton.setDisable()
			MultiBot.ClampActivePage()
			if(MultiBot.frames["MultiBar"].buttons["Units"].roster == "actives") then
				MultiBot.renderUnits(MultiBot.frames["MultiBar"].buttons["Units"], false)
			end
			--MultiBot.doRaid()
			return
		end
		
		if(arg1 == "Enable player botAI") then
			local tName = UnitName("player")
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			tButton.waitFor = "CO"
			SendChatMessage(MultiBot.doReplace(MultiBot.info.combat, "NAME", tName), "SAY")
			SendChatMessage("co ?", "WHISPER", nil, tName)
			tButton.setEnable()

			local tMaster = MultiBot.frames["MultiBar"].buttons["Units"]
			if(tMaster.roster == "actives") then
				MultiBot.renderUnits(tMaster, false)
			end

			return
		end

		if(arg1 == "Disable player botAI") then
			local tName = UnitName("player")
			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].frames[tName]
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			if(tFrame ~= nil) then tFrame:Hide() end
			MultiBot.CollapseUnitButton(tButton)
			tButton.setDisable()

			local tMaster = MultiBot.frames["MultiBar"].buttons["Units"]
			if(tMaster.roster == "actives") then
				MultiBot.renderUnits(tMaster, false)
			end

			return
		end
		
		if(MultiBot.isInside(arg1, "Zone:", "zone:")) then
			local tPlayer = MultiBot.player
			if(tPlayer.waitFor ~= "COORDS" or tPlayer.memory == nil) then return end
			
			local tLocation = MultiBot.doSplit(arg1, " ")
			local tZone = string.sub(tLocation[6], 2, string.len(tLocation[6]) - 1)
			local tMap = string.sub(tLocation[3], 2, string.len(tLocation[3]) - 1)
			local tTip = MultiBot.doReplace(MultiBot.doReplace(MultiBot.info.teleport, "MAP", tMap), "ZONE", tZone)
			
			tPlayer.memory.goMap = tLocation[2]
			tPlayer.memory.tip = MultiBot.doReplace(MultiBot.tips.game.memory, "ABOUT", tTip)
			return
		end
		
		if(MultiBot.isInside(arg1, "X:") and MultiBot.isInside(arg1, "Y:")) then
			local tPlayer = MultiBot.player
			if(tPlayer.waitFor ~= "COORDS" or tPlayer.memory == nil) then return end
			
			local tCoords = MultiBot.doSplit(arg1, " ")
			tPlayer.memory.goX = tCoords[2]
			tPlayer.memory.goY = tCoords[4]
			tPlayer.memory.goZ = tCoords[6]
			tPlayer.memory.setEnable()
			tPlayer.waitFor = ""
			return
		end
	end
	
	-- CHAT:WHISPER --
	
	if(event == "CHAT_MSG_WHISPER") then
		if(MultiBot.auto.release == true) then
			-- Graveyard not ready to talk Bot in the chinese Version --
			if(arg1 == "在墓地见我") then
				MultiBot.frames["MultiBar"].frames["Units"].buttons[arg2].waitFor = "你好"
				return
			end
			
			if(arg1 == "Meet me at the graveyard") then
				SendChatMessage("summon", "WHISPER", nil, arg2)
				return
			end
		end
		
		if(MultiBot.isInside(arg1, "StatsOfPlayer")) then
			local tUnit = MultiBot.toUnit(arg2)
			MultiBot.stats.frames[tUnit].setStats(arg2, UnitLevel(tUnit), arg1, true)
		end
		
		if(arg1 == "stats" and arg2 ~= UnitName("player")) then
			local tXP = math.floor(100.0 / UnitXPMax("player") * UnitXP("player"))
			local tMana = math.floor(100.0 / UnitManaMax("player") * UnitMana("player"))
			SendChatMessage("StatsOfPlayer " .. tXP .. " " .. tMana, "WHISPER", nil, arg2)
		end
		
		-- REQUIREMENT --
		
		local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[arg2]
		
		if(MultiBot.auto.release == true) then
			-- Graveyard ready to talk Bot in the chinese Version --
			if(tButton ~= nil and tButton.waitFor == "你好" and arg1 == "你好") then
				SendChatMessage("summon", "WHISPER", nil, arg2)
				tButton.waitFor = ""
				return
			end
		end
		
		if(MultiBot.isInside(arg1, "Hello", "你好") and tButton == nil) then
			local tUnit = MultiBot.toUnit(arg2)
			if(tUnit == nil) then return end
			local tLocClass, tClass = UnitClass(tUnit)
			if(tClass == nil) then return end
			local tLevel = UnitLevel(tUnit)
			
			tButton = MultiBot.addActive(tClass, tLevel, arg2).setDisable()
			MultiBotSetupActiveButton(tButton)
		elseif(tButton == nil) then return end
		
		if(MultiBot.isInside(arg1, "Hello", "你好") and tButton.class == "Unknown" and tButton.roster == "friends") then
			local tName = ""
			local tLevel = ""
			local tClass = ""
			
			for i = 1, 50 do
				tName, tLevel, tClass = GetFriendInfo(i)
				if(tName == arg2) then break end
				if(tName == nil) then break end
			end
			
			local tClass = MultiBot.toClass(tClass)
			local tTable = MultiBot.index.classes[tButton.roster][tButton.class]
			local tIndex = 0
			
			for i = 1, table.getn(tTable) do
				if(tTable[i] == arg2) then 
					tIndex = i
					break
				end
			end
			
			if(tIndex > 0) then
				if(MultiBot.index.classes[tButton.roster][tClass] == nil) then MultiBot.index.classes[tButton.roster][tClass] = {} end
				table.remove(MultiBot.index.classes[tButton.roster][tButton.class], tIndex)
				table.insert(MultiBot.index.classes[tButton.roster][tClass], tName)
			end
			
			tButton.setTexture("Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tClass) .. ".blp")
			tButton.tip = MultiBot.toTip(tClass, tLevel, tName)
			tButton.class = tClass
		end
		
		if(MultiBot.isInside(arg1, "Hello", "你好")) then
			tButton.waitFor = "CO"
			SendChatMessage(MultiBot.doReplace(MultiBot.info.combat, "NAME", arg2), "SAY")
			SendChatMessage("co ?", "WHISPER", nil, arg2)

			local tMaster = MultiBot.frames["MultiBar"].buttons["Units"]
			if(tMaster.roster == "actives") then
				MultiBot.renderUnits(tMaster, false)
			end

			return
		end

		if(MultiBot.isInside(arg1, "Goodbye", "再见")) then
			local tMaster = MultiBot.frames["MultiBar"].buttons["Units"]
			if(tMaster.roster == "actives") then
				MultiBot.renderUnits(tMaster, false)
			end

			return
		end
		
		if(MultiBot.isInside(arg1, "reset to default") and tButton.waitFor == "CO") then
			SendChatMessage("co ,?", "WHISPER", nil, arg2)
			return
		end
		
		if(MultiBot.isInside(arg1, "reset to default") and tButton.waitFor == "NC") then
			SendChatMessage("nc ,?", "WHISPER", nil, arg2)
			return
		end
		
		if(tButton.waitFor == "DETAIL" and MultiBot.isInside(arg1, "playing with")) then
			tButton.waitFor = ""
			MultiBot.RaidPool(arg2, arg1)
			return
		end
		
		if(tButton.waitFor == "IGNORE" and MultiBot.isInside(arg1, "Ignored ")) then
			if(MultiBot.spells[arg2] == nil) then MultiBot.spells[arg2] = {} end
			tButton.waitFor = "DETAIL"
			
			local tSpells = {}
			local tIgnores = MultiBot.doSplit(arg1, ": ")[2]
			
			if(tIgnores ~= nil) then
				tSpells = MultiBot.doSplit(tIgnores, ", ")
				
				for k,v in pairs(tSpells) do
					local tSpell = MultiBot.doSplit(v, "|")[3]
					if(tSpell ~= nil) then MultiBot.spells[arg2][MultiBot.doSplit(tSpell, ":")[2]] = false end
				end
			end
			
			SendChatMessage("who", "WHISPER", nil, arg2)
			return
		end
		
		if(tButton.waitFor == "NC" and MultiBot.isInside(arg1, "Strategies: ")) then
			tButton.waitFor = "IGNORE"
			tButton.normal = string.sub(arg1, 13)
			
			tFrame = MultiBot.frames["MultiBar"].frames["Units"].addFrame(arg2, tButton.x - tButton.size - 32, tButton.y + 2)
			tFrame.class = tButton.class
			tFrame.name = tButton.name
			
			MultiBot["add" .. tButton.class](tFrame, tButton.combat, tButton.normal)
			MultiBot.addEvery(tFrame, tButton.combat, tButton.normal)
			
			MultiBotSyncActiveClassIndex(tButton)
			
			tButton.setEnable()
			MultiBot.ApplyUnitCollapsed(tButton.name)

			local tMaster = MultiBot.frames["MultiBar"].buttons["Units"]
			if(tMaster.roster == "actives") then
				MultiBot.renderUnits(tMaster, false)
			end

			SendChatMessage("ss ?", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "CO" and MultiBot.isInside(arg1, "Strategies: ")) then
			tButton.waitFor = "NC"
			tButton.combat = string.sub(arg1, 13)
			SendChatMessage(MultiBot.doReplace(MultiBot.info.normal, "NAME", arg2), "SAY")
			SendChatMessage("nc ?", "WHISPER", nil, arg2)
			return
		end
		
		if(tButton.waitFor ~= "ITEM" and tButton.waitFor ~= "SPELL" and MultiBot.auto.stats and MultiBot.isInside(arg1, "Bag")) then
			local tUnit = MultiBot.toUnit(arg2)
			if(MultiBot.stats.frames[tUnit] == nil) then MultiBot.addStats(MultiBot.stats, "party1", 0, 0, 32, 192, 96) end
			MultiBot.stats.frames[tUnit].setStats(arg2, UnitLevel(tUnit), arg1)
			return
		end
		
		-- Inventory --
		
		if(tButton.waitFor == "INVENTORY" and MultiBot.isInside(arg1, "Inventory", "背包")) then
			local tItems = MultiBot.inventory.frames["Items"]
			for key, value in pairs(tItems.buttons) do value:Hide() end
			table.wipe(tItems.buttons)
			MultiBot.inventory.setText("Title", MultiBot.doReplace(MultiBot.info.inventory, "NAME", arg2))
			MultiBot.inventory.name = arg2
			tItems.index = 0
			tButton.waitFor = "ITEM"
			SendChatMessage("stats", "WHISPER", nil, arg2)
			return
		end
		
		if(tButton.waitFor == "ITEM" and (MultiBot.beInside(arg1, "Bag,", "Dur") or MultiBot.beInside(arg1, "背包", "耐久度"))) then
			MultiBot.inventory:Show()
			tButton.waitFor = ""
			InspectUnit(arg2)
			return
		end
		
		if(tButton.waitFor == "ITEM") then
			if(string.sub(arg1, 1, 3) == "---") then return end
			MultiBot.addItem(MultiBot.inventory.frames["Items"], arg1)
			return
		end
		
		-- Spellbook --
		
		if(tButton.waitFor == "SPELLBOOK" and MultiBot.isInside(arg1, "Spells")) then
			local tOverlay = MultiBot.spellbook.frames["Overlay"]
			local tSpellbook = MultiBot.spellbook
			table.wipe(tSpellbook.spells)
			tSpellbook.frames["Overlay"].setText("Title", MultiBot.doReplace(MultiBot.info.spellbook, "NAME", arg2))
			tSpellbook.name = arg2
			tSpellbook.index = 0
			tSpellbook.from = 1
			tSpellbook.to = 16
			tButton.waitFor = "SPELL"
			SendChatMessage("stats", "WHISPER", nil, arg2)
			return
		end
		
		if(tButton.waitFor == "SPELL" and MultiBot.isInside(arg1, "Bag,", "Dur", "XP", "背包", "耐久度", "经验值")) then
			local tOverlay = MultiBot.spellbook.frames["Overlay"]
			local tSpellbook = MultiBot.spellbook
			tSpellbook.now = 1
			tSpellbook.max = math.ceil(tSpellbook.index / 16)
			tOverlay.setText("Pages", "|cffffffff" .. tSpellbook.now .. "/" .. tSpellbook.max .. "|r")
			if(tSpellbook.now == tSpellbook.max) then tOverlay.buttons[">"].doHide() else tOverlay.buttons[">"].doShow() end
			tOverlay.buttons["<"].doHide()
			tSpellbook:Show()
			tButton.waitFor = ""
			InspectUnit(arg2)
			return
		end
		
		if(tButton.waitFor == "SPELL") then
			MultiBot.addSpell(arg1, arg2)
			return
		end
		
		-- EQUIPPING --
		
		if(MultiBot.inventory:IsVisible()) then
			if(MultiBot.isInside(arg1, "装备", "使用", "吃", "喝", "盛宴", "摧毁")) then
				tButton.waitFor = "INVENTORY"
				SendChatMessage("items", "WHISPER", nil, tButton.name)
				return
			end
			
			if(MultiBot.isInside(string.lower(arg1), "equipping", "using", "eating", "drinking", "feasting", "destroyed")) then
				tButton.waitFor = "INVENTORY"
				SendChatMessage("items", "WHISPER", nil, tButton.name)
				return
			end
			
			if(MultiBot.inventory:IsVisible() and MultiBot.isInside(string.lower(arg1), "opened")) then
				tButton.waitFor = "LOOT"
				return
			end
		end
		
		return
	end
	
	if(event == "CHAT_MSG_LOOT") then
		if(MultiBot.inventory:IsVisible()) then
			local tButton = nil
			
			if(MultiBot.isInside(arg1, "获得了物品")) then
				local tName = MultiBot.doReplace(MultiBot.doSplit(arg1, ":")[1], "获得了物品", "")
				tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			end
			
			if(MultiBot.isInside(string.lower(arg1), "beute", "receives")) then
				local tName = MultiBot.doSplit(arg1, " ")[1]
				tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			end
			
			if(tButton ~= nil and tButton.waitFor == "LOOT" and tButton ~= nil) then
				tButton.waitFor = "INVENTORY"
				SendChatMessage("items", "WHISPER", nil, tButton.name)
				return
			end
		end
		
		return
	end
	
	if(event == "TRADE_CLOSED") then
		if(MultiBot.inventory:IsVisible()) then
			MultiBot.frames["MultiBar"].frames["Units"].buttons[MultiBot.inventory.name].waitFor = "INVENTORY"
			SendChatMessage("items", "WHISPER", nil, MultiBot.inventory.name)
			return
		end
		
		return
	end
		
	-- QUEST:COMPLETE --
	
	if(event == "QUEST_COMPLETE") then
		if(MultiBot.reward.state) then
			MultiBot.setRewards()
			return
		end
		
		return
	end
	
	-- QUEST:CHANGED --
	
	if(event == "QUEST_LOG_UPDATE") then
		local tButton = MultiBot.frames["MultiBar"].frames["Right"].buttons["Quests"]
		tButton.doRight(tButton)
		return
	end
	
	-- WORLD:MAP --
	
	if(event == "WORLD_MAP_UPDATE" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA") then
		if(MultiBot.necronet == nil or MultiBot.necronet.state == false) then return end
		if(GetCurrentMapContinent == nil or GetCurrentMapAreaID == nil) then return end
		
		local tCont = GetCurrentMapContinent()
		local tArea = GetCurrentMapAreaID()
		
		if(MultiBot.necronet.cont ~= tCont or MultiBot.necronet.area ~= tArea) then
			for key, value in pairs(MultiBot.necronet.buttons) do value:Hide() end
			
			MultiBot.necronet.cont = tCont
			MultiBot.necronet.area = tArea
			
			local tTable = MultiBot.necronet.index[tCont]
			if(tTable ~= nil) then tTable = tTable[tArea] end
			if(tTable ~= nil) then for key, value in pairs(tTable) do value:Show() end end
		end
		
		return
	end
end)

SLASH_MULTIBOT1 = "/multibot"
SLASH_MULTIBOT2 = "/mbot"
SLASH_MULTIBOT3 = "/mb"

SlashCmdList["MULTIBOT"] = function()
	if(MultiBot.state) then
		for key, value in pairs(MultiBot.frames) do value:Hide() end
		MultiBot.state = false
	else
		for key, value in pairs(MultiBot.frames) do value:Show() end
		MultiBot.state = true
	end
end
