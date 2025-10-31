-- =========================================================
-- HEAL ID BIJUU+ (compacto, listas lado a lado, numeros visiveis)
-- sem acentos / vBot-OTClientV8
-- =========================================================

setDefaultTab("Tools")

-- evita duplicar o botao ao recarregar
if btnEditHealingBijuu and not btnEditHealingBijuu:isDestroyed() then
  btnEditHealingBijuu:destroy()
end

-- -------------------------
-- Defaults persistentes
-- -------------------------
storage.bijuuEnabled   = (storage.bijuuEnabled ~= false)
storage.bijuuLowHp     = storage.bijuuLowHp or 85
storage.bijuuHighHp    = storage.bijuuHighHp or 95
storage.bijuuMinMana   = storage.bijuuMinMana or 0        -- 0 ignora mana
storage.bijuuCooldown  = storage.bijuuCooldown or 1500    -- ms

-- Listas separadas (um ID por linha ou separados por virgula)
storage.lookNormal     = storage.lookNormal or ""
storage.lookBijuu      = storage.lookBijuu  or "162,340"

storage.bijuuSpell     = storage.bijuuSpell or "Bijuu regeneration"
storage.normalSpell    = storage.normalSpell or "big regeneration"

-- -------------------------
-- Utils
-- -------------------------
local root = g_ui and g_ui.getRootWidget and g_ui.getRootWidget() or nil
local function trim(s) return (s and s:gsub("^%s+", ""):gsub("%s+$", "")) or "" end

local function parseLooktypes(str)
  local map = {}
  if not str or str == "" then return map end
  for token in string.gmatch(str, "%d+") do map[tonumber(token)] = true end
  return map
end
local function stringHasNumber(str) return type(str)=="string" and string.find(str,"%d")~=nil end

local lastBijuuStr, BIJUU_MAP = nil, {}
local lastNormalStr, NORMAL_MAP = nil, {}

local function getBijuuMap()
  if storage.lookBijuu ~= lastBijuuStr then
    lastBijuuStr = storage.lookBijuu
    BIJUU_MAP = parseLooktypes(lastBijuuStr)
  end
  return BIJUU_MAP
end
local function getNormalMap()
  if storage.lookNormal ~= lastNormalStr then
    lastNormalStr = storage.lookNormal
    NORMAL_MAP = parseLooktypes(lastNormalStr)
  end
  return NORMAL_MAP
end

local _now = type(now) == "function" and now or function() return math.floor(os.clock()*1000) end

