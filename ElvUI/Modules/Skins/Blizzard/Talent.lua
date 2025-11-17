local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables

S:AddCallbackForAddon("Blizzard_TalentUI", "Skin_Blizzard_TalentUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	PlayerTalentFrame:StripTextures(true)
	PlayerTalentFrame:CreateBackdrop("Transparent")
	PlayerTalentFrame.backdrop:Point("TOPLEFT", 11, -12)
	PlayerTalentFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetBackdropHitRect(PlayerTalentFrame)

	do
		local offset

		local talentGroups = GetNumTalentGroups(false, false)
		local petTalentGroups = GetNumTalentGroups(false, true)

		if talentGroups + petTalentGroups > 1 then
			S:SetUIPanelWindowInfo(PlayerTalentFrame, "width", nil, 31)
			offset = true
		else
			S:SetUIPanelWindowInfo(PlayerTalentFrame, "width")
		end

		hooksecurefunc("PlayerTalentFrame_UpdateSpecs", function(_, numTalentGroups, _, numPetTalentGroups)
			if offset and numTalentGroups + numPetTalentGroups <= 1 then
				S:SetUIPanelWindowInfo(PlayerTalentFrame, "width")
				offset = nil
			elseif not offset and numTalentGroups + numPetTalentGroups > 1 then
				S:SetUIPanelWindowInfo(PlayerTalentFrame, "width", nil, 31)
				offset = true
			end
		end)
	end

	S:HandleCloseButton(PlayerTalentFrameCloseButton, PlayerTalentFrame.backdrop)

	local function glyphFrameOnShow(self)
		if GlyphFrame and GlyphFrame:IsShown() then
			self:Hide()
		end
	end

	PlayerTalentFrameStatusFrame:HookScript("OnShow", glyphFrameOnShow)
	PlayerTalentFrameActivateButton:HookScript("OnShow", glyphFrameOnShow)

	PlayerTalentFrameStatusFrame:StripTextures()
	PlayerTalentFramePointsBar:StripTextures()
	PlayerTalentFramePreviewBar:StripTextures()

	S:HandleButton(PlayerTalentFrameActivateButton)
	S:HandleButton(PlayerTalentFrameResetButton)
	S:HandleButton(PlayerTalentFrameLearnButton)

	if PlayerTalentFramePointsBarResetButton then
		S:HandleButton(PlayerTalentFramePointsBarResetButton)
	end

	--PlayerTalentFramePreviewBarFiller:StripTextures()

	PlayerTalentFrameScrollFrame:StripTextures()
	PlayerTalentFrameScrollFrame:CreateBackdrop("Default")
	S:HandleScrollBar(PlayerTalentFrameScrollFrameScrollBar)

	for i = 1, MAX_NUM_TALENTS do
		local talent = _G["PlayerTalentFrameTalent"..i]
		local icon = _G["PlayerTalentFrameTalent"..i.."IconTexture"]
		local rank = _G["PlayerTalentFrameTalent"..i.."Rank"]

		if talent then
			talent:StripTextures()
			talent:SetTemplate("Default")
			talent:StyleButton()

			icon:SetInside()
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer("ARTWORK")

			rank:SetFont(E.LSM:Fetch("font", E.db.general.font), 12, "OUTLINE")
		end
	end

	for i = 1, 4 do
		S:HandleTab(_G["PlayerTalentFrameTab"..i])
	end

	for i = 1, MAX_TALENT_TABS do
		local tab = _G["PlayerSpecTab"..i]
		tab:GetRegions():Hide()

		tab:SetTemplate("Default")
		tab:StyleButton(nil, true)

		tab:GetNormalTexture():SetInside()
		tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
	end

	PlayerTalentFrameStatusFrame:Point("TOPLEFT", 57, -40)
	PlayerTalentFrameActivateButton:Point("TOP", 0, -40)

	PlayerTalentFrameScrollFrame:Width(302)
	PlayerTalentFrameScrollFrame:Point("TOPRIGHT", PlayerTalentFrame, "TOPRIGHT", -62, -77)
	PlayerTalentFrameScrollFrame:SetPoint("BOTTOM", PlayerTalentFramePointsBar, "TOP", 0, 0)

	PlayerTalentFrameScrollFrameScrollBar:Point("TOPLEFT", PlayerTalentFrameScrollFrame, "TOPRIGHT", 4, -18)
	PlayerTalentFrameScrollFrameScrollBar:Point("BOTTOMLEFT", PlayerTalentFrameScrollFrame, "BOTTOMRIGHT", 4, 18)

	--PlayerTalentFrameResetButton:Point("RIGHT", -4, 1)
	--PlayerTalentFrameLearnButton:Point("RIGHT", PlayerTalentFrameResetButton, "LEFT", -3, 0)

	PlayerSpecTab1:Point("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", -33, -65)
	PlayerSpecTab1.ClearAllPoints = E.noop
	PlayerSpecTab1.SetPoint = E.noop

	PlayerTalentFrameTab1:Point("BOTTOMLEFT", 11, 46)

	local function EUI_AdjustCharacterFrame()
		local cf = _G.CharacterFrame
		if not cf or not cf.GetPoint then return end

		if not cf.__EUI_OrigPoint then
			local a1, parent, a2, x, y = cf:GetPoint()
			cf.__EUI_OrigPoint = {a1 or "CENTER", parent or UIParent, a2 or "CENTER", x or 0, y or 0}
		end

		if cf:IsShown() and PlayerTalentFrame and PlayerTalentFrame:IsShown() then
			cf:ClearAllPoints()
			cf:SetPoint("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", -10, 0)
		elseif cf.__EUI_OrigPoint then
			local p = cf.__EUI_OrigPoint
			cf:ClearAllPoints()
			cf:SetPoint(p[1], p[2], p[3], p[4], p[5])
		end
	end

	if PlayerTalentFrame and PlayerTalentFrame.HookScript then
		PlayerTalentFrame:HookScript("OnShow", EUI_AdjustCharacterFrame)
		PlayerTalentFrame:HookScript("OnHide", EUI_AdjustCharacterFrame)
	end
	if _G.CharacterFrame and _G.CharacterFrame.HookScript then
		_G.CharacterFrame:HookScript("OnShow", EUI_AdjustCharacterFrame)
	end
	if hooksecurefunc then
		hooksecurefunc("ShowUIPanel", function(frame)
			if frame == _G.CharacterFrame or frame == _G.PlayerTalentFrame or frame == _G.GlyphFrame then
				EUI_AdjustCharacterFrame()
			end
		end)

		if type(_G.PlayerGlyphTab_OnClick) == "function" then
			hooksecurefunc("PlayerGlyphTab_OnClick", function()
				EUI_AdjustCharacterFrame()
			end)
		end

		if type(_G.PlayerTalentFrameTab_OnClick) == "function" then
			hooksecurefunc("PlayerTalentFrameTab_OnClick", function()
				EUI_AdjustCharacterFrame()
			end)
		end
	end
end)