{ lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      glaze = prev.glaze.overrideAttrs (old: rec {
        version = "7.2.0";
        src = prev.fetchFromGitHub {
          owner = "stephenberry";
          repo = "glaze";
          tag = "v${version}";
          hash = "sha256-f3NVRi3SXKo42hn0WCw7JsOK3EkdOVJIcuzhPorKjFY=";
        };
      });
    })
  ];
}
