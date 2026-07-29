{pkgs} :

pkgs.writeShellScriptBin "sn-install"
# bash
''
nix shell nixpkgs#android-tools -c adb install $1
''
