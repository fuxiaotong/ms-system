local _M = {}

local lrucache = require 'resty.lrucache.pureffi'
local c, err = lrucache.new(200)
if not c then
    return error("failed to create the cache: " .. (err or "unknown"))
end

function _M.set(key, val)
    c:set(key, val);
end

function _M.get(key)
    local data = {}
    data = c:get(key)
    return data
end

return _M
