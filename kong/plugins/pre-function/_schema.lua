-- schema file for both the pre-function and post-function plugin
return function(plugin_name)

  local typedefs = require "kong.db.schema.typedefs"
  local loadstring = loadstring


  local function validate_function(fun)
    local func1, err = loadstring(fun)
    if err then
      return false, "error parsing " .. plugin_name .. ": " .. err
    end

    return true
  end

  local phase_function = { type = "string", required = false, custom_validator = validate_function }


  return {
    name = plugin_name,
    fields = {
      { consumer = typedefs.no_consumer },
      {
        config = {
          type = "record",
          fields = {
            {
              phase = {
                required = false,
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
            {
              functions = {
                required = true,
                default = {},
                type = "array",
                elements = {
                  type = "string",
                  custom_validator = validate_function
                },
              },
            },
            -- newer interface
            { init_worker = phase_function },
            { certificate = phase_function },
            { rewrite = phase_function },
            { access = phase_function },
            { header_filter = phase_function },
            { body_filter = phase_function },
            { log = phase_function },
            { api = phase_function },
          },
        },
      },
    },
  }

end
