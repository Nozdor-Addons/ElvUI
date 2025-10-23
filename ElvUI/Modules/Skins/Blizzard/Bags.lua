-- Quality Border Overlay for Bags & Bank (WotLK 3.3.5)
-- Works with Blizzard bags and ElvUI Bags. Draws own overlay border and colors by item rarity.
-- Rules:
--   * Unknown rarity (cache cold) -> WHITE border (temporary)
--   * Grey/White (0–1) -> no border
--   * Green+ (>=2) -> rarity color
-- Designed to be robust across reloads and late GetItemInfo.

local E, L, V, P, G = unpack(select(2, ...))

local _G        = _G
local select    = select
local unpack    = unpack
local type      = type
local format    = string.format

local WHITE_TEX        = "Interface\\Buttons\\WHITE8x8"
local BORDER_THICKNESS = 1
local RETRY_1          = 0.10
local RETRY_2          = 0.25

-- ========= Utilities =========
local function DefaultColor()
    if E and E.media and E.media.bordercolor then
        return unpack(E.media.bordercolor)
    end
    return 0.1, 0.1, 0.1
end

local function Delay(sec, fn)
    if E and E.Delay then
        return E:Delay(sec, fn)
    elseif C_Timer and C_Timer.After then
        return C_Timer.After(sec, fn)
    else
        local f = CreateFrame("Frame"); local t = 0
        f:SetScript("OnUpdate", function(_, e) t=t+e; if t>=sec then f:SetScript("OnUpdate", nil); pcall(fn) end end)
    end
end

local function ParseItemID(link)
    if not link then return nil end
    local id = link:match("item:(%d+)")
    return id and tonumber(id) or nil
end

-- ========= Overlay =========
local function EnsureOverlay(btn)
    if not btn or btn.__QOverlay then return end

    local f = CreateFrame("Frame", nil, btn)
    f:SetAllPoints(btn)
    f:EnableMouse(false)
    -- Make sure we are above any skin/layers on the button
    local base = btn.GetFrameLevel and btn:GetFrameLevel() or 0
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(base + 100)

    local t = f:CreateTexture(nil, "OVERLAY")
    local b = f:CreateTexture(nil, "OVERLAY")
    local l = f:CreateTexture(nil, "OVERLAY")
    local r = f:CreateTexture(nil, "OVERLAY")
    t:SetTexture(WHITE_TEX); b:SetTexture(WHITE_TEX); l:SetTexture(WHITE_TEX); r:SetTexture(WHITE_TEX)

    local inset = 0
    t:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
    t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -inset, -inset)
    t:SetHeight(BORDER_THICKNESS)

    b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", inset, inset)
    b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
    b:SetHeight(BORDER_THICKNESS)

    l:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
    l:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", inset, inset)
    l:SetWidth(BORDER_THICKNESS)

    r:SetPoint("TOPRIGHT", f, "TOPRIGHT", -inset, -inset)
    r:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
    r:SetWidth(BORDER_THICKNESS)

    btn.__QOverlay = f
    btn.__QTop, btn.__QBot, btn.__QLft, btn.__QRgt = t, b, l, r

    btn:HookScript("OnShow", function(self)
        if self.__QColor then
            local r,g,b = self.__QColor[1], self.__QColor[2], self.__QColor[3]
            self.__QTop:SetVertexColor(r,g,b,1)
            self.__QBot:SetVertexColor(r,g,b,1)
            self.__QLft:SetVertexColor(r,g,b,1)
            self.__QRgt:SetVertexColor(r,g,b,1)
        end
        if self.__QVisible ~= nil then
            local a = self.__QVisible and 1 or 0
            self.__QTop:SetAlpha(a); self.__QBot:SetAlpha(a); self.__QLft:SetAlpha(a); self.__QRgt:SetAlpha(a)
        end
    end)
end

local function SetOverlayColor(btn, r, g, b)
    EnsureOverlay(btn)
    btn.__QTop:SetVertexColor(r, g, b, 1)
    btn.__QBot:SetVertexColor(r, g, b, 1)
    btn.__QLft:SetVertexColor(r, g, b, 1)
    btn.__QRgt:SetVertexColor(r, g, b, 1)
    btn.__QColor = {r, g, b}
end

local function SetOverlayVisible(btn, vis)
    EnsureOverlay(btn)
    local a = vis and 1 or 0
    btn.__QTop:SetAlpha(a); btn.__QBot:SetAlpha(a); btn.__QLft:SetAlpha(a); btn.__QRgt:SetAlpha(a)
    btn.__QVisible = vis
end

