local loadstring = loadstring
local insert = table.insert
local ipairs = ipairs


local config_cache = setmetatable({}, { __mode = "k" })


local PreFunction = {
  VERSION  = "0.1.0",
  PRIORITY = math.huge,
}


function PreFunction:access(config)
  local functions = config_cache[config]
  if not functions then
    functions = {}
    for _, fn_str in ipairs(config.functions) do
      insert(functions, loadstring(fn_str))
    end
    config_cache[config] = functions
  end

  for _, fn in ipairs(functions) do
    fn()
  end
end


return PreFunction
