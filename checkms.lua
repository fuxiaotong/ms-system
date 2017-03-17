local cjson = require "cjson"
local lrucache = require 'mylrucache'

ngx.req.read_body()
local args, err = ngx.req.get_body_data()
if not args then
    ngx.log(ngx.ERR, "post data no find");
end

local data ={}
data = cjson.decode(args)
local barcodeInfo = lrucache.get("ms_" .. data['barcode'])
if barcodeInfo["switch"] == "0" then
    if barcodeInfo["userid"][data["userid"]] == nil then
        ngx.say("fail to buy the product, barcode:", data['barcode'])
    else
        ngx.say("success to buy the product, barcode:", data['barcode'])
    end
elseif barcodeInfo["switch"] == "1" then
   local userArr = cjson.decode(barcodeInfo["userid"])                                                                                                                                                                          
   if userArr[data["userid"]] == nil then
        ngx.say("please wait a minute to check again, barcode:", data['barcode'])
    else
        ngx.say("success to buy the product, barcode:", data['barcode'])
    end
else
    ngx.exit(500)
end

-- curl 127.0.0.1/api/checkms -d "{\"barcode\":\"123\",\"userid\":\"77\"}"