local function HideBlizzardIconBorder(btn, nameHint)
    if nameHint then
        local ib = _G[nameHint.."IconBorder"]
        if ib then
            if ib.Hide then ib:Hide() end
            if ib.SetTexture then ib:SetTexture(nil) end
            if ib.SetAlpha then ib:SetAlpha(0) end
            ib.Show = function() end
        end
    end
    if btn and btn.IconBorder then
        local ib = btn.IconBorder
        if ib.Hide then ib:Hide() end
        if ib.SetTexture then ib:SetTexture(nil) end
        if ib.SetAlpha then ib:SetAlpha(0) end
        btn.IconBorder = nil
    end
end

-- Decide and set border for a button by given quality (or nil)
local function ApplyDecision(btn, quality, useQualityColors)
    if quality == nil then
        -- unknown rarity -> white border (temporary)
        SetOverlayColor(btn, 1, 1, 1)
        SetOverlayVisible(btn, true)
        btn.__QDesired = -1
        return
    end
    if useQualityColors then
        if quality >= 2 then
            local r,g,b = GetItemQualityColor(quality)
            SetOverlayColor(btn, r, g, b)
            SetOverlayVisible(btn, true)
        else
            -- grey/white -> no border
            SetOverlayVisible(btn, false)
        end
    else
        -- user disabled quality colors -> hide
        SetOverlayVisible(btn, false)
    end
    btn.__QDesired = quality
end

-- ========= Central updater =========
local Pending = {}  -- weak set of buttons waiting for GetItemInfo
local function TrackPending(btn, itemID)
    if not btn or not itemID then return end
    btn.__QPending = itemID
    Pending[btn] = true
end

local function Untrack(btn)
    if not btn then return end
    btn.__QPending = nil
    Pending[btn] = nil
end

local function RefreshButtonFromSource(btn, bagID, slotID, useQualityColors)
    if not btn then return end
    HideBlizzardIconBorder(btn, btn.GetName and btn:GetName() or nil)

    -- First try container-provided quality (instant on 3.3.5)
    local _, _, _, q, _, _, link = GetContainerItemInfo(bagID, slotID)
    if q ~= nil then
        ApplyDecision(btn, q, useQualityColors)
        Untrack(btn)
        return
    end

    -- No quality yet. If we have link, try GetItemInfo; show white meanwhile.
    if link then
        ApplyDecision(btn, nil, useQualityColors) -- temporary white
        local id = ParseItemID(link)
        if id then
            TrackPending(btn, id)
        end

        -- quick retries (helps right after /reload)
        Delay(RETRY_1, function()
            local rq = select(3, GetItemInfo(link))
            if rq ~= nil then
                ApplyDecision(btn, rq, useQualityColors)
                Untrack(btn)
            end
        end)
        Delay(RETRY_2, function()
            local rq = select(3, GetItemInfo(link))
            if rq ~= nil then
                ApplyDecision(btn, rq, useQualityColors)
                Untrack(btn)
            end
        end)
        return
    end

    -- empty slot
    SetOverlayVisible(btn, false)
    Untrack(btn)
end

-- Bank button updater (item slots & bank bag buttons)
local function RefreshBankButton(btn)
    if not btn then return end
    HideBlizzardIconBorder(btn, btn.GetName and btn:GetName() or nil)

    local useQualityColors = true
    if E and E.GetModule then
        local B = E:GetModule("Bags", true)
        if B and B.db then useQualityColors = not not B.db.qualityColors end
    end

    if btn.isBag then
        local invID = ContainerIDToInventoryID(btn:GetID())
        local q = invID and GetInventoryItemQuality("player", invID) or nil
        if q ~= nil then
            ApplyDecision(btn, q, useQualityColors)
            return
        end
        local link = invID and GetInventoryItemLink("player", invID)
        if link then
            ApplyDecision(btn, nil, useQualityColors)
            local id = ParseItemID(link)
            if id then TrackPending(btn, id) end
            Delay(RETRY_1, function()
                local rq = select(3, GetItemInfo(link))
                if rq ~= nil then ApplyDecision(btn, rq, useQualityColors); Untrack(btn) end
            end)
            Delay(RETRY_2, function()
                local rq = select(3, GetItemInfo(link))
                if rq ~= nil then ApplyDecision(btn, rq, useQualityColors); Untrack(btn) end
            end)
        else
            SetOverlayVisible(btn, false)
        end
        return
    end

    -- bank item slot
    local slot = btn:GetID()
    local _, _, _, q, _, _, link = GetContainerItemInfo(BANK_CONTAINER, slot)
    if q ~= nil then
        ApplyDecision(btn, q, useQualityColors)
        return
    end
    if link then
        ApplyDecision(btn, nil, useQualityColors)
        local id = ParseItemID(link); if id then TrackPending(btn, id) end
        Delay(RETRY_1, function()
            local rq = select(3, GetItemInfo(link))
            if rq ~= nil then ApplyDecision(btn, rq, useQualityColors); Untrack(btn) end
        end)
        Delay(RETRY_2, function()
            local rq = select(3, GetItemInfo(link))
            if rq ~= nil then ApplyDecision(btn, rq, useQualityColors); Untrack(btn) end
        end)
    else
        SetOverlayVisible(btn, false)
    end
