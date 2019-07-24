local ctx = ngx.ctx

local cjson_decode = require("cjson").decode
local cjson_encode = require("cjson").encode

local insert = table.insert
local type = type
local find = string.find
local lower = string.lower
local match = string.match

local function is_json_body(content_type)
  return content_type and find(lower(content_type), "application/json", nil, true)
end


local function read_json_body(body)
  if body then
    local status, res = pcall(cjson_decode, body)
    if status then
      return res
    end
  end
end


-- key defaults to nil
function transform_data(conf, data, status, key)
  if (type(data) == "table") then
    -- Try to do a global match transform
    -- XXX: Better list detection?
    -- XXX: If code is exactly the same, can't we just use ipairs or pairs
    --      as an iterator?
    if data[1] then
      -- it's a list
      for k, v in ipairs(data) do
        local nk, thing = transform_data(conf, v, status, k)
        if k ~= nk then data[k] = nil end
        data[nk] = thing
      end
    else
      -- it's a dict
      for k, v in pairs(data) do
        local nk, thing = transform_data(conf, v, status, k)
        if k ~= nk then data[k] = nil end
        data[nk] = thing
      end
    end
  end

  return data_wrangler(key, data)
end


-- Initializes context here in case this plugin's access phase
-- did not run - and hence `rt_body_chunks` and `rt_body_chunk_number`
-- were not initialized
ctx.rt_body_chunks = ctx.rt_body_chunks or {}
ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

local chunk, eof = ngx.arg[1], ngx.arg[2]

-- if eof wasn't received keep buffering
if not eof then
  ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
  ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1
  ngx.arg[1] = nil
  return
end

-- last piece of body is ready; do the thing
local resp_body = table.concat(ctx.rt_body_chunks)


-- transform json
if is_json_body(ngx.header["content-type"]) then
  local json_body = read_json_body(resp_body)
  if json_body == nil then
    return
  end

  local err, transformed_data = transform_data(conf, json_body, ngx.status)

  if err then
    return
  end

  body = cjson_encode(transformed_data)
  ngx.arg[1] = body
end
