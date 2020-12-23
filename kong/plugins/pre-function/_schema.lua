-- schema file for both the pre-function and post-function plugin
return function(plugin_name)

  local Schema = require "kong.db.schema"
  local typedefs = require "kong.db.schema.typedefs"

  local functions_deprecated = "[%s] 'config.functions' will be deprecated in favour of 'config.access'"

  local sandbox_helpers = require "kong.tools.sandbox_helpers"


  local phase_functions = Schema.define {
    required = true,
    default = {},
    type = "array",
    elements = {
      type = "string",
      required = false,
      -- Checks for valid lua, does not execute
      custom_validator = sandbox_helpers.validate_safe,
    }
  }

  return {
    name = plugin_name,
    fields = {
      { consumer = typedefs.no_consumer },
      {
        config = {
          type = "record",
          fields = {
            -- old interface. functions are always on access phase
            { functions = phase_functions {
              custom_validator = function(v)
                if #v > 0 then
                  kong.log.warn(functions_deprecated:format(plugin_name))
                end

                return true
              end,
            } },
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
    entity_checks = {
      { mutually_exclusive_sets = {
        set1 = { "config.functions" },
        set2 = { "config.access" },
      } },
      { at_least_one_of = {
        "config.functions",
        "config.certificate",
        "config.rewrite",
        "config.access",
        "config.header_filter",
        "config.body_filter",
        "config.log",
      } },
    },
  }
end
