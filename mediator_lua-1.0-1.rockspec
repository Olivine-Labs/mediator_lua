package = "mediator_lua"
version = "1.0-1"
source = {
  url = "https://github.com/downloads/Olivine-Labs/mediator_lua/mediator_lua-1.0.tar.gz"
}
description = {
  summary = "Event handling through channels",
  detailed = [[
    mediator_lua allows you to subscribe and publish to a central object so
    you can decouple function calls in your application. It's as simple as
    mediator:subscribe("channel", function). Supports namespacing, predicates,
    and more.
  ]],
  homepage = "http://olivinelabs.com/mediator_lua/",
  license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
   modules = {
    mediator_lua = "mediator.lua"
  }
}