-- -------------------------
-- Painel (setupUI) compacto + valores numericos
-- -------------------------
local function openHealPanel()
  if not root then print("root nao encontrado"); return end
  local existing = root:getChildById("healBijuuPanel")
  if existing then existing:destroy(); return end

  local ui = setupUI([[
MainWindow
  id: healBijuuPanel
  text: HEALING EDIT
  size: 360 450
  color:#21fff8
  background-color: black
  opacity: 0.9

  Label
    id: title
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    text: ""
    color: #21fff8
    margin-top: 8

  Label
    id: lowLbl
    anchors.top: title.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 8
    text: "LOW_HP:"
    color: #21fff8

  HorizontalScrollBar
    id: lowHp
    anchors.top: lowLbl.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 80
    minimum: 1
    maximum: 100
    step: 1
    height: 15

  Label
    id: lowVal
    anchors.top: lowHp.top
    anchors.right: parent.right
    margin-right: 10
    text: "0%"
    color: yellow

  Label
    id: highLbl
    anchors.top: lowHp.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 10
    text: "HIGH_HP:"
    color: #21fff8

  HorizontalScrollBar
    id: highHp
    anchors.top: highLbl.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 80
    minimum: 1
    maximum: 100
    step: 1
    height: 15

  Label
    id: highVal
    anchors.top: highHp.top
    anchors.right: parent.right
    margin-right: 10
    text: "0%"
    color: yellow

  Label
    id: manaLbl
    anchors.top: highHp.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 10
    text: "MIN_MANA:"
    color: #21fff8

  HorizontalScrollBar
    id: manaHp
    anchors.top: manaLbl.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 80
    minimum: 0
    maximum: 100
    step: 1
    height: 15

  Label
    id: manaVal
    anchors.top: manaHp.top
    anchors.right: parent.right
    margin-right: 10
    text: "0%"
    color: yellow

  Label
    id: cdLbl
    anchors.top: manaHp.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 10
    text: "COOLDOWN:"
    color: #21fff8

  HorizontalScrollBar
    id: cdBar
    anchors.top: cdLbl.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 80
    minimum: 200
    maximum: 5000
    step: 50
    height: 15

  Label
    id: cdVal
    anchors.top: cdBar.top
    anchors.right: parent.right
    margin-right: 10
    text: "0 ms"
    color: yellow

  -- Linha dupla: Normal (esq) e Especial (dir)
  Label
    id: lookLeftLbl
    anchors.top: cdBar.bottom
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    margin-left: 10
    margin-right: 5
    margin-top: 12
    text: "NORMAL"
    color: #21fff8

  Label
    id: lookRightLbl
    anchors.top: cdBar.bottom
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    margin-left: 5
    margin-right: 10
    margin-top: 12
    text: "ESPECIAL"
    color: #21fff8

  TextEdit
    id: lookNormalEdit
    anchors.top: lookLeftLbl.bottom
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    margin-left: 10
    margin-right: 5
    height: 22
    multiline: false
    color: yellow

  TextEdit
    id: lookBijuuEdit
    anchors.top: lookRightLbl.bottom
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    margin-left: 5
    margin-right: 10
    height: 22
    multiline: false
    color: yellow

  Label
    id: s1Lbl
    anchors.top: lookBijuuEdit.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 10
    text: "SPELL BIJUU"
    color: #21fff8

  TextEdit
    id: s1Edit
    anchors.top: s1Lbl.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    height: 22
    multiline: false
    color: yellow

  Label
    id: s2Lbl
    anchors.top: s1Edit.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 10
    text: "SPELL NORMAL"
    color: #21fff8

  TextEdit
    id: s2Edit
    anchors.top: s2Lbl.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    height: 22
    multiline: false
    color: yellow

  HorizontalSeparator
    id: sep1
    anchors.top: s2Edit.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 10

  Button
    id: testBijuu
    text: "TESTAR SPELL BIJUU"
    anchors.top: sep1.bottom
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    margin-left: 10
    margin-right: 5
    height: 22
    color: #21fff8

  Button
    id: testNormal
    text: "TESTAR SPELL NORMAL"
    anchors.top: sep1.bottom
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    margin-left: 5
    margin-right: 10
    height: 22
    color: #21fff8

  Button
    id: outfitId
    text: "ID OUTFIT"
    anchors.top: testNormal.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    margin-top: 6
    height: 20
    color: #21fff8

  Button
    id: closeButton
    text: "Fechar"
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-right: 10
    margin-bottom: 10
    width: 80
    color: red
]], root)

  -- valores iniciais
  ui.lowHp:setValue(storage.bijuuLowHp)
  ui.highHp:setValue(storage.bijuuHighHp)
  ui.manaHp:setValue(storage.bijuuMinMana)
  ui.cdBar:setValue(storage.bijuuCooldown)

  ui.lookNormalEdit:setText(storage.lookNormal)
  ui.lookBijuuEdit:setText(storage.lookBijuu)
  ui.s1Edit:setText(storage.bijuuSpell)
  ui.s2Edit:setText(storage.normalSpell)

  ui.lowVal:setText(storage.bijuuLowHp .. "%")
  ui.highVal:setText(storage.bijuuHighHp .. "%")
  ui.manaVal:setText(storage.bijuuMinMana .. "%")
  ui.cdVal:setText(storage.bijuuCooldown .. " ms")

  -- eventos
  ui.lowHp.onValueChange = function(_, v)
    storage.bijuuLowHp = v
    if storage.bijuuHighHp < v then
      storage.bijuuHighHp = v
      ui.highHp:setValue(v)
      ui.highVal:setText(v .. "%")
    end
    ui.lowVal:setText(v .. "%")
  end

  ui.highHp.onValueChange = function(_, v)
    storage.bijuuHighHp = v
    if storage.bijuuLowHp > v then
      storage.bijuuLowHp = v
      ui.lowHp:setValue(v)
      ui.lowVal:setText(v .. "%")
    end
    ui.highVal:setText(v .. "%")
  end

  ui.manaHp.onValueChange = function(_, v)
    storage.bijuuMinMana = v
    ui.manaVal:setText(v .. "%")
  end

  ui.cdBar.onValueChange = function(_, v)
    storage.bijuuCooldown = v
    ui.cdVal:setText(v .. " ms")
  end

  ui.lookNormalEdit.onTextChange = function(_, text) storage.lookNormal = text end
  ui.lookBijuuEdit.onTextChange  = function(_, text) storage.lookBijuu  = text end
  ui.s1Edit.onTextChange         = function(_, text) storage.bijuuSpell  = text end
  ui.s2Edit.onTextChange         = function(_, text) storage.normalSpell = text end

  ui.testBijuu.onClick = function()
    local s = trim(storage.bijuuSpell)
    say((s ~= "" and s) or "Bijuu regeneration")
  end
  ui.testNormal.onClick = function()
    local s = trim(storage.normalSpell)
    say((s ~= "" and s) or "big regeneration")
  end
  ui.outfitId.onClick = function()
    local ot = (type(outfit) == "function" and outfit()) or {}
    local id = ot.type or -1
    say(tostring(id))
  end

  ui.closeButton.onClick = function() ui:destroy() end
end

-- Botao no painel do bot (guard para nao duplicar)
btnEditHealingBijuu = UI.Button("EDIT HEALING", function() openHealPanel() end)

-- -------------------------
-- Macro: histerese + anti flood + listas separadas
-- -------------------------
local needHeal, lastCast = false, 0

macro(200, "HEALING", function()
  if not storage.bijuuEnabled then return end

  local hp = hppercent() or 100
  local low     = storage.bijuuLowHp or 85
  local high    = storage.bijuuHighHp or 95
  local minMana = storage.bijuuMinMana or 0
  local cd      = storage.bijuuCooldown or 1500

  if hp <= low then needHeal = true
  elseif hp >= high then needHeal = false end
  if not needHeal then return end

  if type(manapercent)=="function" and minMana>0 and (manapercent() or 100) < minMana then return end
  if _now() - lastCast < cd then return end

  local otf = (type(outfit)=="function" and outfit()) or {}
  local t = otf.type or -1

  local bijuuMap  = getBijuuMap()
  local normalMap = getNormalMap()
  local hasBijuuList  = stringHasNumber(storage.lookBijuu)
  local hasNormalList = stringHasNumber(storage.lookNormal)

  local inBijuu  = bijuuMap[t]  == true
  local inNormal = normalMap[t] == true

  local bijuuSpell  = trim(storage.bijuuSpell);  if bijuuSpell==""  then bijuuSpell="Bijuu regeneration" end
  local normalSpell = trim(storage.normalSpell); if normalSpell=="" then normalSpell="big regeneration" end

  local spell
  if hasBijuuList and inBijuu then
    spell = bijuuSpell
  elseif (not hasNormalList) or inNormal then
    spell = normalSpell
  else
    spell = normalSpell
  end

  say(spell)
  lastCast = _now()
end)
