```
http :8001/service name=example host=mockbin.org
http -f :8001/service/example/plugins name=pre-function config.functions=@transformer.lua config.functions=@transform.lua config.phase=body_filter
```
