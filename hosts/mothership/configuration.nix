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
    # --- TIERED LLM SERVICES ---
    # Import the modular service definitions (Gemma, Qwen, LiteLLM, etc.)
    ../../modules/ai/llm-services
  ];

  # Headless AI machine: no desktop/GUI is ever built or installed.
  # Default to server/headless mode (what systemd-boot loads)
  host.isHeadless = true;
  host.enableGreetd = false;

  host.homeManagerHostname = "mothership";
  host.fallbackNameservers = [ "11.125.37.1" ];

  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # GPU kernel params live with the backend module: amd_iommu=off and the
      # unified-memory sizing are shared in backend/default.nix, while the
      # KFD-only workarounds (amdgpu.cwsr_enable=0, amdgpu.runpm=0) are in
      # backend/rocm.nix and drop automatically under Vulkan.
      #
      # iommu=pt was dropped: amd_iommu=off turns the AMD IOMMU off outright, so
      # asking for passthrough mode alongside it was contradictory dead config.
      "amdgpu.gpu_recovery=1"
      "initcall_blacklist=simpledrm_platform_driver_init"

      # --- STRIX HALO HARDWARE FIXES (GFX 11.5.1) ---
      "amdgpu.sg_display=1" # Allows non-contiguous memory for display (Prevents -12 pin errors)
      "amdgpu.dcfeaturemask=0x0" # Disable PSR (Prevents pageflip timeouts on high-refresh panels)
      "amdgpu.dcdebugmask=0x10" # Disable unstable DC features
      "amdgpu.abmlevel=0" # Prevents panel backlight interference

      # Unified-memory sizing (amdgpu.gttsize / ttm.pages_limit) is owned by
      # services.llm-services.backend.gttSizeMiB — see the backend module. Both
      # backends need it, so it follows the backend rather than the host.
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.overcommit_memory" = 1;
      "vm.nr_hugepages" = 1024;
      "net.ipv4.tcp_fastopen" = 3;
      "vm.min_free_kbytes" = 1048576; # 1GB reserve to prevent fragmentation stalls during heavy inference
    };
  };

  # Dropped two stale GPU variables that used to live here:
  #
  #   RADV_PERFTEST = "aco"        — dead. "aco" is not in radv_perftest_options
  #                                  in this mesa (ACO became the default backend
  #                                  and the toggle was removed), so RADV parsed
  #                                  it as an unknown option and ignored it.
  #   HSA_OVERRIDE_GFX_VERSION     — redundant, and far too broad set globally.
  #                                  llama-cpp-rocm builds gfx1151 natively, so
  #                                  overriding gfx1151 to gfx1151 is a no-op;
  #                                  backend/rocm.nix still sets it per-service.
  environment.variables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  };

  # --- LOCAL AI STACK CONFIGURATION ---
  # These services provide local OpenAI-compatible endpoints for Open WebUI and OpenClaw
  # Local GPU inference backend (Strix Halo / gfx1151). Flip these two to switch
  # the whole llama.cpp stack between ROCm and Vulkan (see backend module).
  # Vulkan (RADV) is upstream's recommended backend for gfx1151 on grounds of
  # stability and compatibility — see https://strix-halo-toolboxes.com/.
  #
  # It is NOT the faster one. Upstream's own benchmark data has ROCm tied on
  # token generation (1.00x) but well ahead on prefill, and the gap grows with
  # context: 1.34x at depth 0, 1.41x at 32k, 2.37x at 64k. Hermes runs at
  # 131072, so the penalty here is real. Flip these two and measure prefill at
  # a realistic depth before settling.
  services.llm-services.backend.enableRocm = false;
  services.llm-services.backend.enableVulkan = true;

  services.llm-services.gpt-oss.enable = false; # Reasoning/Large (DeepSeek-R1-671B)
  services.llm-services.qwen-coder.enable = false; # Qwen3.6
  services.llm-services.qwen-flash.enable = true; # Fast/Chat (Qwen2.5-7B) - Port 8011
  services.llm-services.gemma.enable = false; # Bleeding Edge (Gemma 4-31B) - Port 8012
  services.llm-services.litellm-uv.enable = false; # (uv/PyPI runtime resolution — non-reproducible, drifted/broke)
  services.llm-services.litellm.enable = true; # Proxy/Gateway - Port 4000 (Nix-native, reproducible)
  services.llm-services.llama-cpp-hermes.enable = true; # Hermes-3-Llama-3.1

  powerManagement.cpuFreqGovernor = "performance";

  # Open WebUI: The primary user interface for all local and remote LLMs
  services.open-webui = {
    enable = true;
    port = 8080;
    host = "0.0.0.0";
    environment = {
      # Points to local llama-server instances and the LiteLLM gateway
      OPENAI_API_BASE_URLS = "http://127.0.0.1:8011/v1;http://127.0.0.1:8014/v1;http://127.0.0.1:8012/v1;http://127.0.0.1:4000/v1";
      OPENAI_API_KEYS = "none;none;none";
      ENABLE_OLLAMA_API = "False";
      ENABLE_WEB_SEARCH = "True";
      WEB_SEARCH_ENGINE = "duckduckgo";
      WEB_SEARCH_CONCURRENT_REQUESTS = "1";
      USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
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

  systemd.services.open-webui.serviceConfig.EnvironmentFile = [
    config.sops.templates."open-webui-env".path
  ];

  # --- DECLARATIVE MODEL MANAGEMENT ---
  # Main models are fetched by llama-server itself via --hf-repo/--hf-file into
  # LLAMA_CACHE (see modules/ai/llm-services), which handles split GGUFs, resume
  # and etag verification. This job only covers the speculative-decoding draft
  # model, which llama-server's --hf-* flags do not reach.
  systemd.services.model-downloader = {
    description = "Download the speculative-decoding draft model";
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
        # aria2 leaves a .aria2 control file next to any partial download. A
        # bare -f check treats a half-fetched 40GB shard as done, which is how
        # the Hermes shards ended up unusable; resume unless the control file
        # is gone.
        if [ -f "$target" ] && [ ! -f "$target.aria2" ]; then
          return 0
        fi
        aria2c -x16 -s16 -j5 -c --dir="$MODEL_DIR" -o "$name" "$url"
      }
      download_model "qwen2.5-1.5b-instruct-q8_0.gguf" "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q8_0.gguf"
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

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "11.125.37.99";
        Domains = "~salh.xyz";
      };
    };
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
      "video"
      "render"
      "input"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPx5JBI3FNtugjdVeb1Gg4lUEJvGa/eiZ6rnsIN/oC3f sammy@salh.xyz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2hNthWiWeNoxH848/Vhdkc8jWNJw7690ZNAh8RVE9d sammy@salh.xyz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZKrkpzxAf0u3+fn59xouUtVHtklRuGwCwfPpR0Y8nc sammy.alhashemi@mail.utoronto.ca"
    ];
  };

  services.getty.autologinUser = "${user}";
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
    yq-go
    playwright-driver.browsers
    (python313.withPackages (
      ps: with ps; [
        litellm
        backoff
        fastapi
        uvicorn
        pydantic
        python-dotenv
        apscheduler
        uvloop
        orjson
        pyyaml
        rich
        python-multipart
        cryptography
        pyjwt
        boto3
        aiohttp
        httpx
        email-validator
      ]
    ))
    (import ../../common/scripts/aider-search.nix { inherit pkgs; })
    (import ../../common/scripts/aider-pro.nix { inherit pkgs; })
    (import ../../common/scripts/agent-chainer.nix { inherit pkgs; })
    gnome-keyring
    libsecret
  ];

  services.gnome.gnome-keyring.enable = true;
  services.openssh.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  networking.extraHosts = ''
    11.125.37.101 mothership
    11.125.37.175 oldboy
    11.125.37.99  raspberrypi
    11.125.37.98  filestore
    11.125.37.135 homebase
  '';

  networking.firewall.enable = false;
  system.stateVersion = "24.11";
}
