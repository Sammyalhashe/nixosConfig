{
  description = "Patched XRLinuxDriver with license check bypassed";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "xr-driver";
          version = "2.8.6-patched";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
            python3
            autoPatchelfHook
          ];

          buildInputs = with pkgs; [
            libusb1
            libevdev
            udev
            openssl
            json_c
            curl
            wayland
            glibc
            python3Packages.pyyaml
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
          ];

          noAuditTmpdir = true;

          postPatch = ''
                        # Disable the Rust-based subproject that requires internet during build
                        if [ -f modules/xrealInterfaceLibrary/interface_lib/CMakeLists.txt ]; then
                          # Just completely rewrite the problematic file with a simpler one
                          cat <<EOF > modules/xrealInterfaceLibrary/interface_lib/CMakeLists.txt
            cmake_minimum_required(VERSION 3.16)
            project(xrealAirLibrary C)
            set(CMAKE_C_STANDARD 17)
            find_package(json-c REQUIRED CONFIG)
            add_subdirectory(modules/hidapi)
            add_subdirectory(modules/Fusion/Fusion)
            set(PROTOCOL_SOURCES src/imu_protocol_hid.c)
            add_library(xrealAirLibrary src/crc32.c src/device.c src/device_imu.c src/device_mcu.c src/hid_ids.c \''${PROTOCOL_SOURCES})
            target_compile_options(xrealAirLibrary PRIVATE -fPIC)
            target_include_directories(xrealAirLibrary BEFORE PUBLIC include)
            target_include_directories(xrealAirLibrary SYSTEM BEFORE PRIVATE \''${CMAKE_CURRENT_SOURCE_DIR}/modules/hidapi \''${CMAKE_CURRENT_SOURCE_DIR}/modules/Fusion)
            target_link_libraries(xrealAirLibrary PRIVATE hidapi::hidapi json-c::json-c Fusion m)
            set(XREAL_AIR_INCLUDE_DIR \''${CMAKE_CURRENT_SOURCE_DIR}/include PARENT_SCOPE)
            set(XREAL_AIR_LIBRARY xrealAirLibrary PARENT_SCOPE)
            set(NREAL_AIR_INCLUDE_DIR \''${XREAL_AIR_INCLUDE_DIR} PARENT_SCOPE)
            set(NREAL_AIR_LIBRARY \''${XREAL_AIR_LIBRARY} PARENT_SCOPE)
            EOF
                          # Replace reference to xreal_one protocol with NULL
                          sed -i 's/&imu_protocol_xreal_one/NULL/g' modules/xrealInterfaceLibrary/interface_lib/src/hid_ids.c
                        fi

                        # Add libudev to CMakeLists.txt
                        sed -i '/pkg_check_modules(LIBUSB REQUIRED libusb-1.0)/a pkg_check_modules(LIBUDEV REQUIRED libudev)' CMakeLists.txt
                        sed -i "s/\''${LIBUSB_LIBRARIES}/\''${LIBUSB_LIBRARIES} \''${LIBUDEV_LIBRARIES}/" CMakeLists.txt
          '';

          preConfigure = ''
            mkdir -p include
            echo "start_date: 0" > custom_banner_config.yml

            # Mock cargo/rustc for the disabled subproject
            mkdir -p mock_bin
            echo "#!/bin/sh" > mock_bin/cargo
            echo "exit 0" >> mock_bin/cargo
            chmod +x mock_bin/cargo
            ln -s cargo mock_bin/rustc
            export PATH=$PWD/mock_bin:$PATH
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp xrDriver $out/bin/xr_driver
            cp ../bin/xr_driver_cli $out/bin/xr_driver_cli

            mkdir -p $out/lib
            cp -r ../lib/x86_64/* $out/lib/
            # Install built libraries
            find . -name "libxrealAirLibrary.a" -exec cp {} $out/lib/ \;
            find . -name "libFusion.a" -exec cp {} $out/lib/ \;
            find . -name "libhidapi-hidraw.so*" -exec cp -d {} $out/lib/ \;
            find . -name "libhidapi-libusb.so*" -exec cp -d {} $out/lib/ \;

            mkdir -p $out/lib/udev/rules.d
            cp ../udev/*.rules $out/lib/udev/rules.d/

            mkdir -p $out/include
            cp ../include/*.h $out/include/
            mkdir -p $out/include/sdks
            cp ../include/sdks/*.h $out/include/sdks/

            runHook postInstall
          '';

          appendRunpaths = [
            "$out/lib"
            "$out/lib/viture"
          ];
        };
      }
    );
}
