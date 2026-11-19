final: prev:
let
  unwrapped = prev.zellij-unwrapped;
  # winit/glutin dlopen these at runtime for `zellij terminal`; nixpkgs leaves them off the RPATH.
  windowingLibs = with final; [
    libglvnd
    wayland
    libxkbcommon
    fontconfig
    libx11
    libxcursor
    libxi
  ];
  # Patching a copy of the cached build avoids recompiling zellij from source.
  zellijWithWindowing = final.runCommand "zellij-${unwrapped.version}" {
    nativeBuildInputs = [ final.patchelf ];
    inherit (unwrapped) version meta;
  } ''
    cp -r --no-preserve=mode ${unwrapped} $out
    chmod +x $out/bin/*
    patchelf --add-rpath ${final.lib.makeLibraryPath windowingLibs} $out/bin/zellij

    install -Dm644 ${unwrapped.src}/assets/dev.zellij.Zellij.desktop \
      $out/share/applications/dev.zellij.Zellij.desktop
    install -Dm644 ${unwrapped.src}/assets/dev.zellij.Zellij.metainfo.xml \
      $out/share/metainfo/dev.zellij.Zellij.metainfo.xml
    for size in 128 256 512; do
      install -Dm644 ${unwrapped.src}/zellij-utils/assets/icons/logo$size.png \
        $out/share/icons/hicolor/''${size}x$size/apps/dev.zellij.Zellij.png
    done
  '';
in
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  zellij = zellijWithWindowing;
}
