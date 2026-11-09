{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.host.username;

  guard = pkgs.writeShellApplication {
    name = "near-wallet-mcp";
    runtimeInputs = [
      pkgs.python3
      # near-mcp's entry point runs `node` from PATH.
      pkgs.nodejs_22
    ];
    text = ''
      export NEAR_KEYFILE=${config.sops.secrets.NEAR_AGENT_KEYFILE.path}
      export NTFY_TOKEN_FILE=${config.sops.secrets.near-wallet-ntfy.path}
      export NPX=${pkgs.nodejs_22}/bin/npx
      exec python3 ${./guard.py}
    '';
  };

  recipe = (pkgs.formats.yaml { }).generate "near-wallet.yaml" {
    version = "1.0.0";
    title = "NEAR agent wallet";
    description = "Trade the agent's NEAR wallet on Ref Finance; it cannot send funds";
    settings.temperature = 0.2;
    instructions = ''
      You manage a small NEAR mainnet trading wallet for the user. You can view
      balances and swap on Ref Finance; you cannot send or withdraw funds, and
      you must never try to get round that.
      Rules for every swap:
      - Trade only NEAR, wNEAR, USDC and USDT.
      - Get a swap estimate first, and do not swap if the expected loss to
        slippage and fees is over 3% or the trade is over 300 USD.
      - Before swapping, state the tokens, amount, estimate and why.
      Never call load_skill.
    '';
    prompt = "Show the wallet's balances, then wait for instructions.";
    extensions = [
      {
        type = "stdio";
        name = "near";
        cmd = lib.getExe guard;
        args = [ ];
        timeout = 300;
        # Same list the guard enforces; this only keeps the rest out of the prompt.
        available_tools = [
          "account_view_account_summary"
          "search_near_fungible_tokens"
          "contract_view_functions"
          "contract_get_function_args"
          "contract_call_raw_function_as_read_only"
          "ref_finance_get_pools"
          "ref_finance_get_swap_estimate"
          "ref_finance_execute_swap"
        ];
      }
    ];
  };

  # Local model only: the session holds the wallet's balances and decides trades.
  gooseNear = pkgs.writeShellApplication {
    name = "goose-near";
    runtimeInputs = [ pkgs.goose-cli ];
    text = ''
      export GOOSE_PROVIDER=openai
      export OPENAI_HOST=http://127.0.0.1:4000
      export OPENAI_BASE_PATH=v1/chat/completions
      export OPENAI_API_KEY=none
      export GOOSE_MODEL=qwen3.8
      # Every swap waits for your yes.
      export GOOSE_MODE=approve
      exec goose run --recipe ${recipe} --interactive "$@"
    '';
  };
in
{
  sops.secrets.NEAR_AGENT_KEYFILE.owner = user;
  sops.secrets.near-wallet-ntfy = {
    key = "NTFY_ALERTS_TOKEN";
    owner = user;
  };

  environment.systemPackages = [
    guard
    gooseNear
  ];
}
