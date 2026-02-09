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
  ];

  host.useOmarchy = lib.mkDefault false;
  host.greetd = true;
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

      # Memory Aperture (Confirmed working)
      "ttm.pages_limit=25165824"
      "ttm.page_pool_size=25165824"
      "amdgpu.gartsize=98304"
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

  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama-rocm;
  #   rocmOverrideGfx = "11.5.1";
  #   loadModels = [
  #     "deepseek-coder-v2:236b-instruct-q4_K_M"
  #     "qwen2.5-coder:32b-instruct"
  #     "llama3.3:70b-instruct-q4_K_M"
  #   ];
  #
  #   environmentVariables = {
  #     HSA_OVERRIDE_GFX_VERSION = "11.5.1";
  #     HSA_ENABLE_SDMA = "0";
  #     HSA_XNACK = "0";
  #
  #     # --- THE SEGFAULT AT 0x18 FIXES ---
  #     OLLAMA_USE_MMAP = "0"; # MUST BE ZERO - forces weights into RAM
  #     HSA_OVERRIDE_CPU_HSA_CAPABLE = "0"; # STOP CPU node capability (Stops the 0x18 sync)
  #     HSA_AMD_P2P = "0"; # DISABLES Peer-to-Peer (Bypasses APU init bug)
  #     HSA_FORCE_FINE_GRAIN_CACHE = "0"; # Force Coarse Grained pool usage
  #
  #     # Limit ROCm to the GPU only
  #     HIP_VISIBLE_DEVICES = "0";
  #     ROCR_VISIBLE_DEVICES = "0";
  #     HSA_IGNORE_CPU_NODE_CHECK = "1";
  #     ROC_ENABLE_PRE_ALLOCATION = "0";
  #   };
  # };
  #
  # # CRITICAL: We must ensure the model loader AND the runner share the exact same env
  # # The NixOS module sometimes fails to pass these to the helper loader service
  # systemd.services.ollama-model-loader.environment = config.services.ollama.environmentVariables;
  # # Fix for PATH conflict in model loader
  # systemd.services.ollama-model-loader.path = lib.mkForce [
  #   pkgs.rocmPackages.clr
  #   pkgs.coreutils
  # ];
  #
  # systemd.services.ollama = {
  #   after = [ "network.target" ];
  #   path = lib.mkForce [
  #     pkgs.rocmPackages.clr
  #     pkgs.coreutils
  #   ];
  #   wants = [ "network.target" ];
  #   serviceConfig = {
  #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
  #     TimeoutStartSec = "300";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #   };
  # };

  # 1. The Llama-cpp Service (Coder - Port 8012)

  services.llama-cpp = {

    enable = true;

    port = 8012;

    host = "0.0.0.0";

    package = pkgs.llama-cpp.override { vulkanSupport = true; };

    model = "/var/lib/llama-cpp-models/qwen_32b.gguf";

    extraFlags = [

      "--n-gpu-layers"
      "999"

      "--ctx-size"
      "32768"

      "--threads"
      "16"

      "--device"
      "Vulkan0"

      "--flash-attn"
      "1"

    ];

  };

  # 2. The Llama-cpp Service (Reasoner - Port 8013)

  systemd.services.llama-cpp-reasoning = {

    description = "LLaMA C++ server (Reasoning)";

    after = [ "network.target" ];

    wantedBy = [ "multi-user.target" ];

    environment = {

      XDG_CACHE_HOME = "/var/cache/llama-cpp-reasoning";

      RADV_PERFTEST = "aco";

      AMD_VULKAN_ICD = "RADV";

      GGML_VK_PREFER_HOST_MEMORY = "1";

    };

    serviceConfig = {

      User = "salhashemi2";

      Group = "users";

      CacheDirectory = "llama-cpp-reasoning";

      RuntimeDirectory = "llama-cpp-reasoning";

      DeviceAllow = [
        "/dev/dri/renderD128"
        "/dev/dri/card0"
        "/dev/kfd"
      ];

      PrivateDevices = false;

      ExecStart = "${
        pkgs.llama-cpp.override { vulkanSupport = true; }
      }/bin/llama-server --model /var/lib/llama-cpp-models/gpt-oss-120b.gguf --port 8013 --host 0.0.0.0 --n-gpu-layers 999 --ctx-size 8192 --threads 16 --device Vulkan0 --flash-attn 1";

      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

      Restart = "on-failure";

      RestartSec = "5s";

    };

  };

  powerManagement.cpuFreqGovernor = "performance";

  # 3. Systemd Service Overrides (Environment & Permissions for Coder)

  systemd.services.llama-cpp = {

    after = [ "network.target" ];

    environment = {

      XDG_CACHE_HOME = "/var/cache/llama-cpp";

      RADV_PERFTEST = "aco"; # Use the superior Mesa compiler

      AMD_VULKAN_ICD = "RADV";

      GGML_VK_PREFER_HOST_MEMORY = "1";

    };

    serviceConfig = {

      # Since the model is in your home dir, we'll run as your user for now

      User = "salhashemi2";

      Group = "users";

      CacheDirectory = "llama-cpp";

      RuntimeDirectory = "llama-cpp";

      # Grant permission to the GPU and memory fabric

      DeviceAllow = [

        "/dev/dri/renderD128"

        "/dev/dri/card0"

        "/dev/kfd"

      ];

      PrivateDevices = false;

      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

      Restart = "on-failure";

      RestartSec = lib.mkForce "5s";

    };

  };

  # 4. Update Open WebUI to talk to Llama.cpp

  # Llama.cpp server uses OpenAI-compatible endpoints on port 8012 by default

  services.open-webui = {

    enable = true;

    port = 8080;

    environment = {

      # Redirect from Ollama's port (11434) to Llama.cpp's port (8012)

      # We add /v1 because llama-cpp-server exposes an OpenAI-compatible API

      OPENAI_API_BASE_URL = "http://127.0.0.1:8012/v1";

      OPENAI_API_KEY = "none";

      # Disable the default Ollama search to clean up the UI

      ENABLE_OLLAMA_API = "False";

    };

  };

  # Declarative Model Management

  systemd.services.model-downloader = {

    description = "Download and verify GGUF models in background";

    after = [ "network.target" ];

    # Keep this so it starts on boot, but Type=simple ensures it doesn't block

    wantedBy = [ "multi-user.target" ];

    path = [

      pkgs.aria2 # The high-speed downloader

      pkgs.coreutils # For mkdir/echo

      pkgs.systemd # For systemctl restart

    ]; # Ensure script can find curl/mkdir

    script = ''

      MODEL_DIR="/var/lib/llama-cpp-models"

      mkdir -p "$MODEL_DIR"

      RESTART_REQUIRED=false



      download_model() {

        local name=


        local url=$2

        local target="$MODEL_DIR/$name"

        if [ ! -f "$target" ]; then

          echo "Fast-syncing $name with aria2c..."

          # -x16: 16 connections per server

          # -s16: Split the file into 16 chunks

          # -c:   Continue partial downloads

          if aria2c -x16 -s16 -j5 -c --summary-interval=10 --dir="$MODEL_DIR" -o "$name" "$url"; then       

              echo "Finished downloading: $name"

              RESTART_REQUIRED=true

          else

              echo "Download failed for model $name"

          fi

        else

          echo "Model $name already exists, skipping."

        fi

      }



      download_model "qwen_32b.gguf" "https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/qwen2.5-coder-32b-instruct-q4_k_m.gguf"

      download_model "llama_70b.gguf" "https://huggingface.co/lmstudio-community/Llama-3.3-70B-Instruct-GGUF/resolve/main/Llama-3.3-70B-Instruct-Q4_K_M.gguf"

      download_model "gpt-oss-120b.gguf" "https://huggingface.co/openai/gpt-oss-120b-GGUF/resolve/main/gpt-oss-120b-q4_k_m.gguf"



      if [ "$RESTART_REQUIRED" = true ]; then

        echo "Cleaning up .aria2 control files..."

        rm -f "$MODEL_DIR"/*.aria2

        echo "New models detected. Triggering batch restart of llama-cpp..."

        systemctl restart llama-cpp.service

        systemctl restart llama-cpp-reasoning.service

      else

        echo "No updates needed. Services remain undisturbed."

      fi

    '';

    serviceConfig = {
      Type = "simple"; # Returns control to Nix immediately
      User = "salhashemi2";
      Nice = 10;
      # If the internet cuts out, try again in 30s
      Restart = "on-failure";
      RestartSec = "30s";
      StateDirectory = "llama-cpp-models";
      # This creates /var/lib/llama-cpp-models owned by salhashemi2
      StateDirectoryMode = "0755";
    };
  };

  # 2. Add the Vulkan driver to your graphics stack
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
  ];
  # Remaining system config...
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # extraPackages = with pkgs; [ rocmPackages.clr.icd ];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 20;
  };

  # auto upgrade
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # enable garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Bootloader.
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
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

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
    (pkgs.buildEnv {
      name = "lemonade-runtime";
      paths = [
        pkgs.rocmPackages.clr
        pkgs.vulkan-loader
        pkgs.libdrm
      ];
    })
  ];

  # xdg env variables
  environment.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/var/lib";
    XDG_CACHE_HOME = "$HOME/var/cache";
  };

  fonts.packages = with pkgs; [
    monoid
    source-code-pro
    xorg.fontadobe100dpi
    xorg.fontadobe75dpi
  ];
  fonts.fontDir.enable = true;

  services.openssh.enable = true;
  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.thincast.client"
  ];
  services.flatpak.remotes = [
    {
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }
  ];
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.udev.packages = with pkgs; [
    platformio-core.udev
    openocd
  ];

  networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
