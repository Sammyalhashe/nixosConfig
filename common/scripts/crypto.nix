{ pkgs }:

pkgs.writeShellScriptBin "crypto" ''
  echo "test-nix" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat

  DEFAULT_CRYPTO="ETH"

  function _get_crypto_price () {
      if [[ -z "$1" ]]; then
          local crypto="$DEFAULT_CRYPTO"
      else
          local crypto="$1"
      fi
      if [[ -z "$2" ]]; then
          avg_price=`${pkgs.curl}/bin/curl -s rate.sx/$crypto | grep avg | awk '{print $2}' | tr -d '[:space:]'`
          echo "$avg_price" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
      else
          avg_price=`${pkgs.curl}/bin/curl -s rate.sx/$crypto | grep avg | awk '{print $2}' | tr -d '[:space:]'`
          read -p "$avg_price" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
      fi
  }

  _get_crypto_price "$1" "$2"
''
