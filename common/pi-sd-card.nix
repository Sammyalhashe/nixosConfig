{ lib, ... }:
{
  disko.devices = {
    disk = {
      sdcard = {
        type = "disk";
        device = "/dev/mmcblk0";
        content = {
          type = "table";
          format = "gpt";
          partitions = {
            firmware = {
              size = "512M";
              type = "EF00";
              priority = 1;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/firmware";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
