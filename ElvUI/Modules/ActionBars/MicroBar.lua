local E, L, V, P, G = unpack(select(2, ...))
local AB = E:GetModule("ActionBars")

local _G = _G
local unpack = unpack
local gsub, match = string.gsub, string.match
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"PVPMicroButton",
	"LFDMicroButton",
	"EncounterJournalMicroButton",
	"StoreMicroButton",
	"MainMenuMicroButton"
}

local function onEnter(button)
	if AB.db.microbar.mouseover then
		E:UIFrameFadeIn(ElvUI_MicroBar, 0.2, ElvUI_MicroBar:GetAlpha(), AB.db.microbar.alpha)
	end
	if button and button ~= ElvUI_MicroBar and button.backdrop then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	end
end

local function onLeave(button)
	if AB.db.microbar.mouseover then
		E:UIFrameFadeOut(ElvUI_MicroBar, 0.2, ElvUI_MicroBar:GetAlpha(), 0)
	end
	if button and button ~= ElvUI_MicroBar and button.backdrop then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

function AB:HandleMicroButton(button)
	if not button then return end
	local pushed = button:GetPushedTexture()
	local normal = button:GetNormalTexture()
	local disabled = button:GetDisabledTexture()

	if not button._elv_baseW or not button._elv_baseH then
		local bw, bh = button:GetSize()
		button._elv_baseW = bw or 28
		button._elv_baseH = bh or 58
	end

	local f = CreateFrame("Frame", nil, button)
	f:SetFrameLevel(button:GetFrameLevel() - 1)
	f:SetTemplate("Default", true)
	f:SetOutside(button)
	button.backdrop = f

	button:SetParent(ElvUI_MicroBar)
	button:GetHighlightTexture():Kill()
	button:HookScript("OnEnter", onEnter)
	button:HookScript("OnLeave", onLeave)
	button:SetHitRectInsets(0, 0, 0, 0)
	button:Show()

	pushed:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	pushed:SetInside(f)

	normal:SetTexCoord(0.17, 0.87, 0.5, 0.908)
	normal:SetInside(f)

	if disabled then
		disabled:SetTexCoord(0.17, 0.87, 0.5, 0.908)
		disabled:SetInside(f)
	end
end

function AB:UpdateMicroButtonsParent()
	if InCombatLockdown() then
		AB.NeedsUpdateMicroButtonsParent = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	for i = 1, #MICRO_BUTTONS do
		local b = _G[MICRO_BUTTONS[i]]
		if b and b.SetParent then
			b:SetParent(ElvUI_MicroBar)
			b:Show()
		end
	end

	AB:UpdateMicroPositionDimensions()
end

function AB:UpdateMicroBarVisibility()
	if InCombatLockdown() then
		AB.NeedsUpdateMicroBarVisibility = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	local visibility = self.db.microbar.visibility
	if visibility and match(visibility, "[\n\r]") then
		visibility = gsub(visibility, "[\n\r]", "")
	end

	RegisterStateDriver(ElvUI_MicroBar.visibility, "visibility", (self.db.microbar.enabled and visibility) or "hide")
end

