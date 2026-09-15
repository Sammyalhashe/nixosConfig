{
  pkgs,
}:
let
  inherit (pkgs) lib;
  runtimeLibs = with pkgs; [
    libclang
    protobuf
  ];
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "zkas-rusty";
  version = "1.0.8";
  src = pkgs.fetchurl {
    url = "https://github.com/firecash/zkas-rusty/releases/download/zkas-v${finalAttrs.version}/zkas-zkas-v${finalAttrs.version}-linux-amd64.zip";
    hash = "asdfasdfasdfasdfasdfasdf";
  };
})
