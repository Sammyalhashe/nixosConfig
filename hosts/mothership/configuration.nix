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

  host.enableBreezy = true;

  # Default to server/headless mode (what systemd-boot loads)
  host.isHeadless = true;
  host.enableGreetd = false;

  # Specialisation allows switching to a full Desktop environment via the boot menu
  specialisation = {
    desktop.configuration = {
      system.nixos.tags = [ "desktop" ];
      host.isHeadless = lib.mkForce false;
      host.enableGreetd = lib.mkForce true;
      host.enableKDE = lib.mkForce true;
      host.enableMango = lib.mkForce true;
    };
  };
  
  host.homeManagerHostname = "default";
  host.fallbackNameservers = [ "11.125.37.1" ];

  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amd_iommu=off" # Disable IOMMU to prevent SDMA/VMM pagefaults on Strix Halo
      "iommu=pt"
      "amdgpu.gpu_recovery=1"
      "amdgpu.cwsr_enable=0" # Disable compute wave save/restore for ROCm stability
      "initcall_blacklist=simpledrm_platform_driver_init"

      # --- STRIX HALO HARDWARE FIXES (GFX 11.5.1) ---
      "amdgpu.sg_display=1" # Allows non-contiguous memory for display (Prevents -12 pin errors)
      "amdgpu.dcfeaturemask=0x0" # Disable PSR (Prevents pageflip timeouts on high-refresh panels)
      "amdgpu.dcdebugmask=0x10" # Disable unstable DC features
      "amdgpu.abmlevel=0" # Prevents panel backlight interference
      "amdgpu.runpm=0" # Keeps GPU awake for ROCm discovery

      # --- UNIFIED MEMORY MANAGEMENT ---
      # Leaving ~24GB for CPU/OS prevents the "Pageflip timeout" freezes when GPU is under heavy load
      "ttm.pages_limit=25600000"
      "amdgpu.gartsize=102400"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.overcommit_memory" = 1;
      "vm.nr_hugepages" = 1024;
      "net.ipv4.tcp_fastopen" = 3;
      "vm.min_free_kbytes" = 1048576; # 1GB reserve to prevent fragmentation stalls during heavy inference
    };
  };

  # Essential environment variables for GFX 11.5.1 and Playwright
  environment.variables = {
    HSA_OVERRIDE_GFX_VERSION = "11.5.1"; # Mandatory for Strix Halo to run ROCm 7.x
    RADV_PERFTEST = "aco";
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  };

  # --- LOCAL AI STACK CONFIGURATION ---
  # These services provide local OpenAI-compatible endpoints for Open WebUI and OpenClaw
  services.llm-services.gpt-oss.enable = false;    # Reasoning/Large (DeepSeek-R1-671B)
  services.llm-services.qwen-coder.enable = true; # Qwen3.6
  services.llm-services.qwen-flash.enable = true;  # Fast/Chat (Qwen2.5-7B) - Port 8011
  services.llm-services.gemma.enable = false;       # Bleeding Edge (Gemma 4-31B) - Port 8012
  services.llm-services.litellm-uv.enable = true;  # Proxy/Gateway - Port 4000

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
  # Background downloader that ensures GGUF files are present and verified
  systemd.services.model-downloader = {
    description = "Download and verify GGUF models in background";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.aria2 pkgs.coreutils pkgs.systemd ];
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
      download_model "qwq_32b_q4km.gguf" "https://huggingface.co/unsloth/QwQ-32B-GGUF/resolve/main/QwQ-32B-Q4_K_M.gguf"
      download_model "qwen3_next_q3km.gguf" "https://huggingface.co/unsloth/Qwen3-Coder-Next-GGUF/resolve/main/Qwen3-Coder-Next-Q3_K_M.gguf"
      download_model "google_gemma-4-31B-it-Q4_K_M.gguf" "https://huggingface.co/bartowski/google_gemma-4-31B-it-GGUF/resolve/main/google_gemma-4-31B-it-Q4_K_M.gguf"
      download_model "qwen2.5-1.5b-instruct-q8_0.gguf" "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q8_0.gguf"
      download_model "qwen2.5-7b-instruct-q8_0.gguf" "https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q8_0.gguf"
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
    nameservers = [ "11.125.37.99" "11.125.37.1" "1.1.1.1" ];
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
    extraGroups = [ "networkmanager" "docker" "wheel" "video" "render" "input" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPx5JBI3FNtugjdVeb1Gg4lUEJvGa/eiZ6rnsIN/oC3f sammy@salh.xyz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZKrkpzxAf0u3+fn59xouUtVHtklRuGwCwfPpR0Y8nc sammy.alhashemi@mail.utoronto.ca"
    ];
  };

  services.getty.autologinUser = "${user}";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  environment.systemPackages = with pkgs; [
    git amdgpu_top nvtopPackages.amd rocmPackages.rocminfo vulkan-tools uv yq-go playwright-driver.browsers
    (python313.withPackages (ps: with ps; [
      litellm backoff fastapi uvicorn pydantic python-dotenv apscheduler uvloop orjson pyyaml rich
      python-multipart cryptography pyjwt boto3 aiohttp httpx email-validator
    ]))
    (import ../../common/scripts/aider-search.nix { inherit pkgs; })
    (import ../../common/scripts/aider-pro.nix { inherit pkgs; })
    (import ../../common/scripts/agent-chainer.nix { inherit pkgs; })
    gnome-keyring libsecret
  ];

  services.gnome.gnome-keyring.enable = true;
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