end

-- ========= Hooks =========
-- Blizzard containers
local function RepaintContainer(frame)
    if not frame or not frame.size then return end
    local bag = frame:GetID()
    local name = frame:GetName()

    local useQualityColors = true
    if E and E.GetModule then
        local B = E:GetModule("Bags", true)
        if B and B.db then useQualityColors = not not B.db.qualityColors end
    end

    for i=1, frame.size do
        local btn = _G[name.."Item"..i]
        if btn then
            EnsureOverlay(btn)
            RefreshButtonFromSource(btn, bag, i, useQualityColors)
        end
    end
end

local function BankButtonUpdate(btn)
    EnsureOverlay(btn)
    RefreshBankButton(btn)
end

local function HookWhenAvailable(fname, hookfn, eventName, cond)
    if type(_G[fname]) == "function" then
        hooksecurefunc(fname, hookfn); return
    end
    local f = CreateFrame("Frame")
    f:RegisterEvent(eventName or "PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self)
        if not cond or cond() then
            if type(_G[fname]) == "function" then
                hooksecurefunc(fname, hookfn)
                self:UnregisterAllEvents()
                self:SetScript("OnEvent", nil)
            end
        end
    end)
end

HookWhenAvailable("ContainerFrame_Update", RepaintContainer, "PLAYER_ENTERING_WORLD")
HookWhenAvailable("BankFrameItemButton_Update", BankButtonUpdate, "BANKFRAME_OPENED", function() return _G.BankFrame and _G.BankFrame:IsShown() end)

-- ElvUI Bags
local function HookElvUIBags()
    if not (E and E.GetModule) then return end
    local B = E:GetModule("Bags", true)
    if not B then return end

    if not B.__QHooked then
        B.__QHooked = true
        hooksecurefunc(B, "UpdateSlot", function(_, frame, bagID, slotID)
            if not (frame and frame.Bags and frame.Bags[bagID]) then return end
            local slot = frame.Bags[bagID][slotID]
            if not slot then return end
            EnsureOverlay(slot)
            local useQualityColors = not not (B.db and B.db.qualityColors)
            RefreshButtonFromSource(slot, bagID, slotID, useQualityColors)
        end)
        hooksecurefunc(B, "UpdateKeySlot", function(_, slotID)
            local slot = _G["ElvUIKeyFrameItem"..slotID]
            if not slot then return end
            EnsureOverlay(slot)
            local useQualityColors = not not (B.db and B.db.qualityColors)
            RefreshButtonFromSource(slot, KEYRING_CONTAINER, slotID, useQualityColors)
        end)
    end
end

HookElvUIBags()
local once = CreateFrame("Frame")
once:RegisterEvent("PLAYER_ENTERING_WORLD")
once:SetScript("OnEvent", function(self) HookElvUIBags() end)

-- Universal quality hook (any addon that calls it)
if type(_G.SetItemButtonQuality) == "function" then
    hooksecurefunc("SetItemButtonQuality", function(button, quality)
        if not button then return end
        EnsureOverlay(button)
        local use = true
        if E and E.GetModule then
            local B = E:GetModule("Bags", true)
            if B and B.db then use = not not B.db.qualityColors end
        end
        ApplyDecision(button, quality, use)
    end)
end

-- GET_ITEM_INFO_RECEIVED: refresh pending buttons by itemID
local evt = CreateFrame("Frame")
evt:RegisterEvent("GET_ITEM_INFO_RECEIVED")
evt:SetScript("OnEvent", function(_, _, itemID)
    if not itemID then return end
    for btn in pairs(Pending) do
        if btn.__QPending == itemID then
            -- Try to resolve
            local link = btn.GetItemLink and btn:GetItemLink() -- some buttons have helper
            local rq
            if link then
                rq = select(3, GetItemInfo(link))
            end
            if rq == nil then
                -- We don't know bag/slot from button reliably here; just recolor white stays.
            else
                local use = true
                if E and E.GetModule then
                    local B = E:GetModule("Bags", true); if B and B.db then use = not not B.db.qualityColors end
                end
                ApplyDecision(btn, rq, use)
                Untrack(btn)
            end
        end
    end
end)

-- Safety: hide IconBorder for Blizzard bags when shown
if type(_G.ContainerFrameItemButton_Update) == "function" then
hooksecurefunc("ContainerFrameItemButton_Update", function(btn)
    if not btn then return end
    HideBlizzardIconBorder(btn, btn:GetName() or nil)
end)

end
