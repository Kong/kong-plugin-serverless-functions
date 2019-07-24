function data_wrangler(key, data)
  if (type(data) ~= "table") then
    data = 42
    -- return key, 42
  end


  if key == "clientIPAddress" then
    data = "0.0.0.0"
  end

  -- if key and key == "postData" then
  --   key = "awesomeData"
  -- end

  -- if key and key == "headers" then
  --   data["hello-world"] = "what's up"
  -- end
  -- -- if key and key == "postData" then
  -- --   data.mimeType = 42
  -- -- end
  -- --
  -- if key then
  --   key = key .. "-magic"
  -- end
  -- if key then
  --   key = key .. "-magic"
  -- end
  --
  -- if key and key == "postData" then
  --   key = "postData-whatever"
  --   if data and data.text then
  --     data.text = "Hello Fast Track"
  --   end
  -- end

  return key, data
end

