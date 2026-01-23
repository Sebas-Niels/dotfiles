{ ... }:

{
  home.file.".config/wireplumber/main.lua.d/51-discord-keepalive.lua".text = ''
    rule = {
  matches = {
    {
      { "application.process.binary", "matches", ".*Discord.*" },
    },
  },
  apply_properties = {
    ["node.suspend-on-idle"] = false,
  },
}

table.insert(stream.rules, rule)

  '';
}
