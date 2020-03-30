local helpers = require "spec.helpers"

local mock_one_fn = [[
  kong.response.clear_header("server")
]]


for _, method in ipairs({ "phase+functions", "phase=functions"}) do
  local function get_conf(phase, functions)
    if method == "phase+functions" then
      return { phase = phase, functions = functions }
    elseif method == "phase=functions" then
      return { [phase] = functions }
    end
  end

for _, plugin_name in ipairs({ "pre-function", "post-function" }) do

  describe("Plugin: " .. plugin_name .. string.format(" (by %s)", method) .. " header_filter", function()
    local client, admin_client

    setup(function()
      local bp, db = helpers.get_db_utils()

      assert(db:truncate())

      local service = bp.services:insert {
        name     = "service-1",
        host     = helpers.mock_upstream_host,
        port     = helpers.mock_upstream_port,
      }

      local route = bp.routes:insert {
        service = { id = service.id },
        hosts   = { "one." .. plugin_name .. ".com" },
      }

      bp.plugins:insert {
        name    = plugin_name,
        route   = { id = route.id },
        config  = get_conf("header_filter", { mock_one_fn }),
      }

      assert(helpers.start_kong({
        nginx_conf = "spec/fixtures/custom_nginx.template",
      }))
    end)

    teardown(function()
      helpers.stop_kong()
    end)

    before_each(function()
      client = helpers.proxy_client()
      admin_client = helpers.admin_client()
    end)

    after_each(function()
      if client and admin_client then
        client:close()
        admin_client:close()
      end
    end)


    describe("response transformation", function()
      it("using header_filters", function()
        local res = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "one." .. plugin_name .. ".com"
          }
        })

        assert.res_status(200, res)
        assert.same(nil, res.headers.Server)
      end)
    end)
  end)
end
end
