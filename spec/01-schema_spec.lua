local v = require("spec.helpers").validate_plugin_config_schema

local mock_fn_one = '("hello world!"):find("world")'
local mock_fn_two = 'local x = 1'
local mock_fn_three = 'local x = 1 return function() x = x + 1 end'
local mock_fn_invalid = 'print('
local mock_fn_invalid_return = 'return "hello-world"'


for _, plugin_name in ipairs({ "pre-function", "post-function" }) do

  for _, method in ipairs({ "functions", "phase=functions"}) do
    local function get_conf(functions)
      if method == "functions" then
        return { functions = functions }
      elseif method == "phase=functions" then
        return { access = functions }
      end
    end

    -- local function get_functions_from_error(err)
    --   if method == "functions" then
    --     return err.config.functions
    --   elseif method == "phase=functions" then
    --     return err.config.access
    --   end
    -- end


    describe("Plugin: " .. plugin_name .. string.format(" (by %s)", method) .. " schema", function()
    for _, u in ipairs({ 'on', 'sandbox' }) do describe(("untrusted_lua = '%s'"):format(u), function()
      local schema

      setup(function()
        schema = require("kong.plugins." .. plugin_name .. ".schema")
        _G.kong.configuration = {
          untrusted_lua = u,
        }

        spy.on(kong.log, "warn")
      end)

      teardown(function()
        kong.log.warn:revert()
      end)

      it("validates single function", function()
        local ok, err = v(get_conf { mock_fn_one }, schema)

        assert.truthy(ok)
        assert.falsy(err)
      end)

      it("error in function is not triggered during validation", function()
        local ok, err = v(get_conf {
            [[error("should never happen")]],
        }, schema)

        assert.truthy(ok)
        assert.falsy(err)
      end)

      it("validates single function with upvalues", function()
        local ok, err = v(get_conf{ mock_fn_three }, schema)

        assert.truthy(ok)
        assert.falsy(err)
      end)

      it("validates multiple functions", function()
        local ok, err = v(get_conf { mock_fn_one, mock_fn_two }, schema)

        assert.truthy(ok)
        assert.falsy(err)
      end)

      it("a valid chunk with an invalid return type", function()
        local ok, err = v(get_conf { mock_fn_invalid_return }, schema)

        assert.truthy(ok)
        assert.falsy(err)
      end)


      if method == "functions" then
        it("throws a log warning when being used", function()
          v(get_conf { mock_fn_one, mock_fn_two }, schema)
          assert.spy(kong.log.warn).was_called.with(string.format("[%s] 'config.functions' will be deprecated in favour of 'config.access'", plugin_name))
        end)
      end

      describe("errors", function()
        it("with an invalid function", function()
          local ok, err = v(get_conf { mock_fn_invalid }, schema)

          assert.falsy(ok)
          -- XXX
          -- assert.equals("error parsing " .. plugin_name .. ": [string \"print(\"]:1: unexpected symbol near '<eof>'", get_functions_from_error(err)[1])
          assert.not_nil(err)
        end)

        it("with a valid and invalid function", function()
          local ok, err = v(get_conf { mock_fn_one, mock_fn_invalid }, schema)

          assert.falsy(ok)
          -- XXX
          -- assert.equals("error parsing " .. plugin_name .. ": [string \"print(\"]:1: unexpected symbol near '<eof>'", get_functions_from_error(err)[2])
          assert.not_nil(err)
        end)
      end)
    end) end end)
  end
end
