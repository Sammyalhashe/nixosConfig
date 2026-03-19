{ pkgs, lib, ... }:

let
  xr-driver = pkgs.stdenv.mkDerivation rec {
    pname = "xr-driver";
    version = "2.8.6-patched";

    src = ../../xr_driver_src;

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      python3
      rustc
      cargo
    ];

    buildInputs = with pkgs; [
      libusb1
      libevdev
      openssl
      json_c
      curl
      wayland
      python3Packages.pyyaml
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
    ];

    postPatch = ''
      # Disable the Rust-based subproject that requires internet during build
      sed -i 's/add_subdirectory("\''${XOD_ROOT}"/# \0/' modules/xrealInterfaceLibrary/interface_lib/CMakeLists.txt
      sed -i 's/target_link_libraries(xrealAirLibrary PRIVATE xreal_one_driver)/# \0/' modules/xrealInterfaceLibrary/interface_lib/CMakeLists.txt
    '';

    preConfigure = ''
      mkdir -p include
      echo "start_date: 0" > custom_banner_config.yml

      mkdir -p bin
      echo "#!/bin/sh" > bin/cargo
      echo "exit 0" >> bin/cargo
      chmod +x bin/cargo
      ln -s cargo bin/rustc
      export PATH=$PWD/bin:$PATH
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp xrDriver $out/bin/xr_driver
      mkdir -p $out/lib/udev/rules.d
      cp ../udev/*.rules $out/lib/udev/rules.d/
      runHook postInstall
    '';
  };
in
{
  environment.systemPackages = [ xr-driver ];

  services.udev.packages = [ xr-driver ];

  boot.kernelModules = [ "uinput" ];
}
