local loadstring = loadstring

local function validate_function(fun)
  local func1, err = loadstring(fun)
  if err then
    return false, "Error parsing nless: " .. err
  end

  local success, func2 = pcall(func1)

  if not success or func2 == nil then
    -- the code IS the handler function
    return true
  end

  -- the code RETURNED the handler function
  if type(func2) == "function" then
    return true
  end

  -- the code returned something unknown
  return false, "Bad return value from nless function, " ..
                "expected function type, got " .. type(func2)
end

local phase_field = { required = false, type = "string", custom_validator = validate_function }

return {
  name = "nless",
  fields = {
    { config = {
      type = "record",
      fields = {
        { access = phase_field },
      }
    }
  } }
}
