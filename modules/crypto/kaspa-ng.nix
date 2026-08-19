{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Upstream publishes an amd64 .deb per release, which is far cheaper than
  # compiling rusty-kaspa from source. Unpacked with dpkg and relinked with
  # autoPatchelfHook -- the standard nixpkgs approach for prebuilt Debian
  # binaries.
  #
  # The binary only DT_NEEDEDs libstdc++/libgcc_s/libm/libc (autoPatchelfHook
  # resolves those). Everything graphical is dlopen'd at runtime and therefore
  # invisible to autoPatchelf, so it has to go on LD_LIBRARY_PATH via the
  # wrapper below. The list mirrors the actual `lib*.so*` strings in the binary
  # plus the .deb's `Depends: libglib2.0-0, libatk1.0-0, libgtk-3-0`.
  runtimeLibs = with pkgs; [
    libGL # libGL.so.1 / libEGL.so.1
    libglvnd
    libxkbcommon # + libxkbcommon-x11.so.0
    wayland # libwayland-client.so.0 / libwayland-egl.so.1
    dbus # libdbus-1.so.3
    glib
    atk
    gtk3
    xorg.libX11
    xorg.libX11.out
    xorg.libxcb
    xorg.libXcursor
    xorg.libXi
    xorg.libXrender
  ];

  kaspa-ng = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "kaspa-ng";
    version = "2.0.1";

    src = pkgs.fetchurl {
      url = "https://github.com/aspectron/kaspa-ng/releases/download/v${finalAttrs.version}/kaspa-ng_${finalAttrs.version}_amd64.deb";
      hash = "sha256-a0Ry7i8tjNlSxj61TotV8gZIWxtT+DOabGa5GzQuT/w=";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      makeWrapper
      copyDesktopItems
    ];

    # Satisfies the binary's DT_NEEDED entries.
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    # The .deb contains only /usr/bin/kaspa-ng -- no icon, no .desktop entry.
    installPhase = ''
      runHook preInstall
      install -Dm755 usr/bin/kaspa-ng $out/bin/kaspa-ng
      runHook postInstall
    '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "kaspa-ng";
        desktopName = "Kaspa NG";
        comment = "Kaspa desktop p2p node and wallet";
        exec = "kaspa-ng";
        # TODO: upstream ships no icon; point this at one if you source a .png.
        icon = "kaspa-ng";
        categories = [
          "Network"
          "Finance"
        ];
      })
    ];

    postFixup = ''
      wrapProgram $out/bin/kaspa-ng \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
    '';

    meta = {
      description = "Kaspa NG - desktop p2p node and wallet based on Rusty Kaspa";
      homepage = "https://github.com/aspectron/kaspa-ng";
      mainProgram = "kaspa-ng";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      # Upstream Cargo.toml declares `license = "PROPRIETARY"`.
      license = lib.licenses.unfree;
    };
  });
in
lib.mkIf config.host.enableKaspaNg {
  environment.systemPackages = [ kaspa-ng ];
}
