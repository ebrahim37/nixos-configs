local HEADSCALE_URL = "https://headscale.ebra.dev/api/v1/node"
local HEADSCALE_TOKEN_FILE = "/run/secrets/enc_priv_headscale_widget_token"
local DISCORD_URL = "https://widgets.ebra.dev/discord"
local DISCORD_TOKEN_FILE = "/run/secrets/enc_priv_discord_widget_token"
local POLL_INTERVAL_MS = 30000

local headscalePending = false
local discordPending = false

local function readToken(path)
  local token, err = noctalia.readFile(path)
  if token == nil then
    return nil, err or "could not read token"
  end

  token = noctalia.string.trim(token)
  if token == "" then
    return nil, "token is empty"
  end

  return token, nil
end

local function ipSortValue(peer)
  local ip = peer.ip or ""
  local lastOctet = string.match(ip, "(%d+)$")
  return tonumber(lastOctet) or math.huge
end

local function pollTailnet()
  if headscalePending then
    return
  end

  local token, tokenError = readToken(HEADSCALE_TOKEN_FILE)
  if token == nil then
    noctalia.state.set("tailnet", {
      status = "error",
      message = tokenError,
      peers = {},
      updatedAt = os.time(),
    })
    return
  end

  headscalePending = true
  local accepted = noctalia.http({
    url = HEADSCALE_URL,
    headers = {
      "Accept: application/json",
      "Authorization: Bearer " .. token,
    },
  }, function(response)
    headscalePending = false
    if not response.ok or response.status < 200 or response.status >= 300 then
      noctalia.state.set("tailnet", {
        status = "error",
        message = "HTTP " .. tostring(response.status or 0),
        peers = {},
        updatedAt = os.time(),
      })
      return
    end

    local decoded, decodeError = noctalia.json.decode(response.body)
    if decoded == nil or type(decoded.nodes) ~= "table" then
      noctalia.state.set("tailnet", {
        status = "error",
        message = decodeError or "response has no nodes array",
        peers = {},
        updatedAt = os.time(),
      })
      return
    end

    local peers = {}
    for _, node in ipairs(decoded.nodes) do
      local name = node.givenName or node.name or "unknown"
      if name ~= "headplane-agent" then
        local ip = ""
        if type(node.ipAddresses) == "table" and node.ipAddresses[1] ~= nil then
          ip = tostring(node.ipAddresses[1])
        end
        table.insert(peers, {
          name = tostring(name),
          ip = ip,
          connected = node.online == true,
        })
      end
    end

    table.sort(peers, function(a, b)
      local aValue = ipSortValue(a)
      local bValue = ipSortValue(b)
      if aValue == bValue then
        return a.name < b.name
      end
      return aValue < bValue
    end)

    noctalia.state.set("tailnet", {
      status = "ok",
      peers = peers,
      updatedAt = os.time(),
    })
  end)

  if not accepted then
    headscalePending = false
    noctalia.state.set("tailnet", {
      status = "error",
      message = "request queue is full",
      peers = {},
      updatedAt = os.time(),
    })
  end
end

local function pollDiscord()
  if discordPending then
    return
  end

  local token, tokenError = readToken(DISCORD_TOKEN_FILE)
  if token == nil then
    noctalia.state.set("discord", {
      status = "error",
      message = tokenError,
      peers = {},
      updatedAt = os.time(),
    })
    return
  end

  discordPending = true
  local accepted = noctalia.http({
    url = DISCORD_URL,
    headers = {
      "Accept: application/json",
      "Authorization: " .. token,
    },
  }, function(response)
    discordPending = false
    if not response.ok or response.status < 200 or response.status >= 300 then
      noctalia.state.set("discord", {
        status = "error",
        message = "HTTP " .. tostring(response.status or 0),
        peers = {},
        updatedAt = os.time(),
      })
      return
    end

    local decoded, decodeError = noctalia.json.decode(response.body)
    if decoded == nil or type(decoded) ~= "table" then
      noctalia.state.set("discord", {
        status = "error",
        message = decodeError or "response is not an array",
        peers = {},
        updatedAt = os.time(),
      })
      return
    end

    local peers = {}
    for _, peer in ipairs(decoded) do
      table.insert(peers, {
        name = tostring(peer.name or "unknown"),
        isStreaming = peer.isStreaming == true,
        isMutedOrDeafened = peer.isMutedOrDeafened == true,
      })
    end

    noctalia.state.set("discord", {
      status = "ok",
      peers = peers,
      updatedAt = os.time(),
    })
  end)

  if not accepted then
    discordPending = false
    noctalia.state.set("discord", {
      status = "error",
      message = "request queue is full",
      peers = {},
      updatedAt = os.time(),
    })
  end
end

local function poll()
  pollTailnet()
  pollDiscord()
end

noctalia.state.set("tailnet", { status = "loading", peers = {} })
noctalia.state.set("discord", { status = "loading", peers = {} })
noctalia.state.watch("refresh", function()
  poll()
end)
noctalia.setUpdateInterval(POLL_INTERVAL_MS)
poll()

function update()
  poll()
end
