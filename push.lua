local server = require "resty.websocket.server"
local redis = require 'resty.redis'
local cjson = require 'cjson'

local function cleanup()
    ngx.exit(499)
end

local function pushMsg(wb)
    local red = redis:new()
    red:set_timeout(0)
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.log(ngx.ERR, "faile to connect redis: ", err)
        return
    end
    local res, err = red:subscribe("news")
    a = 5
    while a>0 
    do
        local res, err = red:read_reply()
        -- for i,v in pairs(res) do
        --     ngx.log(ngx.ERR, "key:",i," value:",v)
        -- end
        bytes, err = wb:send_text(res[3])

        a = a-1
    end
end

local ok, err = ngx.on_abort(cleanup)

local wb, err = server:new{
    timeout = 5000,
    max_payload_len = 65535
}
if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    ngx.exit(400)
end

ngx.thread.spawn(pushMsg, wb)

while 1 do
    local data, typ, err = wb:recv_frame()
    if typ == "ping" then
        local bytes, err = wb:send_pong("in")
    end

    if typ == "close" then
        local bytes, err = wb:send_close(1000, "enough!")
        if not bytes then
            ngx.log(ngx.ERR, "failed to send the close frame: ", err)
        end
        ngx.exit(500)
    end
        
end

wb:set_timeout(0)
