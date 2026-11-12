{
  config,
  lib,
  ...
}:

let
  cfg = config.host;
  mining = cfg.moneroMiningAddress != "";
in
{
  config = lib.mkIf cfg.enableMonero (
    lib.mkMerge [
      {
        services.monero = {
          enable = true;
          prune = true;
          # P2Pool learns about new blocks from monerod's ZMQ feed.
          extraConfig = ''
            zmq-pub=tcp://127.0.0.1:${toString config.services.p2pool.zmqPort}
          '';
        };
      }

      (lib.mkIf mining {
        # mini suits a single CPU's hashrate: shares land often enough to get paid.
        services.p2pool = {
          enable = true;
          sidechain = "mini";
          walletAddress = cfg.moneroMiningAddress;
        };

        services.xmrig = {
          enable = true;
          settings = {
            autosave = false;
            cpu = {
              enabled = true;
              huge-pages = true;
              # About half the threads, so the desktop stays usable.
              max-threads-hint = 50;
            };
            opencl.enabled = false;
            cuda.enabled = false;
            # P2Pool's stratum server; payouts go to the address above, not to xmrig.
            pools = [ { url = "127.0.0.1:3333"; } ];
          };
        };

        systemd.services.xmrig = {
          after = [ "p2pool.service" ];
          wants = [ "p2pool.service" ];
          serviceConfig = {
            Nice = 19;
            CPUSchedulingPolicy = "idle";
          };
        };

        # RandomX's 2 GiB dataset plus per-thread scratchpads, in 2 MiB pages.
        boot.kernel.sysctl."vm.nr_hugepages" = 1280;
      })
    ]
  );
}
