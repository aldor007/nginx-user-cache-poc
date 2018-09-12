local re = ngx.re

ngx.var.no_cache = '0'
local user_id = ngx.var.cookie_session
if user_id == nil then
   return
end
 
local path = ngx.var.uri
-- dziala na okreslonych sciezkac
if not re.match(path, '^/(internal)(.*)', 'ijo') then
   return
end
 
local http = require "resty.http"
local httpc = http.new()
 
-- timeouts do api
httpc:set_timeouts(50, 450, 450)
httpc:connect('localhost', 80)
 
local res, err = httpc:request_uri('http://127.0.0.1/api?userid=' .. user_id .. '&path=' .. path)
 
if not res then
-- in case of error no cache response
   ngx.log(ngx.ERR, 'request to lambda failed ' .. err )
   ngx.var.no_cache = '1'
   return
end
 
if res.status ~= 200 then
   ngx.log(ngx.ERR, 'request to lambda invalid status ' .. res.status)
   ngx.var.no_cache = '1'
   return
end
 
local info = res.headers['x-cache-api-info']
if info == 'no-cache' then
   ngx.var.no_cache = '1'
   return
end
 
if res.headers['x-cache-api-cache-param'] == nil then
   ngx.var.no_cache = '1'
   return
end
 
if info == 'no-change-cache-key' then
   return
end
 
 
-- update cache key
local cache_key = ngx.var.cache_key
ngx.var.cache_key = cache_key .. '!' .. res.headers['x-cache-api-cache-param']

