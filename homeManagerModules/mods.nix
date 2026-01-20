{ config, pkgs, lib, ... }:
{
  xdg.configFile."mods/mods.yml".text = ''
    default-api: perplexity
    default-model: sonar-pro
    format-text:
      markdown: "Format the response as markdown without enclosing backticks."
      json: "Format the response as json without enclosing backticks."
    mcp-servers: {}
    mcp-timeout: 15s
    roles:
      "default": []
    format: false
    role: "default"
    raw: false
    quiet: false
    temp: 1.0
    topp: 1.0
    topk: 50
    no-limit: false
    word-wrap: 80
    include-prompt-args: false
    include-prompt: 0
    max-retries: 5
    fanciness: 10
    status-text: Generating
    theme: charm
    max-input-chars: 12250
    max-completion-tokens: 100
    apis:
      perplexity:
        base-url: https://api.perplexity.ai
        api-key-env: PERPLEXITY_API_KEY
        models:
          sonar:
            name: sonar
            max-input-chars: 12288
          sonar-pro:
            name: sonar-pro
            max-input-chars: 12288
  '';
}
