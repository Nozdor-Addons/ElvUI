local E, L, V, P, G = unpack(select(2, ...))
local S
if E and E.GetModule then
    S = E:GetModule("Skins")
end
if not S then return end

local function SkinsEnabled()
    local priv = E.private or {}
    local skins = priv.skins or {}
    local blizz = skins.blizzard or {}
    if skins.enable == false then return false end
    if blizz.enable == false then return false end
    return true
end

local function LoadSkin()
    if not SkinsEnabled() or not SpellBookFrame then return end

	if SpellBookFrame.StripTextures then SpellBookFrame:StripTextures(true) end
	if not SpellBookFrame.backdrop and SpellBookFrame.CreateBackdrop then
		SpellBookFrame:CreateBackdrop("Transparent", nil, nil, nil, true)
	end
	if SpellBookFrame.backdrop and SpellBookFrame.backdrop.SetAllPoints then
		SpellBookFrame.backdrop:SetAllPoints(SpellBookFrame)
	end

    if SpellBookPageText and SpellBookPageText.SetTextColor then
        SpellBookPageText:SetTextColor(0.8, 0.8, 0.8)
    end

    if S.HandleEditBox and SpellBookFrameSearchBox then
        S:HandleEditBox(SpellBookFrameSearchBox)
    end

	do
		local i, prev = 1, nil
		while true do
			local tab = _G["SpellBookFrameTabButton"..i]
			if not tab then break end
	
			tab:Size(100, 30)
			tab:ClearAllPoints()
			if i == 1 then
				tab:SetPoint("BOTTOMLEFT", SpellBookFrame, "BOTTOMLEFT", 0, -30)
			else
				tab:SetPoint("LEFT", prev, "RIGHT", 0, 0)                       
			end
	
			local n = tab.GetNormalTexture and tab:GetNormalTexture()
			if n and n.SetTexture then n:SetTexture(nil) end
			local d = tab.GetDisabledTexture and tab:GetDisabledTexture()
			if d and d.SetTexture then d:SetTexture(nil) end
			if S.HandleTab then S:HandleTab(tab) end
	
			if tab.backdrop and tab.backdrop.SetInside then
				tab.backdrop:SetInside(tab, 0, 0)
			end
	
			prev = tab
			i = i + 1
		end
	end

    if S.HandleNextPrevButton then
        if SpellBookPrevPageButton then S:HandleNextPrevButton(SpellBookPrevPageButton, nil, nil, true) end
        if SpellBookNextPageButton then S:HandleNextPrevButton(SpellBookNextPageButton, nil, nil, true) end
    end

    if S.HandleCloseButton and SpellBookCloseButton then
        local parentForClose = (SpellBookFrame and SpellBookFrame.backdrop) or SpellBookFrame
        S:HandleCloseButton(SpellBookCloseButton, parentForClose)
    end

    if ShowAllSpellRanksCheckBox and S.HandleCheckBox then
        S:HandleCheckBox(ShowAllSpellRanksCheckBox)
    end

    do
        local i = 1
        while true do
            local sideTab = _G["SpellBookSkillLineTab"..i]
            if not sideTab then break end
            if sideTab.StripTextures then sideTab:StripTextures() end
            if not sideTab.backdrop and sideTab.CreateBackdrop then
                sideTab:CreateBackdrop("Default")
                if sideTab.backdrop.SetInside then sideTab.backdrop:SetInside(sideTab, 6, 6) end
            end
            local icon = sideTab.GetNormalTexture and sideTab:GetNormalTexture()
            if icon and icon.SetTexCoord then
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                if sideTab.backdrop and icon.SetParent then icon:SetParent(sideTab.backdrop) end
                if icon.SetPoint then icon:SetPoint("TOPLEFT", sideTab.backdrop, "TOPLEFT", 1, -1) end
                if icon.SetPoint then icon:SetPoint("BOTTOMRIGHT", sideTab.backdrop, "BOTTOMRIGHT", -1, 1) end
            end
            local p = sideTab.GetPushedTexture and sideTab:GetPushedTexture()
            if p and p.SetTexture then p:SetTexture(nil) end
            local h = sideTab.GetHighlightTexture and sideTab:GetHighlightTexture()
            if h and h.SetTexture then h:SetTexture(nil) end
            i = i + 1
        end
    end

    do
        local i = 1
        while true do
            local btn = _G["SpellButton"..i]
            if not btn then break end
            local icon = btn.iconTexture or btn.Icon
            if icon and icon.SetTexCoord then
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            if btn.GetHighlightTexture then
                local hl = btn:GetHighlightTexture()
                if hl and hl.SetTexture then hl:SetTexture(nil) end
            end
            if btn.SetCheckedTexture then
                btn:SetCheckedTexture(nil)
            end
            i = i + 1
        end
    end
end

S:AddCallback("Spellbook", LoadSkin)
