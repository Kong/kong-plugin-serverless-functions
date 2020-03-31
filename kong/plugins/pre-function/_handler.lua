-- handler file for both the pre-function and post-function plugin
return function(plugin_name, priority)
  local insert = table.insert

  local config_cache = setmetatable({}, { __mode = "k" })

  local ServerlessFunction = {
    PRIORITY = priority,
    VERSION = "0.3.1",
  }

  -- !!! Note thins function also executes fn_str !!!
  -- If we support both old style (0.1.0) and new style (0.2.0+), this
  -- early execution is mandatory, since it's our check for it.
  local function load_function(fn_str)
    local func1 = loadstring(fn_str)    -- load it
    local _, func2 = pcall(func1)       -- run it
    if type(func2) ~= "function" then
      -- old style (0.1.0), without upvalues
      return func1
    else
      -- this is a new function (0.2.0+), with upvalues
      -- the first call to func1 above only initialized it, so run again
      func2()
      return func2
    end
  end

  local function invoke(phase, config)
    if not config then
      return
    end

    local cache = config_cache[config] or {}

    -- old style phase support. config.functions apply to config.phase
    if config.phase == phase then
      if #config.functions > 0 and not cache.functions then
        cache.functions = {}
        for _, fn_str in ipairs(config.functions) do
          insert(cache.functions, load_function(fn_str))
        end

        config_cache[config] = cache

        return  -- must return since we already executed them
      end
    end

    -- new style phase support: config.access = { some, functions }
    if #config[phase] > 0 and not cache[phase] then
      cache[phase] = {}
      for _, fn_str in ipairs(config[phase]) do
        insert(cache[phase], load_function(fn_str))
      end

      config_cache[config] = cache

      return  -- must return since we already executed them
    end

    -- XXX Should we support both ?
    local functions = (
      config.phase == phase and #config.functions > 0 and cache.functions
    ) or (
      #config[phase] > 0 and cache[phase]
    ) or {}

    for _, fn in ipairs(functions) do
      fn()
    end
  end

  function ServerlessFunction:new()
    ServerlessFunction.super.new(self, "ServerlessFunction:" .. plugin_name)
  end

  function ServerlessFunction:certificate(config)
    invoke("certificate", config)
  end

  function ServerlessFunction:rewrite(config)
    invoke("rewrite", config)
  end

  function ServerlessFunction:access(config)
    invoke("access", config)
  end

  function ServerlessFunction:header_filter(config)
    invoke("header_filter", config)
  end

  function ServerlessFunction:body_filter(config)
    invoke("body_filter", config)
  end

  function ServerlessFunction:log(config)
    invoke("log", config)
  end


  return ServerlessFunction
end
