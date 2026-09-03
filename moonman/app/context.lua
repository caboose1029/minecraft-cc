--- Composition root: wires the platform adapters to configuration and gives
--- commands one object to work against.
---
--- Swapping the ports table is all it takes to drive the app from a test
--- harness instead of a real computer.
local configModule = require("moonman.app.config")
local manifestModule = require("moonman.domain.manifest")
local sourceModule = require("moonman.domain.source")

local context = {}

local Context = {}
Context.__index = Context

--- Default ports, backed by the real CC APIs.
---@return table
function context.defaultPorts()
  return {
    http = require("moonman.platform.http"),
    fs = require("moonman.platform.fs"),
    log = require("moonman.platform.log"),
    json = require("moonman.platform.json"),
  }
end

---@param ports table|nil
---@return table
function context.new(ports)
  ports = ports or context.defaultPorts()
  local cfg, warning = configModule.load(ports)
  if warning then
    ports.log.warn("moonman: " .. warning)
  end
  return setmetatable({
    ports = ports,
    http = ports.http,
    fs = ports.fs,
    log = ports.log,
    json = ports.json,
    config = cfg,
  }, Context)
end

--- Fetch, decode, and validate the manifest. Memoised per run.
---@return table|nil manifest, string|nil err
function Context:manifest()
  if self._manifest ~= nil then
    return self._manifest
  end
  local url = sourceModule.manifestUrl(self.config)
  local body, err = self.http.get(url)
  if body == nil then
    return nil, "could not fetch manifest: " .. err
  end
  local decoded, decodeErr = self.json.decode(body)
  if decoded == nil then
    return nil, "manifest at " .. url .. " is not valid JSON: " .. decodeErr
  end
  local model, parseErr = manifestModule.parse(decoded)
  if model == nil then
    return nil, parseErr
  end
  self._manifest = model
  return model
end

--- Resolve a manifest source path to its download URL under the active ref.
---@param sourcePath string
---@return string
function Context:url(sourcePath)
  return sourceModule.url(self.config.repo, self.config.ref, sourcePath)
end

--- Where this context points, for display.
---@return string
function Context:origin()
  return sourceModule.describe(self.config)
end

return context
