local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
local type = type

S:AddCallbackForAddon("Blizzard_GlyphUI", "Skin_Blizzard_GlyphUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	if not PlayerTalentFrame then
		TalentFrame_LoadUI()
	end

	-- Keep Blizzard's parchment texture; just remove ElvUI's full-frame textures
	GlyphFrame:StripTextures()

	-- ==== TUNING ====
	-- Size of the parchment area (and the layout radius) relative to Blizzard's default
	local paperScale = 0.97   -- 0.90..0.98 are usually nice
	-- Size of the glyph buttons relative to default
	local slotScale  = 0.94   -- keep close to paperScale
	-- Vertical nudge for the whole parchment block (helps center it visually)
	local yOffset    = 6
	-- =================

	-- Base size used by Blizzard/ElvUI skin in 3.3.5
	local baseW, baseH = 323, 349

	-- Create a real frame to hold parchment + buttons.
	-- IMPORTANT: Buttons cannot be parented to a Texture, only a Frame.
	local holder = _G.GlyphFrameElvUIHolder
	if not holder then
		holder = CreateFrame("Frame", "GlyphFrameElvUIHolder", GlyphFrame)
	end
	holder:ClearAllPoints()
	holder:SetPoint("CENTER", GlyphFrame, "CENTER", 0, yOffset)
	holder:SetSize(baseW * paperScale, baseH * paperScale)
	holder:SetFrameLevel(GlyphFrame:GetFrameLevel() + 1)

	-- Parchment texture
	GlyphFrameBackground:ClearAllPoints()
	GlyphFrameBackground:SetParent(holder)
	GlyphFrameBackground:SetAllPoints(holder)
	GlyphFrameBackground:SetDrawLayer("BACKGROUND", 0)
	GlyphFrameBackground:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
	-- texWidth, texHeight, cropWidth, cropHeight, offsetX, offsetY = 512, 512, 315, 340, 21, 72
	GlyphFrameBackground:SetTexCoord(0.041015625, 0.65625, 0.140625, 0.8046875)

	-- Glow
	GlyphFrameGlow:ClearAllPoints()
	GlyphFrameGlow:SetParent(holder)
	GlyphFrameGlow:SetAllPoints(holder)
	GlyphFrameGlow:SetDrawLayer("BACKGROUND", 1)
	GlyphFrameGlow:SetTexture("Interface\\Spellbook\\UI-GlyphFrame-Glow")
	-- texWidth, texHeight, cropWidth, cropHeight, offsetX, offsetY = 512, 512, 315, 340, 30, 34
	GlyphFrameGlow:SetTexCoord(0.05859375, 0.673828125, 0.06640625, 0.73046875)

	-- Positions are relative to CENTER of parchment.
	-- We scale the offsets with paperScale, and scale the buttons with slotScale.
	local glyphPositions = {
		{"CENTER", -1, 126},   -- 1 top
		{"CENTER", -1, -119},  -- 2 bottom
		{"TOPLEFT", 8, -62},   -- 3 top-left
		{"BOTTOMRIGHT", -10, 70}, -- 4 bottom-right
		{"TOPRIGHT", -8, -62}, -- 5 top-right
		{"BOTTOMLEFT", 7, 70}  -- 6 bottom-left
	}

	local function ApplyGlyphLayout()
		local glyphFrameLevel = holder:GetFrameLevel() + 5

		for i = 1, 6 do
			local btn = _G["GlyphFrameGlyph"..i]
			if btn then
				btn:SetParent(holder) -- parent MUST be a Frame (not a Texture)
				btn:SetFrameLevel(glyphFrameLevel)
				btn:SetScale(slotScale)

				btn:ClearAllPoints()
				local p, x, y = glyphPositions[i][1], glyphPositions[i][2], glyphPositions[i][3]
				btn:SetPoint(p, holder, p, x * paperScale, y * paperScale)
			end
		end
	end

	ApplyGlyphLayout()

	-- Re-apply after Blizzard updates the glyph frame (prevents drift/overlap)
	hooksecurefunc("GlyphFrame_Update", function()
		if GlyphFrame and GlyphFrame:IsShown() then
			ApplyGlyphLayout()
		end
	end)

	-- Keep the original ElvUI behavior hiding Talent UI bits while glyph tab is open
	GlyphFrame:HookScript("OnShow", function()
		PlayerTalentFrameTitleText:Hide()
		PlayerTalentFramePointsBar:Hide()
		PlayerTalentFrameScrollFrame:Hide()
		PlayerTalentFrameStatusFrame:Hide()
		PlayerTalentFrameActivateButton:Hide()

		if PlayerTalentFrame.ElvUI_UpdateTalentOffset then
			PlayerTalentFrame.ElvUI_UpdateTalentOffset(nil, nil, true)
		end
	end)

	GlyphFrame:SetScript("OnHide", function()
		PlayerTalentFrameTitleText:Show()
		PlayerTalentFramePointsBar:Show()
		PlayerTalentFrameScrollFrame:Show()

		if PlayerTalentFrame.ElvUI_UpdateTalentOffset then
			PlayerTalentFrame.ElvUI_UpdateTalentOffset(nil, nil, true)
		end
	end)

	hooksecurefunc(PlayerTalentFrame, "updateFunction", function()
		if GlyphFrame:IsShown() then
			PlayerTalentFramePreviewBar:Hide()
		end
	end)
end)
