local BasePlugin = require "kong.plugins.base_plugin"

local http = require "httpclient"
local json = require "cjson"
local hc = http.new("httpclient.ngx_driver")
local requests = require "requests"

local JWT = BasePlugin:extend()
local kong = kong
local ipairs = ipairs
local pairs = pairs
local string = string
local tostring = tostring

JWT.VERSION = "0.1.0-10"
JWT.PRIORITY = 998

function JWT:new()
    JWT.super.new(self, "kong-auth-key-jwt-server")
end

local function sha256JWT(msg)
    local function band(int1, int2, int3, ...)
            int1 = int1 % 2^32
            int2 = int2 % 2^32
            local ret =
            ((int1%0x00000002>=0x00000001 and int2%0x00000002>=0x00000001 and 0x00000001) or 0)+
            ((int1%0x00000004>=0x00000002 and int2%0x00000004>=0x00000002 and 0x00000002) or 0)+
            ((int1%0x00000008>=0x00000004 and int2%0x00000008>=0x00000004 and 0x00000004) or 0)+
            ((int1%0x00000010>=0x00000008 and int2%0x00000010>=0x00000008 and 0x00000008) or 0)+
            ((int1%0x00000020>=0x00000010 and int2%0x00000020>=0x00000010 and 0x00000010) or 0)+
            ((int1%0x00000040>=0x00000020 and int2%0x00000040>=0x00000020 and 0x00000020) or 0)+
            ((int1%0x00000080>=0x00000040 and int2%0x00000080>=0x00000040 and 0x00000040) or 0)+
            ((int1%0x00000100>=0x00000080 and int2%0x00000100>=0x00000080 and 0x00000080) or 0)+
            ((int1%0x00000200>=0x00000100 and int2%0x00000200>=0x00000100 and 0x00000100) or 0)+
            ((int1%0x00000400>=0x00000200 and int2%0x00000400>=0x00000200 and 0x00000200) or 0)+
            ((int1%0x00000800>=0x00000400 and int2%0x00000800>=0x00000400 and 0x00000400) or 0)+
            ((int1%0x00001000>=0x00000800 and int2%0x00001000>=0x00000800 and 0x00000800) or 0)+
            ((int1%0x00002000>=0x00001000 and int2%0x00002000>=0x00001000 and 0x00001000) or 0)+
            ((int1%0x00004000>=0x00002000 and int2%0x00004000>=0x00002000 and 0x00002000) or 0)+
            ((int1%0x00008000>=0x00004000 and int2%0x00008000>=0x00004000 and 0x00004000) or 0)+
            ((int1%0x00010000>=0x00008000 and int2%0x00010000>=0x00008000 and 0x00008000) or 0)+
            ((int1%0x00020000>=0x00010000 and int2%0x00020000>=0x00010000 and 0x00010000) or 0)+
            ((int1%0x00040000>=0x00020000 and int2%0x00040000>=0x00020000 and 0x00020000) or 0)+
            ((int1%0x00080000>=0x00040000 and int2%0x00080000>=0x00040000 and 0x00040000) or 0)+
            ((int1%0x00100000>=0x00080000 and int2%0x00100000>=0x00080000 and 0x00080000) or 0)+
            ((int1%0x00200000>=0x00100000 and int2%0x00200000>=0x00100000 and 0x00100000) or 0)+
            ((int1%0x00400000>=0x00200000 and int2%0x00400000>=0x00200000 and 0x00200000) or 0)+
            ((int1%0x00800000>=0x00400000 and int2%0x00800000>=0x00400000 and 0x00400000) or 0)+
            ((int1%0x01000000>=0x00800000 and int2%0x01000000>=0x00800000 and 0x00800000) or 0)+
            ((int1%0x02000000>=0x01000000 and int2%0x02000000>=0x01000000 and 0x01000000) or 0)+
            ((int1%0x04000000>=0x02000000 and int2%0x04000000>=0x02000000 and 0x02000000) or 0)+
            ((int1%0x08000000>=0x04000000 and int2%0x08000000>=0x04000000 and 0x04000000) or 0)+
            ((int1%0x10000000>=0x08000000 and int2%0x10000000>=0x08000000 and 0x08000000) or 0)+
            ((int1%0x20000000>=0x10000000 and int2%0x20000000>=0x10000000 and 0x10000000) or 0)+
            ((int1%0x40000000>=0x20000000 and int2%0x40000000>=0x20000000 and 0x20000000) or 0)+
            ((int1%0x80000000>=0x40000000 and int2%0x80000000>=0x40000000 and 0x40000000) or 0)+
            ((int1>=0x80000000 and int2>=0x80000000 and 0x80000000) or 0)

            return (int3 and band(ret, int3, ...)) or ret
    end

    local function bxor(int1, int2, int3, ...)
            local ret =
            ((int1%0x00000002>=0x00000001 ~= (int2%0x00000002>=0x00000001) and 0x00000001) or 0)+
            ((int1%0x00000004>=0x00000002 ~= (int2%0x00000004>=0x00000002) and 0x00000002) or 0)+
            ((int1%0x00000008>=0x00000004 ~= (int2%0x00000008>=0x00000004) and 0x00000004) or 0)+
            ((int1%0x00000010>=0x00000008 ~= (int2%0x00000010>=0x00000008) and 0x00000008) or 0)+
            ((int1%0x00000020>=0x00000010 ~= (int2%0x00000020>=0x00000010) and 0x00000010) or 0)+
            ((int1%0x00000040>=0x00000020 ~= (int2%0x00000040>=0x00000020) and 0x00000020) or 0)+
            ((int1%0x00000080>=0x00000040 ~= (int2%0x00000080>=0x00000040) and 0x00000040) or 0)+
            ((int1%0x00000100>=0x00000080 ~= (int2%0x00000100>=0x00000080) and 0x00000080) or 0)+
            ((int1%0x00000200>=0x00000100 ~= (int2%0x00000200>=0x00000100) and 0x00000100) or 0)+
            ((int1%0x00000400>=0x00000200 ~= (int2%0x00000400>=0x00000200) and 0x00000200) or 0)+
            ((int1%0x00000800>=0x00000400 ~= (int2%0x00000800>=0x00000400) and 0x00000400) or 0)+
            ((int1%0x00001000>=0x00000800 ~= (int2%0x00001000>=0x00000800) and 0x00000800) or 0)+
            ((int1%0x00002000>=0x00001000 ~= (int2%0x00002000>=0x00001000) and 0x00001000) or 0)+
            ((int1%0x00004000>=0x00002000 ~= (int2%0x00004000>=0x00002000) and 0x00002000) or 0)+
            ((int1%0x00008000>=0x00004000 ~= (int2%0x00008000>=0x00004000) and 0x00004000) or 0)+
            ((int1%0x00010000>=0x00008000 ~= (int2%0x00010000>=0x00008000) and 0x00008000) or 0)+
            ((int1%0x00020000>=0x00010000 ~= (int2%0x00020000>=0x00010000) and 0x00010000) or 0)+
            ((int1%0x00040000>=0x00020000 ~= (int2%0x00040000>=0x00020000) and 0x00020000) or 0)+
            ((int1%0x00080000>=0x00040000 ~= (int2%0x00080000>=0x00040000) and 0x00040000) or 0)+
            ((int1%0x00100000>=0x00080000 ~= (int2%0x00100000>=0x00080000) and 0x00080000) or 0)+
            ((int1%0x00200000>=0x00100000 ~= (int2%0x00200000>=0x00100000) and 0x00100000) or 0)+
            ((int1%0x00400000>=0x00200000 ~= (int2%0x00400000>=0x00200000) and 0x00200000) or 0)+
            ((int1%0x00800000>=0x00400000 ~= (int2%0x00800000>=0x00400000) and 0x00400000) or 0)+
            ((int1%0x01000000>=0x00800000 ~= (int2%0x01000000>=0x00800000) and 0x00800000) or 0)+
            ((int1%0x02000000>=0x01000000 ~= (int2%0x02000000>=0x01000000) and 0x01000000) or 0)+
            ((int1%0x04000000>=0x02000000 ~= (int2%0x04000000>=0x02000000) and 0x02000000) or 0)+
            ((int1%0x08000000>=0x04000000 ~= (int2%0x08000000>=0x04000000) and 0x04000000) or 0)+
            ((int1%0x10000000>=0x08000000 ~= (int2%0x10000000>=0x08000000) and 0x08000000) or 0)+
            ((int1%0x20000000>=0x10000000 ~= (int2%0x20000000>=0x10000000) and 0x10000000) or 0)+
            ((int1%0x40000000>=0x20000000 ~= (int2%0x40000000>=0x20000000) and 0x20000000) or 0)+
            ((int1%0x80000000>=0x40000000 ~= (int2%0x80000000>=0x40000000) and 0x40000000) or 0)+
            ((int1>=0x80000000 ~= (int2>=0x80000000) and 0x80000000) or 0)

            return (int3 and bxor(ret, int3, ...)) or ret
    end

    local function bnot(int)
            return 4294967295 - int
    end

    local function rshift(int, by)
            int = int % 2^32
            local shifted = int / (2 ^ by)
            return shifted - shifted % 1
    end

    local function rrotate(int, by)
            int = int % 2^32
            local shifted = int / (2 ^ by)
            local fraction = shifted % 1
            return (shifted - fraction) + fraction * (2 ^ 32)
    end

    local k = {
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
            0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
            0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
            0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
            0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
            0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
            0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
            0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
            0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }


    local function str2hexa(s)
            local h = string.gsub(s, ".", function(c)
                    return string.format("%02x", string.byte(c))
            end)
            return h
    end

    local function num2s(l, n)
            local s = ""
            for i = 1, n do
                    local rem = l % 256
                    s = string.char(rem) .. s
                    l = (l - rem) / 256
            end
            return s
    end

    local function s232num(s, i)
            local n = 0
            for i = i, i + 3 do n = n*256 + string.byte(s, i) end
            return n
    end

    local function preproc(msg, len)
            local extra = 64 - ((len + 1 + 8) % 64)
            len = num2s(8 * len, 8)
            msg = msg .. "\128" .. string.rep("\0", extra) .. len
            return msg
    end

    local function initH256(H)
            H[1] = 0x6a09e667
            H[2] = 0xbb67ae85
            H[3] = 0x3c6ef372
            H[4] = 0xa54ff53a
            H[5] = 0x510e527f
            H[6] = 0x9b05688c
            H[7] = 0x1f83d9ab
            H[8] = 0x5be0cd19
            return H
    end

    local function digestblock(msg, i, H)
            local w = {}
            for j = 1, 16 do w[j] = s232num(msg, i + (j - 1) * 4) end
            for j = 17, 64 do
                    local v = w[j - 15]
                    local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
                    v = w[j - 2]
                    local s1 = bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
                    w[j] = w[j - 16] + s0 + w[j - 7] + s1
            end

            local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
            for i = 1, 64 do
                    local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                    local maj = bxor(band(a, b), band(a, c), band(b, c))
                    local t2 = s0 + maj
                    local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                    local ch = bxor (band(e, f), band(bnot(e), g))
                    local t1 = h + s1 + ch + k[i] + w[i]
                    h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
            end

            H[1] = (H[1] + a) % 2^32
            H[2] = (H[2] + b) % 2^32
            H[3] = (H[3] + c) % 2^32
            H[4] = (H[4] + d) % 2^32
            H[5] = (H[5] + e) % 2^32
            H[6] = (H[6] + f) % 2^32
            H[7] = (H[7] + g) % 2^32
            H[8] = (H[8] + h) % 2^32
    end

    msg = preproc(msg, #msg)
    local H = initH256({})
    for i = 1, #msg, 64 do digestblock(msg, i, H) end
    return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
            num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end


function sortKeyJWT( args )
    local index = {}
    local result = {}

    for _,v in ipairs(args) do
        table.insert(index, _)
    end
    table.sort( index )

    for _, v in ipairs(index) do
        table.insert( result, args[v] )
    end

    return result
end

function createSignatureJWT(key, args)

    local queryString = ""
    local sargs = sortKeyJWT(args)
    for _, v in ipairs(sargs) do
        queryString = queryString .. v
    end

    return sha256JWT(queryString..key)
end

function sendGetJWT(url, query)

    local count = 0

    for _,v in pairs(query) do
        count = count +1
    end

    local param = "?"
    local flag = 0
    for _,v in pairs(query) do
        flag = flag + 1

        if _ ~= nil and v ~= nil then
            if flag == count then
                param = param .. _ .. "=" .. v
            else
                param = param .. _ .. "=" .. v .. "&"
            end
        end

    end

    url = url .. param

    local res = requests.get(url)


    kong.log("jwt_request_status", tostring(url), res.status_code)


    if res.err ~= nil or res.status_code ~= 200 then
        return {}, {status = 500, message = "Error in processing"}
    end

    local body, error = res.json()

    kong.log("jwt_request_response", tostring(url), body, error)


    return {
        data = body
    }, nil
end


function sendPostJWT(url, body)


    -- local res = hc:post(url, "", {
    --     headers = {
    --         accept = "*/*",
    --         content_type = "application/x-www-form-urlencoded"
    --     },
    --     params = {baz = "qux"}
    -- })

    local res = hc:post("http://httpbin.org/post","", {headers = {accept = "application/json", ["user-agent"] = "lua httpclient unit tests"}, params = {baz = "qux"}})


    -- if res.err ~= nil or res.code ~=200 then
    --     return {}, {status = 500, message = "Error in processing"}
    -- end

    return {
        data = res,
        body = body,
        url = url
    }, nill
end

function doAuthenticationJWT(conf)

    local userToken = kong.request.get_header(tostring(conf.header_select_token))

    if not userToken then

        kong.log("jwt_not_user_token", userToken)
        return {}, {
            status = 401,
            message = "401 Unauthorized"
        }
    end

    local body = {
        [conf.body_send_token] = userToken
    }

    local signature = createSignatureJWT(conf.secret_key_signature_authentication, body)
    body.signature = signature

    local ok , errrq
    if string.lower(conf.method_authentication)  == "get" then

        ok, errrq = sendGetJWT(conf.url_authentication, body)

        if errrq ~= nil then
            kong.log("jwt_send_request_error", errrq)
            return {}, {
                status = 401,
                message= "401 Unauthorized"
            }
        end

    else
        kong.log("jwt_auth_error", " | not select method GET")
        return {}, {
            status = 401,
            message= "401 Unauthorized"
        }
    end

    if not ok.data[conf.param_token] then

        kong.log("jwt_auth_error", " | ", ok.data, " | ", conf.param_token ," | ", ok.data[conf.param_token])
        return {}, {
            status = 401,
            message= "401 Unauthorized"
        }
    end

    kong.service.request.set_header("authorization", "Bearer " .. ok.data[conf.param_token])

    return {}, nil
end



function JWT:access(conf)

    JWT.super.access(self)



    if not conf.header_select_token or not conf.url_authentication or not conf.method_authentication or not conf.body_send_token or not conf.param_token or not conf.secret_key_signature_authentication then

        kong.log("jwt_auth_error", " | not enough params")
        return kong.response.exit(401, {
            message = "401 Unauthorized",
            status = 401
        })
    end

    local ok, err = doAuthenticationJWT(conf)

    if err ~= nil then
        return kong.response.exit(err.status, {
            message = err.message,
            status = err.status
        })
    end
end

return JWT