function AB:UpdateMicroPositionDimensions()
	if not ElvUI_MicroBar then return end

	local numRows = 1
	local prevButton = ElvUI_MicroBar
	local offset = E:Scale(E.PixelMode and 1 or 3)
	local spacing = E:Scale(offset + self.db.microbar.buttonSpacing)

	for i = 1, #MICRO_BUTTONS do
		local button = _G[MICRO_BUTTONS[i]]
		if button then
			local lastColumnButton = i - self.db.microbar.buttonsPerRow
			if lastColumnButton and lastColumnButton >= 1 then
				lastColumnButton = _G[MICRO_BUTTONS[lastColumnButton]]
			else
				lastColumnButton = nil
			end

			local _bw = button._elv_baseW or button:GetWidth()
			local _bh = button._elv_baseH or button:GetHeight()
			local _w = self.db.microbar.buttonSize or _bw
			local _h = (_bw > 0 and _bh > 0) and (_w * (_bh / _bw)) or (self.db.microbar.buttonSize * 1.4)
			button:Size(_w, _h)
			button:ClearAllPoints()

			if prevButton == ElvUI_MicroBar then
				button:Point("TOPLEFT", prevButton, "TOPLEFT", offset, -offset)
			elseif (i - 1) % self.db.microbar.buttonsPerRow == 0 then
				button:Point("TOP", lastColumnButton, "BOTTOM", 0, -spacing)
				numRows = numRows + 1
			else
				button:Point("LEFT", prevButton, "RIGHT", spacing, 0)
			end

			prevButton = button
		end
	end

	if AB.db.microbar.mouseover and not ElvUI_MicroBar:IsMouseOver() then
		ElvUI_MicroBar:SetAlpha(0)
	else
		ElvUI_MicroBar:SetAlpha(self.db.microbar.alpha)
	end

	AB.MicroWidth = (((CharacterMicroButton:GetWidth() + spacing) * self.db.microbar.buttonsPerRow) - spacing) + (offset * 2)
	AB.MicroHeight = (((CharacterMicroButton:GetHeight() + spacing) * numRows) - spacing) + (offset * 2)
	ElvUI_MicroBar:Size(AB.MicroWidth, AB.MicroHeight)

	if ElvUI_MicroBar.mover then
		if self.db.microbar.enabled then
			E:EnableMover(ElvUI_MicroBar.mover:GetName())
		else
			E:DisableMover(ElvUI_MicroBar.mover:GetName())
		end
	end

	self:UpdateMicroBarVisibility()
end

local function microEvents(_, event, unit)
	if event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
		if unit ~= "player" then return end
	end
	if InCombatLockdown() then
		AB.NeedsUpdateMicroButtonsParent = true
		AB:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	AB:UpdateMicroButtonsParent()
end

function AB:SetupMicroBar()
	local microBar = CreateFrame("Frame", "ElvUI_MicroBar", E.UIParent)
	microBar:Point("TOPLEFT", E.UIParent, "TOPLEFT", 4, -48)
	microBar:SetFrameStrata("LOW")
	microBar:EnableMouse(true)
	microBar:SetScript("OnEnter", onEnter)
	microBar:SetScript("OnLeave", onLeave)

	microBar.visibility = CreateFrame("Frame", nil, E.UIParent, "SecureHandlerStateTemplate")
	microBar.visibility:SetScript("OnShow", function() microBar:Show() end)
	microBar.visibility:SetScript("OnHide", function() microBar:Hide() end)

	for i = 1, #MICRO_BUTTONS do
		local btn = _G[MICRO_BUTTONS[i]]
		if btn then
			self:HandleMicroButton(btn)
			btn:SetParent(ElvUI_MicroBar)
		end
	end

	MicroButtonPortrait:SetAllPoints()
	PVPMicroButtonTexture:SetAllPoints()
	PVPMicroButtonTexture:SetTexture([[Interface\AddOns\ElvUI\Media\Textures\PVP-Icons]])

	if E.myfaction == "Alliance" then
		PVPMicroButtonTexture:SetTexCoord(0.545, 0.935, 0.070, 0.940)
	else
		PVPMicroButtonTexture:SetTexCoord(0.100, 0.475, 0.070, 0.940)
	end

	self:SecureHook("VehicleMenuBar_MoveMicroButtons", "UpdateMicroButtonsParent")
	if _G.UpdateMicroButtons then self:SecureHook("UpdateMicroButtons", "UpdateMicroButtonsParent") end
	if _G.MoveMicroButtons then self:SecureHook("MoveMicroButtons", "UpdateMicroButtonsParent") end
	if _G.UIParent_ManageFramePositions then self:SecureHook("UIParent_ManageFramePositions", "UpdateMicroButtonsParent") end

	local ev = CreateFrame("Frame", nil, microBar)
	ev:RegisterEvent("PLAYER_ENTERING_WORLD")
	ev:RegisterEvent("UNIT_ENTERED_VEHICLE")
	ev:RegisterEvent("UNIT_EXITED_VEHICLE")
	ev:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	ev:RegisterEvent("PLAYER_CONTROL_GAINED")
	ev:RegisterEvent("PLAYER_CONTROL_LOST")
	ev:SetScript("OnEvent", microEvents)

	self:UpdateMicroPositionDimensions()
	MainMenuBarPerformanceBar:Kill()

	E:CreateMover(microBar, "MicrobarMover", L["Micro Bar"], nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbar,microbar")

	self:UpdateMicroButtonsParent()
end
