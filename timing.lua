local consum_handle = function ()
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
            local res, err = red:hmget("ms_" .. value['barcode'], "switch", "userid", "maxcount", "remain")
            
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
                local setRes, err = red:hmset("ms_" .. value['barcode'], "switch", res[1], 
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
if ngx.worker.id() ~= -1 then
    local consum_timer_ok, err = ngx.timer.at(0, consum_handle)
end


local delay = 5
local update_handler
update_handler = function()
    local ok, err = ngx.timer.at(delay, update_handler)
    if not ok then
        ngx.log(ngx.ERR, "fail creat timer")
        return
    end
    local redis = require 'resty.redis'
    local cjson = require 'cjson'
    local red = redis:new()
    red:set_timeout(1000)
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.log(ngx.ERR, "faile to connect redis: ", err)
        return
    end
    local res, err = red:smembers("ms_list_barcode")

    local lruVal =  {}
    for i,v in ipairs(res) do
        local res_data, err = red:hgetall("ms_" .. v) 
        for k=1,#(res_data),2 do
            lruVal[res_data[k]] = res_data[k+1]
            -- ngx.log(ngx.ERR, "keyuuu: ", res_data[k], " value: ", res_data[k+1])
        end
        local lru = require 'mylrucache'
        -- ngx.log(ngx.ERR, ">>", "ms_" .. v)

        lru.set("ms_" .. v, lruVal)
        -- ngx.log(ngx.ERR, ">>>", cjson.encode(oo))
    end

    local ok, err = red:set_keepalive(10000, 100)
end

if ngx.worker.id() ~= -1 then
    local update_timer_ok, err = ngx.timer.at(0, update_handler)
    if not ok then
        return
    end
end
