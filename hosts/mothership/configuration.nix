{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  user = "salhashemi2";
in
{
  imports = [
    ./hardware-configuration.nix
    ./bluetooth.nix
    inputs.home-manager.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    ../../common/home-manager-config.nix
    # Import the new modular LLM services
    ../../nixosModules/llm-services
  ];

  host.useOmarchy = lib.mkDefault false;
  host.greetd = true;

  specialisation = {
    server.configuration = {
      system.nixos.tags = [ "server" ];
      host.greetd = lib.mkForce false;
      host.isHeadless = true;
    };
  };
  host.homeManagerHostname = "default";
  host.fallbackNameservers = [ "11.125.37.1" ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amd_iommu=off"
      "iommu=pt"
      "amdgpu.gpu_recovery=1"
      "amdgpu.cwsr_enable=0"
      "initcall_blacklist=simpledrm_platform_driver_init"

      # --- STRIX HALO HARDWARE FIXES ---
      "amdgpu.sg_display=0" # Fixes display-linked memory stalls
      "amdgpu.dcfeaturemask=0x8" # DISABLES PSR (Fixes your REG_WAIT error)
      "amdgpu.abmlevel=0" # Prevents panel backlight interference
      "amdgpu.runpm=0" # Keeps GPU awake for ROCm discovery

      # Memory Aperture (Working Baseline)
      "ttm.pages_limit=30000000"
      "ttm.page_pool_size=30000000"
      "amdgpu.gartsize=122880"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.overcommit_memory" = 1;
      "vm.nr_hugepages" = 1024;
      "net.ipv4.tcp_fastopen" = 3;
    };
  };

  # Essential environment variables for GFX 11.5.1
  environment.variables = {
    HSA_OVERRIDE_GFX_VERSION = "11.5.1";
    RADV_PERFTEST = "aco";
  };

  # Enable the Modular LLM Services
  services.llm-services.gpt-oss.enable = false;
  services.llm-services.qwen-coder.enable = true;

  powerManagement.cpuFreqGovernor = "performance";

  # 4. Update Open WebUI to talk to Llama.cpp
  services.open-webui = {
    enable = true;
    port = 8080;
    environment = {
      OPENAI_API_BASE_URL = "http://127.0.0.1:8012/v1";
      OPENAI_API_KEY = "none";
      ENABLE_OLLAMA_API = "False";
      PYTHONPATH =
        let
          pyPkgs = pkgs.python313Packages;
        in
        lib.makeSearchPath "lib/python3.13/site-packages" [
          pyPkgs.requests
          pyPkgs.beautifulsoup4
          pyPkgs.markdownify
          pyPkgs.lxml
          pyPkgs.tiktoken
          pyPkgs.aiohttp
          pyPkgs.loguru
          pyPkgs.orjson
          pyPkgs.rank-bm25
          pyPkgs.scikit-learn
          pyPkgs.scipy
          pyPkgs.torch
          pyPkgs.sentence-transformers
          pyPkgs.transformers
          pyPkgs.regex
        ];
    };
  };

  # Declarative Model Management
  systemd.services.model-downloader = {
    description = "Download and verify GGUF models in background";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.aria2
      pkgs.coreutils
      pkgs.systemd
    ];
    script = ''
      MODEL_DIR="/var/lib/llama-cpp-models"
      mkdir -p "$MODEL_DIR"
      download_model() {
        local name=$1
        local url=$2
        local target="$MODEL_DIR/$name"
        if [ ! -f "$target" ]; then
          aria2c -x16 -s16 -j5 -c --dir="$MODEL_DIR" -o "$name" "$url"
        fi
      }
      download_model "qwen_32b.gguf" "https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/qwen2.5-coder-32b-instruct-q4_k_m.gguf"
    '';
    serviceConfig = {
      Type = "simple";
      User = "salhashemi2";
      Nice = 10;
      Restart = "on-failure";
      RestartSec = "30s";
      StateDirectory = "llama-cpp-models";
      StateDirectoryMode = "0755";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
    ];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 20;
  };

  system.autoUpgrade.enable = false;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking = {
    hostName = "mothership";
    networkmanager.enable = true;
    nameservers = [
      "11.125.37.99"
      "11.125.37.1"
      "1.1.1.1"
    ];
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    options = "caps:swapescape";
  };

  users.users.${user} = {
    isNormalUser = true;
    description = "Sammy Al Hashemi";
    extraGroups = [
      "networkmanager"
      "docker"
      "wheel"
    ];
  };

  programs.mango.enable = true;
  services.getty.autologinUser = "${user}";
  nixpkgs.config.allowUnfree = true;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  environment.systemPackages = with pkgs; [
    git
    amdgpu_top
    nvtopPackages.amd
    rocmPackages.rocminfo
    vulkan-tools
    uv
    (import ../../common/scripts/aider-search.nix { inherit pkgs; })
  ];

  services.openssh.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  networking.firewall.enable = false;
  system.stateVersion = "24.11";
}