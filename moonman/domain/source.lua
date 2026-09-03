--- Where manifest source paths live on the network.
---
--- Pure URL composition: the ref is supplied by config rather than baked into
--- the manifest, so a single manifest works from any branch, tag, or commit.
local source = {}

local RAW_HOST = "https://raw.githubusercontent.com"

--- Build the raw URL for a repo-relative path.
---@param repo string "owner/name"
---@param ref string branch, tag, or commit sha
---@param sourcePath string path relative to the repository root
---@return string
function source.url(repo, ref, sourcePath)
  return ("%s/%s/%s/%s"):format(RAW_HOST, repo, ref, sourcePath)
end

--- The URL of the manifest itself.
---@param config table
---@return string
function source.manifestUrl(config)
  return source.url(config.repo, config.ref, config.manifest_path)
end

--- Human-readable description of where a config points.
---@param config table
---@return string
function source.describe(config)
  return config.repo .. "@" .. config.ref
end

return source
