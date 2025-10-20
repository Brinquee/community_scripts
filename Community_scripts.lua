-- SANITY TEST: deve SEMPRE criar o botão e abrir uma janela simples
local tabName = getTab('HP') or getTab('Main') or setDefaultTab('Main')

local wnd = setupUI([[
MainWindow
  !text: tr('Community Scripts - TEST')
  size: 320 220

  Label
    id: lbl
    anchors.centerIn: parent
    text: Pronto! A janela abriu. (teste)
]])

wnd:hide()

local btn = UI.Button('CS Manager (TEST)', function()
  if wnd:isVisible() then wnd:hide() else wnd:show(); wnd:raise(); wnd:focus() end
end, tabName)
btn:setColor('#d2cac5')
print('[TEST] Botão e janela criados.')
