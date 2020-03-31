-- schema file for both the pre-function and post-function plugin
return function(plugin_name)

  local typedefs = require "kong.db.schema.typedefs"
  local loadstring = loadstring


  local function validate_function(fun)
    local _, err = loadstring(fun)
    if err then
      return false, "error parsing " .. plugin_name .. ": " .. err
    end

    return true
  end


  local phase_function = {
    type = "string",
    required = false,
    custom_validator = validate_function
  }

  local phase_functions = {
    required = true,
    default = {},
    type = "array",
    elements = phase_function
  }

  return {
    name = plugin_name,
    fields = {
      { consumer = typedefs.no_consumer },
      {
        config = {
          type = "record",
          fields = {
            -- old interface
            {
              phase = {
                required = false,
                default = "access",
                type = "string",
                one_of = {
                  "init_worker",
                  "certificate",
                  "rewrite",
                  "access",
                  "header_filter",
                  "body_filter",
                  "log"
                },
              },
            },
            { functions = phase_functions },
            -- new interface
            { certificate = phase_functions },
            { rewrite = phase_functions },
            { access = phase_functions },
            { header_filter = phase_functions },
            { body_filter = phase_functions },
            { log = phase_functions },
          },
        },
      },
    },
  }

end
