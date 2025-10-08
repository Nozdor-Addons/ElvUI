local E, L, V, P, G = unpack(select(2, ...)) -- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
local GetInventoryItemID = GetInventoryItemID
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetInventoryItemLink = GetInventoryItemLink
local CreateFrame = CreateFrame
local floor = math.floor
local min, max = math.min, math.max

S:AddCallbackForAddon("Blizzard_InspectUI", "Skin_Blizzard_InspectUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.inspect then return end

	InspectFrame:StripTextures(true)
	InspectFrame:CreateBackdrop("Transparent")
	InspectFrame.backdrop:Point("TOPLEFT", 11, -12)
	InspectFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetUIPanelWindowInfo(InspectFrame, "width")

	S:SetBackdropHitRect(InspectFrame)
	S:SetBackdropHitRect(InspectPVPFrame, InspectFrame.backdrop)
	S:SetBackdropHitRect(InspectTalentFrame, InspectFrame.backdrop)

	InspectPVPFrameHonor:SetHitRectInsets(0, 120, 0, 0)
	InspectPVPFrameArena:SetHitRectInsets(0, 120, 0, 0)

	S:HandleCloseButton(InspectFrameCloseButton, InspectFrame.backdrop)

	S:HandleTab(InspectFrameTab1)
	S:HandleTab(InspectFrameTab2)
	S:HandleTab(InspectFrameTab3)

	InspectPaperDollFrame:StripTextures()

	local slots = {
		"HeadSlot",
		"NeckSlot",
		"ShoulderSlot",
		"BackSlot",
		"ChestSlot",
		"ShirtSlot",
		"TabardSlot",
		"WristSlot",
		"HandsSlot",
		"WaistSlot",
		"LegsSlot",
		"FeetSlot",
		"Finger0Slot",
		"Finger1Slot",
		"Trinket0Slot",
		"Trinket1Slot",
		"MainHandSlot",
		"SecondaryHandSlot",
		"RangedSlot"
	}

	for _, slot in ipairs(slots) do
		local icon = _G["Inspect"..slot.."IconTexture"]
		local frame = _G["Inspect"..slot]

		frame:StripTextures()
		frame:SetFrameLevel(frame:GetFrameLevel() + 2)
		frame:CreateBackdrop("Default")
		frame.backdrop:SetAllPoints()

		frame:StyleButton()

		icon:SetTexCoord(unpack(E.TexCoords))
		icon:SetInside()
	end

	local styleButton
	do
		local function awaitCache(button)
			if InspectFrame.unit then
				styleButton(button)
			end
		end

		styleButton = function(button)
			if button.hasItem then
				local itemID = GetInventoryItemID(InspectFrame.unit, button:GetID())
				if itemID then
					local _, _, quality = GetItemInfo(itemID)

					if not quality then
						E:Delay(0.1, awaitCache, button)
						return
					elseif quality then
						button.backdrop:SetBackdropBorderColor(GetItemQualityColor(quality))
						return
					end
				end
			end

			button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end

	hooksecurefunc("InspectPaperDollItemSlotButton_Update", styleButton)

	S:HandleRotateButton(InspectModelRotateLeftButton)
	S:HandleRotateButton(InspectModelRotateRightButton)

	InspectPVPFrame:StripTextures()

	for i = 1, MAX_ARENA_TEAMS do
		local frame = _G["InspectPVPTeam"..i]
		frame:StripTextures()
		frame:CreateBackdrop("Transparent")
		frame.backdrop:Point("TOPLEFT", 9, -6)
		frame.backdrop:Point("BOTTOMRIGHT", -24, -5)
	--	_G["InspectPVPTeam"..i.."StandardBar"]:Kill()
		S:SetBackdropHitRect(frame)
	end

	InspectTalentFrame:StripTextures()

	S:HandleCloseButton(InspectTalentFrameCloseButton, InspectFrame.backdrop)

	for i = 1, MAX_TALENT_TABS do
		local headerTab = _G["InspectTalentFrameTab"..i]

		headerTab:StripTextures()
		headerTab:CreateBackdrop("Default", true)
		headerTab.backdrop:Point("TOPLEFT", 2, -7)
		headerTab.backdrop:Point("BOTTOMRIGHT", 1, -1)
		S:SetBackdropHitRect(headerTab)

		headerTab:Width(i == 2 and 101 or 102)
		headerTab.SetWidth = E.noop

		headerTab:HookScript("OnEnter", S.SetModifiedBackdrop)
		headerTab:HookScript("OnLeave", S.SetOriginalBackdrop)
	end

	for i = 1, MAX_NUM_TALENTS do
		local talent = _G["InspectTalentFrameTalent"..i]

		if talent then
			local icon = _G["InspectTalentFrameTalent"..i.."IconTexture"]
			local rank = _G["InspectTalentFrameTalent"..i.."Rank"]

			talent:StripTextures()
			talent:SetTemplate("Default")
			talent:StyleButton()

			icon:SetInside()
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer("ARTWORK")

			rank:SetFont(E.LSM:Fetch("font", E.db.general.font), 12, "OUTLINE")
		end
	end

	InspectHeadSlot:Point("TOPLEFT", 19, -76)
	InspectHandsSlot:Point("TOPLEFT", 307, -76)
	InspectMainHandSlot:Point("TOPLEFT", InspectPaperDollFrame, "BOTTOMLEFT", 121, 131)

	InspectModelFrame:Size(237, 324)
	InspectModelFrame:Point("TOPLEFT", 63, -76)

	InspectModelRotateLeftButton:Point("TOPLEFT", 4, -4)

	InspectTalentFrameScrollFrame:StripTextures()
	InspectTalentFrameScrollFrame:CreateBackdrop("Transparent")
	InspectTalentFrameScrollFrame.backdrop:Point("TOPLEFT", -1, 1)
	InspectTalentFrameScrollFrame.backdrop:Point("BOTTOMRIGHT", 5, -4)

	InspectTalentFramePointsBar:StripTextures()

	InspectModelRotateRightButton:Point("TOPLEFT", InspectModelRotateLeftButton, "TOPRIGHT", 3, 0)

	InspectFrameTab1:Point("CENTER", InspectFrame, "BOTTOMLEFT", 54, 62)
	InspectFrameTab2:Point("LEFT", InspectFrameTab1, "RIGHT", -15, 0)
	InspectFrameTab3:Point("LEFT", InspectFrameTab2, "RIGHT", -15, 0)

	InspectTalentFrameBackgroundTopLeft:Point("TOPLEFT", 21, -77)

	InspectTalentFrameTab1:Point("TOPLEFT", 17, -40)

	InspectTalentFrameScrollFrame:Width(298)
	InspectTalentFrameScrollFrame:Point("TOPRIGHT", -66, -77)

	S:HandleScrollBar(InspectTalentFrameScrollFrameScrollBar)
	InspectTalentFrameScrollFrameScrollBar:Point("TOPLEFT", InspectTalentFrameScrollFrame, "TOPRIGHT", 8, -18)
	InspectTalentFrameScrollFrameScrollBar:Point("BOTTOMLEFT", InspectTalentFrameScrollFrame, "BOTTOMRIGHT", 8, 15)

	local InspectILvl = InspectPaperDollFrame:CreateFontString(nil, "OVERLAY")
	InspectILvl:FontTemplate(E.LSM:Fetch("font", E.db.general.font), 21, "OUTLINE")

	InspectILvl:Point("TOPLEFT", InspectModelFrame, "BOTTOMLEFT", 100, 50)
	InspectILvl:SetText("—")

		local INSPECT_SLOT_IDS = {
		1,  -- Head
		2,  -- Neck
		3,  -- Shoulder
		15, -- Back
		5,  -- Chest
		9,  -- Wrist
		10, -- Hands
		6,  -- Waist
		7,  -- Legs
		8,  -- Feet
		11, -- Finger 1
		12, -- Finger 2
		13, -- Trinket 1
		14, -- Trinket 2
		16, -- Main Hand
		17, -- Off Hand
		18, -- Ranged (WotLK)
	}

	local function ColorByILvl(ilvl)
		if ilvl <= 190 then
			return GetItemQualityColor(2)
		elseif ilvl <= 200 then
			return GetItemQualityColor(3)
		else
			return GetItemQualityColor(4)
		end
	end

	local function UpdateInspectAverage()
		if not InspectFrame or not InspectFrame.unit or not InspectFrame:IsShown() then return end
		local unit = InspectFrame.unit

		local total, count, needsRetry = 0, 0, false

		for _, slotID in ipairs(INSPECT_SLOT_IDS) do
			local link = GetInventoryItemLink(unit, slotID)
			if link then
				local _, _, _, ilvl = GetItemInfo(link)
				if not ilvl then
					needsRetry = true
				elseif ilvl > 0 then
					total = total + ilvl
					count = count + 1
				end
			end
		end

		if needsRetry then
			E:Delay(0.1, UpdateInspectAverage)
			return
		end

		if count > 0 then
			local avg = total / count
			local rounded = floor(avg + 0.5)
			local r, g, b = ColorByILvl(rounded)
			InspectILvl:SetFormattedText("%d", rounded)
			InspectILvl:SetTextColor(r, g, b)
		else
			InspectILvl:SetText("—")
			InspectILvl:SetTextColor(1, 1, 1)
		end
	end

	InspectFrame:HookScript("OnShow", UpdateInspectAverage)
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", function()
		if InspectFrame:IsShown() then UpdateInspectAverage() end
	end)

	local InspectILvlEvent = CreateFrame("Frame")
	InspectILvlEvent:RegisterEvent("INSPECT_READY")
	InspectILvlEvent:SetScript("OnEvent", function(_, event, guid)
		if InspectFrame:IsShown() then UpdateInspectAverage() end
	end)
end)