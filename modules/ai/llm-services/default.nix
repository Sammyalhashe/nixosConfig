{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./backend
    ./models.nix
    ./models/qwen-flash.nix
    ./models/qwen3-8-flash-next.nix
    ./litellm.nix
  ];

  options.services.llm-services.modelCacheDir = lib.mkOption {
    type = lib.types.str;
    default = "/var/lib/llama-cpp-models";
    readOnly = true;
    description = ''
      LLAMA_CACHE for every llama-cpp-* service, so a GGUF pulled by one is
      reused by the rest rather than downloaded per service.

      Fixed under /var/lib because the services reach it through systemd's
      StateDirectory=llama-cpp-models, which is what creates the directory and
      chowns it to the service user; the two must not drift apart.
    '';
  };
}
