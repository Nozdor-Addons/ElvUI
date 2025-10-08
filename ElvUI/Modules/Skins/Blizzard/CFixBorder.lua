local SLOT_NAMES = {
  [1]="HeadSlot",[2]="NeckSlot",[3]="ShoulderSlot",[4]="ShirtSlot",
  [5]="ChestSlot",[6]="WaistSlot",[7]="LegsSlot",[8]="FeetSlot",
  [9]="WristSlot",[10]="HandsSlot",[11]="Finger0Slot",[12]="Finger1Slot",
  [13]="Trinket0Slot",[14]="Trinket1Slot",[15]="BackSlot",[16]="MainHandSlot",
  [17]="SecondaryHandSlot",[18]="RangedSlot",[19]="TabardSlot",
}

local function GetPixel()
  local idx = type(GetCurrentResolution)=="function" and GetCurrentResolution()
  local res = type(GetScreenResolutions)=="function" and ({GetScreenResolutions()})[idx or 1]
  local h = nil
  if type(res)=="string" then h = tonumber(string.match(res, "%d+x(%d+)")) end
  h = h or (type(GetScreenHeight)=="function" and GetScreenHeight()) or 768
  local scale = (type(UIParent.GetScale)=="function" and UIParent:GetScale()) or 1
  return (768 / h) / scale
end

local function Char_GetButton(slotId)
  local name = "Character"..(SLOT_NAMES[slotId] or "")
  return _G[name]
end

local function EnsureBorder(btn)
  if not btn then return nil end
  if btn.CFB and btn.CFB.SetQuality then return btn.CFB end

  for _,k in ipairs({"IconBorder","Border","border","IconBorder2"}) do
    local t = btn[k]
    if t then if t.Hide then t:Hide() end; if t.SetAlpha then t:SetAlpha(0) end end
  end
  if btn.backdrop and btn.backdrop.SetBackdropBorderColor then
    btn.backdrop:SetBackdropBorderColor(0,0,0,0)
  end
  if btn.SetBackdropBorderColor then btn:SetBackdropBorderColor(0,0,0,0) end

  local px = GetPixel()
  local lvl = type(btn.GetFrameLevel)=="function" and (btn:GetFrameLevel() or 0) or 0

  local f = CreateFrame("Frame", nil, btn)
  f:SetAllPoints(btn)
  f:SetFrameLevel(lvl + 5)

  local tTop    = f:CreateTexture(nil, "OVERLAY")
  local tBottom = f:CreateTexture(nil, "OVERLAY")
  local tLeft   = f:CreateTexture(nil, "OVERLAY")
  local tRight  = f:CreateTexture(nil, "OVERLAY")

  local function place()
    tTop:ClearAllPoints()    ; tTop:SetPoint("TOPLEFT",     0, 0) ; tTop:SetPoint("TOPRIGHT",      0, 0) ; tTop:SetHeight(px)
    tBottom:ClearAllPoints() ; tBottom:SetPoint("BOTTOMLEFT",0, 0); tBottom:SetPoint("BOTTOMRIGHT", 0, 0); tBottom:SetHeight(px)
    tLeft:ClearAllPoints()   ; tLeft:SetPoint("TOPLEFT",     0, 0) ; tLeft:SetPoint("BOTTOMLEFT",    0, 0) ; tLeft:SetWidth(px)
    tRight:ClearAllPoints()  ; tRight:SetPoint("TOPRIGHT",   0, 0) ; tRight:SetPoint("BOTTOMRIGHT",  0, 0) ; tRight:SetWidth(px)
  end
  place()

  local function setRGB(r,g,b,a)
    tTop:SetTexture(1,1,1,1)    ; tTop:SetVertexColor(r,g,b,a or 1)
    tBottom:SetTexture(1,1,1,1) ; tBottom:SetVertexColor(r,g,b,a or 1)
    tLeft:SetTexture(1,1,1,1)   ; tLeft:SetVertexColor(r,g,b,a or 1)
    tRight:SetTexture(1,1,1,1)  ; tRight:SetVertexColor(r,g,b,a or 1)
  end

  function f:SetQuality(q)
    local r,g,b = GetItemQualityColor(q or 1)
    setRGB(r,g,b,1)
    f:Show()
  end

  f:SetScript("OnSizeChanged", place)

  btn.CFB = f
  return f
end

local function SafeSetQuality(btn, q)
  local b = EnsureBorder(btn)
  if b and b.SetQuality then b:SetQuality(q) end
end

local function Char_PaintSlot(slotId)
  local btn = Char_GetButton(slotId)
  if not btn then return end
  btn.__slotId = slotId

  EnsureBorder(btn)

  local q = GetInventoryItemQuality("player", slotId)
  if q then SafeSetQuality(btn, q); return end

  local link = GetInventoryItemLink("player", slotId)
  if link then
    local _, _, q2 = GetItemInfo(link)
    if q2 then
      SafeSetQuality(btn, q2)
      return
    else
      GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
      GameTooltip:SetHyperlink(link)
      GameTooltip:Hide()
      SafeSetQuality(btn, 1)
      return
    end
  end

  SafeSetQuality(btn, 1)
end

local function Char_UpdateAll()
  for slotId in pairs(SLOT_NAMES) do
    Char_PaintSlot(slotId)
  end
end

do
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  f:RegisterEvent("UNIT_INVENTORY_CHANGED")
  f:SetScript("OnEvent", function(_, evt, arg1)
    if evt == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
    Char_UpdateAll()
  end)

  if CharacterFrame and type(CharacterFrame.HookScript) == "function" then
    CharacterFrame:HookScript("OnShow", function()
      Char_UpdateAll()
      local runner = CreateFrame("Frame")
      local t, n = 0, 0
      runner:SetScript("OnUpdate", function(self, dt)
        t = t + dt
        if t > 0.12 then
          t = 0; n = n + 1; Char_UpdateAll()
          if n >= 3 then self:SetScript("OnUpdate", nil) self:Hide() end
        end
      end)
    end)
  end

  if type(PaperDollItemSlotButton_Update) == "function" and type(hooksecurefunc) == "function" then
    hooksecurefunc("PaperDollItemSlotButton_Update", function(btn)
      if btn and btn.__slotId then Char_PaintSlot(btn.__slotId) end
    end)
  end
end
