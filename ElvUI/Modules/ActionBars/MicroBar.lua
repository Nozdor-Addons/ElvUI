-- ElvUI MicroBar (robust replacement v6: textures cropped, no squish, stable layout)
local E, L, V, P, G = unpack(select(2, ...))
local AB = E:GetModule("ActionBars")

local _G = _G
local CreateFrame = CreateFrame

-- Respect user's explicit list if present, else discover existing buttons
local function GetMicroButtonsList()
	if type(MICRO_BUTTONS) == "table" and #MICRO_BUTTONS > 0 then
		return MICRO_BUTTONS
	end
	local candidates = {
		"CharacterMicroButton","SpellbookMicroButton","TalentMicroButton",
		"AchievementMicroButton","QuestLogMicroButton","SocialsMicroButton",
		"PVPMicroButton","LFDMicroButton","HelpMicroButton","MainMenuMicroButton",
		"GuildMicroButton","QuestLogMicroButton2","WorldMapMicroButton",
		"CollectionsMicroButton","EncounterJournalMicroButton","StoreMicroButton",
	}
	local t = {}
	for i = 1, #candidates do
		local name = candidates[i]
		if _G[name] then t[#t+1] = name end
	end
	return t
end

local function getDB(self)
	local db = (self and self.db and self.db.microbar) or {}
	db.buttonSize = db.buttonSize or db.buttonsize or 20 -- desired width per button
	db.buttonSpacing = db.buttonSpacing or db.buttonspacing or 2
	db.buttonsPerRow = db.buttonsPerRow or db.buttonsperrow or 10
	db.alpha = (db.alpha ~= nil) and db.alpha or 1
	db.scale = db.scale or 1 -- entire bar scale
	return db
end

-- crop textures like ElvUI did for 3.3.5 micro buttons (icon is in lower half of atlas)
local function CropTex(tex, backdrop)
	if not tex then return end
	if tex.SetTexCoord then
		tex:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	end
	tex:ClearAllPoints()
	if backdrop and backdrop.GetObjectType and backdrop:GetObjectType() then
		tex:SetAllPoints(backdrop)
	else
		tex:SetAllPoints()
	end
end

local function HookButtonTextures(button)
	if button._elv_hooked_tex then return end
	button._elv_hooked_tex = true
	local function reskin()
		CropTex(button.GetNormalTexture and button:GetNormalTexture(), button.ElvBackdrop)
		CropTex(button.GetPushedTexture and button:GetPushedTexture(), button.ElvBackdrop)
		CropTex(button.GetDisabledTexture and button:GetDisabledTexture(), button.ElvBackdrop)
		local hl = button.GetHighlightTexture and button:GetHighlightTexture()
		CropTex(hl, button.ElvBackdrop)
		if hl and hl.SetAlpha then hl:SetAlpha(0.25) end
	end
	if hooksecurefunc then
		hooksecurefunc(button, "SetNormalTexture", reskin)
		hooksecurefunc(button, "SetPushedTexture", reskin)
		hooksecurefunc(button, "SetDisabledTexture", reskin)
		hooksecurefunc(button, "SetHighlightTexture", reskin)
	end
	reskin()
end

function AB:HandleMicroButton(button)
	if not button then return end

	-- cache original size for proper aspect scaling
	if not button._elv_baseW or not button._elv_baseH then
		local bw, bh = button:GetSize()
		button._elv_baseW = bw or 28
		button._elv_baseH = bh or 58
	end

	-- backdrop
	if not button.ElvBackdrop then
		local f = CreateFrame("Frame", nil, button)
		f:SetFrameLevel(button:GetFrameLevel() - 1)
		if f.SetTemplate then f:SetTemplate("Default", true) end
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
		f:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
		button.ElvBackdrop = f
	end

	-- ensure textures look right and stay cropped
	HookButtonTextures(button)

	-- don't force width/height; scale preserves aspect
	button:ClearAllPoints()
	button:Show()
end

local function HookIfExists(name, fn)
	local f = _G[name]
	if type(f) == "function" then
		if hooksecurefunc then hooksecurefunc(name, fn) end
		return true
	end
end

function AB:UpdateMicroButtonsParent()
	if not ElvUI_MicroBar then return end
	local list = GetMicroButtonsList()
	for i = 1, #list do
		local b = _G[list[i]]
		if b and b.SetParent then b:SetParent(ElvUI_MicroBar) end
	end
end

function AB:UpdateMicroBarVisibility()
	if not ElvUI_MicroBar then return end
	local db = getDB(self)

	if db.enabled == false then
		ElvUI_MicroBar:Hide()
		return
	end

	ElvUI_MicroBar:Show()

	if db.mouseover and not ElvUI_MicroBar:IsMouseOver() then
		ElvUI_MicroBar:SetAlpha(0)
	else
		ElvUI_MicroBar:SetAlpha(db.alpha)
	end
end

function AB:UpdateMicroPositionDimensions()
	if not ElvUI_MicroBar then return end
	local db = getDB(self)
	local list = GetMicroButtonsList()

	local bpr = db.buttonsPerRow or 10
	local spacingInner = db.buttonSpacing or 2

	local offset = E:Scale(E.PixelMode and 1 or 3)
	local spacing = E:Scale(offset + spacingInner)

	local rows = {}
	local row = 1; rows[1] = {width=0, maxH=0}
	local col = 0
	local prev = ElvUI_MicroBar

	local maxWidth = 0

	for i = 1, #list do
		local button = _G[list[i]]
		if button then
			-- aspect-preserving scaling from desired width
			local baseW = button._elv_baseW or (button.GetWidth and button:GetWidth()) or 28
			local baseH = button._elv_baseH or (button.GetHeight and button:GetHeight()) or 58
			local targetW = (db.buttonSize and db.buttonSize > 0) and db.buttonSize or baseW
			local scale = targetW / baseW
			button:SetScale(scale)

			local bw, bh = baseW * scale, baseH * scale

			-- positioning
			button:ClearAllPoints()
			if prev == ElvUI_MicroBar then
				button:Point("TOPLEFT", prev, "TOPLEFT", offset, -offset)
				col = 0
			elseif col >= (bpr - 1) then
				col = 0
				row = row + 1
				local upIdx = i - bpr
				local upBtn = (upIdx >= 1) and _G[list[upIdx]] or nil
				if upBtn then
					button:Point("TOP", upBtn, "BOTTOM", 0, -spacing)
				else
					-- fallback if previous row not ready
					local prevRow = rows[row-1]
					local yoff = prevRow and (prevRow.maxH + spacing) or spacing
					button:Point("TOPLEFT", ElvUI_MicroBar, "TOPLEFT", offset, -offset - yoff)
				end
			else
				col = col + 1
				button:Point("LEFT", prev, "RIGHT", spacing, 0)
			end
			prev = button

			-- per-row width/height tracking
			local r = rows[row] or {width=0, maxH=0}
			if r.width == 0 then r.width = bw else r.width = r.width + spacing + bw end
			if bh > r.maxH then r.maxH = bh end
			rows[row] = r
			if r.width > maxWidth then maxWidth = r.width end
		end
	end

	if not ElvUI_MicroBar:GetPoint() then
		ElvUI_MicroBar:Point("TOPLEFT", E.UIParent, "TOPLEFT", E:Scale(4), -E:Scale(4))
	end

	-- final bar size
	local totalHeight = 0
	for _, r in ipairs(rows) do
		if totalHeight == 0 then totalHeight = r.maxH else totalHeight = totalHeight + spacing + r.maxH end
	end
	local finalW = offset * 2 + maxWidth
	local finalH = offset * 2 + totalHeight

	ElvUI_MicroBar:Size(finalW, finalH)
	ElvUI_MicroBar:SetScale((db.scale and db.scale > 0) and db.scale or 1)

	-- visibility & mover
	self:UpdateMicroBarVisibility()
	if ElvUI_MicroBar.mover then
		if db.enabled == false then E:DisableMover(ElvUI_MicroBar.mover:GetName()) else E:EnableMover(ElvUI_MicroBar.mover:GetName()) end
	end
end

function AB:SetupMicroBar()
	-- ensure base buttons exist
	if not _G["CharacterMicroButton"] or not _G["MainMenuMicroButton"] then
		if self.RegisterEvent then self:RegisterEvent("PLAYER_ENTERING_WORLD", "SetupMicroBar") end
		return
	end
	if self.UnregisterEvent then self:UnregisterEvent("PLAYER_ENTERING_WORLD") end

	if not ElvUI_MicroBar then
		ElvUI_MicroBar = CreateFrame("Frame", "ElvUI_MicroBar", E.UIParent)
		ElvUI_MicroBar:SetFrameStrata("LOW")
		if ElvUI_MicroBar.SetTemplate then ElvUI_MicroBar:SetTemplate("Default", true) end
	end

	-- parent & skin buttons
	local list = GetMicroButtonsList()
	for i = 1, #list do
		local btn = _G[list[i]]
		if btn then
			self:HandleMicroButton(btn)
			btn:SetParent(ElvUI_MicroBar)
		end
	end

	-- initial layout
	self:UpdateMicroPositionDimensions()

	-- create mover AFTER size & anchor exist
	if not ElvUI_MicroBar.mover and E.CreateMover then
		E:CreateMover(ElvUI_MicroBar, "ElvAB_MicroBar", L["Micro Bar"], nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbar,microbar")
	end

	-- keep Blizzard from "stealing" buttons: hook if functions exist
	local function reapply()
		AB:UpdateMicroButtonsParent()
		AB:UpdateMicroPositionDimensions()
	end
	HookIfExists("MoveMicroButtons", reapply)
	HookIfExists("VehicleMenuBar_MoveMicroButtons", reapply)
	HookIfExists("UpdateMicroButtons", reapply)

	-- one-time delayed passes to catch late Blizzard relayouts
	if E and E.Delay then
		E:Delay(0.05, reapply)
		E:Delay(0.5, reapply)
	end

	-- also reapply whenever bar is shown
	if not ElvUI_MicroBar._elv_hooked_show then
		ElvUI_MicroBar._elv_hooked_show = true
		ElvUI_MicroBar:HookScript("OnShow", reapply)
	end
end
