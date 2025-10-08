local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")
local TT = E:GetModule("Tooltip")

--Lua functions
--WoW API / Variables

S:AddCallback("Skin_Tooltip", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.tooltip then return end

	S:HandleCloseButton(ItemRefCloseButton, ItemRefTooltip)

	local tooltips = {
		GameTooltip,
		ItemRefTooltip,
		ItemRefShoppingTooltip1,
		ItemRefShoppingTooltip2,
		ItemRefShoppingTooltip3,
		AutoCompleteBox,
		FriendsTooltip,
		ConsolidatedBuffsTooltip,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ShoppingTooltip3,
		WorldMapTooltip,
		WorldMapCompareTooltip1,
		WorldMapCompareTooltip2,
		WorldMapCompareTooltip3
	}
	for _, tt in ipairs(tooltips) do
		TT:SecureHookScript(tt, "OnShow", "SetStyle")
	end

	GameTooltipStatusBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(GameTooltipStatusBar)
	GameTooltipStatusBar:CreateBackdrop("Transparent")
	GameTooltipStatusBar:Point("TOPLEFT", GameTooltip, "BOTTOMLEFT", E.Border, -(E.Spacing * 3))
	GameTooltipStatusBar:Point("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -E.Border, -(E.Spacing * 3))

	TT:SecureHook("GameTooltip_ShowStatusBar", "GameTooltip_ShowStatusBar")

	TT:SecureHookScript(GameTooltip, "OnSizeChanged", "CheckBackdropColor")
	TT:SecureHookScript(GameTooltip, "OnUpdate", "CheckBackdropColor")
end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    local E = _G.ElvUI and unpack(ElvUI)
    if not E then return end
    local TT = E:GetModule("Tooltip")
    if not TT or TT._patched_EnemyInspectLoop then return end
    TT._patched_EnemyInspectLoop = true

    local UnitGUID, UnitIsPlayer, UnitIsEnemy = UnitGUID, UnitIsPlayer, UnitIsEnemy
    local CanInspect = CanInspect

    local function GetTooltipUnit()
        local tt = _G.GameTooltip
        if not tt then return end
        local _, unit = tt:GetUnit()
        return unit
    end

    TT._ShowInspectInfo_Orig = TT.ShowInspectInfo
    function TT:ShowInspectInfo(...)
        if self._inShowInspectInfo then return end

        local unit = GetTooltipUnit()
        if unit then
            if not CanInspect(unit, false) or (UnitIsPlayer(unit) and UnitIsEnemy("player", unit)) then
                return
            end
        end

        self._inShowInspectInfo = true
        local ok, err = pcall(self._ShowInspectInfo_Orig, self, ...)
        self._inShowInspectInfo = false
        if not ok then geterrorhandler()(err) end
    end

    TT._INSPECT_TALENT_READY_Orig = TT.INSPECT_TALENT_READY
    function TT:INSPECT_TALENT_READY(guid, ...)
        local unit = GetTooltipUnit()
        if not unit or UnitGUID(unit) ~= guid then return end
        if not CanInspect(unit, false) or (UnitIsPlayer(unit) and UnitIsEnemy("player", unit)) then
            return
        end
        if self._inShowInspectInfo then return end
        return self._INSPECT_TALENT_READY_Orig(self, guid, ...)
    end
end)