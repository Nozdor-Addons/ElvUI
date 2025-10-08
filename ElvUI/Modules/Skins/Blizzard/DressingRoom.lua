local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
--WoW API / Variables

S:AddCallback("Skin_DressingRoom", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.dressingroom then return end

	DressUpFrame:StripTextures()
	DressUpFrame:CreateBackdrop("Transparent")
	DressUpFrame:Size(460, 645)
	DressUpFrame.backdrop:Point("TOPLEFT", 11, 0)
	DressUpFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetUIPanelWindowInfo(DressUpFrame, "width")
	S:SetBackdropHitRect(DressUpFrame)

	DressUpFramePortrait:Kill()
	DressUpFrameInset:Kill()

	-- SetDressUpBackground()
	-- DressUpBackgroundTopLeft:SetDesaturated(true)
	-- DressUpBackgroundTopRight:SetDesaturated(true)
	-- DressUpBackgroundBotLeft:SetDesaturated(true)
	-- DressUpBackgroundBotRight:SetDesaturated(true)

	MaximizeMinimizeFrame:StripTextures(true)
	S:HandleMaxMinFrame(DressUpFrame.MaxMinButtonFrame)

	S:HandleCloseButton(DressUpFrameCloseButton, DressUpFrame.backdrop)

	S:HandleRotateButton(DressUpModelRotateLeftButton)
	S:HandleRotateButton(DressUpModelRotateRightButton)

	S:HandleButton(DressUpFrameCancelButton)
	S:HandleButton(DressUpFrameResetButton)

	DressUpFrameCancelButton:ClearAllPoints()

	DressUpModel:CreateBackdrop("Default")
	DressUpModel.backdrop:SetOutside(DressUpModel)

	if DressUpModel.backdrop.SetBackdropColor then
    	DressUpModel.backdrop:SetBackdropColor(0, 0, 0, 0)
	end

	local bg = DressUpModel:CreateTexture(nil, "BACKGROUND")
	bg:SetPoint("TOPLEFT",     DressUpModel.backdrop, "TOPLEFT",     2, -2)
	bg:SetPoint("BOTTOMRIGHT", DressUpModel.backdrop, "BOTTOMRIGHT", -2,  2)
	bg:SetTexture([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Parchment]])
	bg:SetTexCoord(0, 1, 0, 1)
	bg:SetDrawLayer("BACKGROUND", 1)  -- выше фонового слоя бекдропа
	bg:Show()

	-- DressUpFrameDescriptionText:Point("CENTER", DressUpFrameTitleText, "BOTTOM", 10, -18)

	-- DressUpModelRotateLeftButton:Point("TOPLEFT", DressUpFrame, 29, -76)
	-- DressUpModelRotateRightButton:Point("TOPLEFT", DressUpModelRotateLeftButton, "TOPRIGHT", 3, 0)

	DressUpModel:Size(399, 480)
	DressUpModel:ClearAllPoints()
	DressUpModel:Point("TOPLEFT", 20, -67)

	-- DressUpBackgroundTopLeft:Point("TOPLEFT", 23, -67)

	DressUpFrameCancelButton:Point("BOTTOMRIGHT", DressUpFrame, "BOTTOMRIGHT", -41.5, 77)
	DressUpFrameResetButton:Point("RIGHT", DressUpFrameCancelButton, "LEFT", -3, 0)
end)
local BASE = { W = 460, H = 645 }

DressUpFrame:SetResizable(false)
DressUpFrame:HookScript("OnSizeChanged", function(self)
    self:SetSize(BASE.W, BASE.H)
end)
