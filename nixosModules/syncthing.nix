{ config, ... }:
let 
  user="salhashemi2";
in
{
  services = {
    syncthing = {
      enable = false;
      user = "$user";
      dataDir = "/home/$user/Documents";
      configDir = "/home/$user/Documents/.config/syncthing";
    };
  };
}
