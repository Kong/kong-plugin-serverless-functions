-- handler file for both the pre-function and post-function plugin
return function(plugin_name, priority)
  local insert = table.insert
  

  local config_cache = setmetatable({}, { __mode = "k" })
  local ServerlessFunction = {}

  ServerlessFunction.PRIORITY = priority
  ServerlessFunction.VERSION = "0.3.0"


  function invoke(phase, config)
    if (config.phase ~= phase) then
      return
    end

    local functions = config_cache[config]
    if not functions then
      -- first call, go compile the functions
      functions = {}
      for _, fn_str in ipairs(config.functions) do
        local func1 = loadstring(fn_str)    -- load it
        local _, func2 = pcall(func1)       -- run it
        if type(func2) ~= "function" then
          -- old style (0.1.0), without upvalues
          insert(functions, func1)
        else
          -- this is a new function (0.2.0+), with upvalues
          insert(functions, func2)

          -- the first call to func1 above only initialized it, so run again
          func2()
        end
      end

      config_cache[config] = functions
      return  -- must return since we allready executed them
    end

    for _, fn in ipairs(functions) do
      fn()
    end
  end

  function ServerlessFunction:new()
    ServerlessFunction.super.new(self, "ServerlessFunction:" .. plugin_name)
  end

  function ServerlessFunction:init_worker(config)
    invoke("init_worker", config)
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
