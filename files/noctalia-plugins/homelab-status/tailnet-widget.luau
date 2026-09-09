local state = noctalia.state.get("tailnet") or { status = "loading", peers = {} }

local function render()
  local peers = state.peers or {}
  local online = 0
  local tooltip = {}

  for _, peer in ipairs(peers) do
    if peer.connected then
      online = online + 1
    end
    table.insert(tooltip, peer.name .. (peer.connected and "  UP" or "  DOWN"))
  end

  barWidget.setVisible(true)
  barWidget.setGlyph("network")
  barWidget.setGlyphColor(state.status == "error" and "#FF949D" or "on_surface")

  if state.status == "loading" then
    barWidget.setText("…")
    barWidget.setColor("on_surface_variant")
    barWidget.setTooltip("Loading tailnet devices")
  elseif state.status == "error" then
    barWidget.setText("ERR")
    barWidget.setColor("#FF949D")
    barWidget.setTooltip("Tailnet: " .. tostring(state.message or "request failed"))
  else
    barWidget.setText(tostring(online) .. "/" .. tostring(#peers))
    barWidget.setColor(online == #peers and "#21FEC0" or "on_surface")
    if #tooltip == 0 then
      barWidget.setTooltip("No tailnet devices")
    else
      barWidget.setTooltip(table.concat(tooltip, "\n"))
    end
  end
end

noctalia.state.watch("tailnet", function(value)
  state = value
  render()
end)
noctalia.setUpdateInterval(30000)
render()

function update()
  state = noctalia.state.get("tailnet") or state
  render()
end

function onClick()
  local revision = noctalia.state.get("refresh-tailnet") or 0
  noctalia.state.set("refresh-tailnet", revision + 1)
end
