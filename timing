
local handle = function ()
    local beanstalkd = require 'resty.beanstalkd'
    local redis = require 'resty.redis'
    local cjson = require 'cjson'

    local bean, err = beanstalkd:new()
    local red = redis:new()
    red:set_timeout(1000)
    bean:set_timeout(1000000000)
    while 1 do
        local ok, err = bean:connect()
        local ok, err = bean:watch("ms_queue")
        local id, data = bean:reserve()
        if not id then
            ngx.log(ngx.ERR, "fail to reserve: ", id)
            return
        else
            ngx.log(ngx.ERR, "success to reserve: ", id, " data: ", data)
            local value = cjson.decode(data)
            ngx.log(ngx.ERR, "data_table==>: ", value['barcode'])
            local ok, err = red:connect("127.0.0.1", 6379)
            if not ok then
                ngx.log(ngx.ERR, "faile to connect redis: ", err)
                return
            end
            local res, err = red:hmget("ms_barcode", "switch", "userid", "maxcount", "remain")
            
            for i,v in ipairs(res) do
                ngx.log(ngx.ERR, "key: ", i, " value: ", v)
            end

            local usertab = {}
            local userlist = ""
            local remainNum = 0;
            if res[1] == "1" then
                if res[2] == "" then
                    usertab[value['userid']] = 1
                else
                    usertab = cjson.decode(res[2])
                    usertab[value['userid']] = 1
                end

                userlist = cjson.encode(usertab)
                remainNum = tonumber(res[4])
                if remainNum == 1 then
                    remainNum = 0
                    res[1] = "0"
                else
                    remainNum = remainNum - 1
                end
                local setRes, err = red:hmset("ms_barcode", "switch", res[1], 
                                    "userid", userlist, "remain", tostring(remainNum))
                local ok, err = red:set_keepalive(10000, 100)
                if not ok then
                    ngx.log(ngx.ERR, "faile to set keepalive: ", err)
                end
            end

            local ok, err = bean:delete(id)
            if not ok then
                ngx.log(ngx.ERR, "fail to delete: ", id)
                return
            end
        end
        bean:set_keepalive(0,100) 
    end
end

local ok, err = ngx.timer.at(0, handle)

-- local delay = 5
-- local handler
-- handler = function()
--     local ok, err = ngx.timer.at(delay, handler)
--     if not ok then
--         ngx.log(ngx.ERR, "fail")
--         return
--     end
--     ngx.log(ngx.ERR, "succeed")
-- end

-- ngx.log(ngx.ERR, "ssss")
-- local ok, err = ngx.timer.at(0, handler)
-- if not ok then
--     return
-- end

-- hd_bean = function ()
--     local id, data = bean:reserve()
--     ngx.log(ngx.ERR, "======data:", data)
--     local ok, err = bean:bury(id)
-- end

-- local ok, err = ngx.timer.at(0, hd_bean)
-- if not ok then
--     return
-- end
