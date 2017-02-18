local beanstalkd = require "resty.beanstalkd"
local cjson = require "cjson"

-- local redis = require "resty.redis"
-- local red = redis:new()

-- red:set_timeout(1000)  -- 1s

-- local ok, err = red:connect("127.0.0.1", 6379)
-- if not ok then
--     ngx.say("failed to connect: ", err)
-- end

-- ok, err = red:set("dog", "an animal")
-- local res, err = red:get("dog")
-- ngx.say("dog:", res)

ngx.req.read_body()
local args, err = ngx.req.get_body_data()
if not args then
    ngx.log(ngx.ERR, "post data no find");
end

ngx.say(args)


ngx.say("----------------------")

local bean, err = beanstalkd:new()
if not bean then
   ngx.say("fail--")
end
local ok, err = bean:connect()

local ok, err = bean:use("ms_queue")
if not ok then
    ngx.say("-----")
end
local id, err = bean:put(args)
if not id then
    ngx.say("err")
end

bean:set_keepalive(0, 100)
