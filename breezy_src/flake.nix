{
  description = "Breezy Desktop for XR virtual workspaces";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    xr-driver = {
      url = "path:../xr_driver_src";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      xr-driver,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.breezy-vulkan = pkgs.stdenv.mkDerivation rec {
          pname = "breezy-vulkan";
          version = "git";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            meson
            ninja
            pkg-config
            glslang
          ];

          buildInputs = with pkgs; [
            vulkan-loader
            vulkan-headers
            libX11
            libXext
            wayland
            libdrm
            xr-driver.packages.${system}.default
          ];

          postPatch = ''
            # Inject XR driver includes and linking into vkBasalt
            sed -i "s|dependencies : \[x11_dep, reshade_dep\]|dependencies : [x11_dep, reshade_dep, cpp.find_library('xrealAirLibrary', dirs: '${
              xr-driver.packages.${system}.default
            }/lib'), cpp.find_library('Fusion', dirs: '${
              xr-driver.packages.${system}.default
            }/lib')]|" vulkan/modules/vkBasalt/src/meson.build
            sed -i "s|include_directories : vkBasalt_include_path|include_directories : [vkBasalt_include_path, include_directories('${
              xr-driver.packages.${system}.default
            }/include')]|" vulkan/modules/vkBasalt/src/meson.build
          '';

          preConfigure = ''
            cd vulkan/modules/vkBasalt
          '';

          mesonFlags = [
            "-Dwith_so=true"
            "-Dwith_json=true"
          ];

          installPhase = ''
                        runHook preInstall
                        mkdir -p $out/lib $out/share/vulkan/implicit_layer.d
                        cp src/libvkbasalt.so $out/lib/libbreezy_vulkan.so
                        
                        # Create the Vulkan layer JSON
                        cat <<EOF > $out/share/vulkan/implicit_layer.d/breezy_vulkan.json
            {
                "file_format_version" : "1.0.0",
                "layer" : {
                    "name": "VK_LAYER_BREEZY_VULKAN",
                    "type": "GLOBAL",
                    "library_path": "$out/lib/libbreezy_vulkan.so",
                    "api_version": "1.3.0",
                    "implementation_version": "1",
                    "description": "Breezy Vulkan XR Layer",
                    "functions": {
                        "vkNegotiateLoaderLayerInterfaceVersion": "vkNegotiateLoaderLayerInterfaceVersion"
                    },
                    "enable_environment": {
                        "ENABLE_VKBASALT": "1"
                    }
                }
            }
            EOF
                        runHook postInstall
          '';
        };

        packages.breezy-desktop = pkgs.python3Packages.buildPythonApplication rec {
          pname = "breezy-desktop";
          version = "git";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            meson
            ninja
            pkg-config
            wrapGAppsHook4
            gobject-introspection
            desktop-file-utils
            gettext
          ];

          buildInputs = with pkgs; [
            gtk4
            libadwaita
            python3Packages.pygobject3
            python3Packages.pydbus
            gst_all_1.gstreamer
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good
          ];

          propagatedBuildInputs = with pkgs; [
            python3Packages.pygobject3
            python3Packages.pydbus
          ];

          postPatch = ''
                        # Fix python path in meson.build
                        sed -i "s|python.find_installation('python3').full_path()|'${pkgs.python3}/bin/python3'|" ui/src/meson.build
                        
                        # Fix pkgdatadir logic in .in files to work with Nix store
                        sed -i "s|pkgdatadir = os.path.join(appdir, 'breezydesktop')|pkgdatadir = '$out/share/breezydesktop'|" ui/src/breezydesktop.in
                        sed -i "s|pkgdatadir = os.path.join(appdir, 'breezydesktop')|pkgdatadir = '$out/share/breezydesktop'|" ui/src/virtualdisplay.in
                        
                        # Ensure moduledir is also correct
                        sed -i "s|lib_dir = os.path.join(pkgdatadir, 'breezydesktop', 'lib')|lib_dir = os.path.join(pkgdatadir, 'lib')|" ui/src/breezydesktop.in
                        sed -i "s|lib_dir = os.path.join(pkgdatadir, 'breezydesktop', 'lib')|lib_dir = os.path.join(pkgdatadir, 'lib')|" ui/src/virtualdisplay.in

                        # Add missing sources to meson.build
                        sed -i "s|'window.py'|'window.py', 'virtualdisplayrow.py'|" ui/src/meson.build

                        # Patch verify.py to always succeed
                        echo "def verify_installation(): return True" > ui/src/verify.py

                        # Stub out ExtensionsManager to bypass GNOME checks
                        cat <<EOF > ui/src/extensionsmanager.py
            from gi.repository import GObject
            class ExtensionsManager(GObject.GObject):
                __gproperties__ = { "breezy-enabled": (bool, "Breezy Enabled", "", True, GObject.ParamFlags.READWRITE) }
                _instance = None
                @staticmethod
                def get_instance():
                    if ExtensionsManager._instance is None: ExtensionsManager._instance = ExtensionsManager()
                    return ExtensionsManager._instance
                def is_installed(self): return True
                def is_enabled(self): return True
                def do_get_property(self, prop): return True
                def do_set_property(self, prop, value): pass
            EOF
          '';

          preConfigure = ''
            cd ui
          '';

          format = "other";

          strictDeps = false;
        };

        packages.breezy-kwin = pkgs.stdenv.mkDerivation rec {
          pname = "breezy-kwin";
          version = "git";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            kdePackages.extra-cmake-modules
            pkg-config
            kdePackages.wrapQtAppsHook
          ];

          buildInputs = with pkgs; [
            kdePackages.kwin
            kdePackages.libplasma
            kdePackages.kconfig
            kdePackages.kconfigwidgets
            kdePackages.kcoreaddons
            kdePackages.kglobalaccel
            kdePackages.ki18n
            kdePackages.kcmutils
            kdePackages.kwindowsystem
            kdePackages.kxmlgui
            kdePackages.qtbase
            kdePackages.qtdeclarative
            kdePackages.qtquick3d
            libepoxy
            libxcb
            xr-driver.packages.${system}.default
          ];

          postPatch = ''
            cp VERSION kwin/
            mkdir -p kwin/src/xrdriveripc
            cp ui/modules/PyXRLinuxDriverIPC/xrdriveripc.py kwin/src/xrdriveripc/
            mkdir -p kwin/src/kcm
            cp ui/data/icons/hicolor/scalable/apps/com.xronlinux.BreezyDesktop.svg kwin/src/kcm/

            # Bypass XDG_SESSION_CLASS check — NixOS greetd doesn't always set it
            sed -i '/const QByteArray sessionClass/,/return;/{/return;/d}' kwin/src/breezydesktopeffect.cpp
            sed -i 's/if (sessionClass != "user")/if (false)/' kwin/src/breezydesktopeffect.cpp
          '';

          preConfigure = ''
            cd kwin
            # Fix hardcoded grep path for KWin effect.h
            sed -i "s|/usr/include/kwin/effect/effect.h|${pkgs.kdePackages.kwin.dev}/include/kwin/effect/effect.h|" CMakeLists.txt
          '';

          # Ensure Qt6 QML modules are found
          preBuild = ''
            export QML2_IMPORT_PATH=${pkgs.kdePackages.qtquick3d}/lib/qt-6/qml
          '';

          cmakeFlags = [
            "-DBUILD_TESTING=OFF"
            "-DQT_MAJOR_VERSION=6"
            "-DQT6_QUICK3D_QML_DIR=${pkgs.kdePackages.qtquick3d}/lib/qt-6/qml/QtQuick3D"
          ];
        };

        packages.default = self.packages.${system}.breezy-desktop;
      }
    );
}
