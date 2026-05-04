{ ... }:
{
  # Unified git configuration
  # Added to centralize user identity and silence the evaluation warning:
  # "The default value of `programs.git.signing.format` has changed from `"openpgp"` to `null`."
  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      user.name = "Sammy Al Hashemi";
      user.email = "sammy@salh.xyz";
    };
  };
}
