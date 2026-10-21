{
  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/Sammyalhashe/nixosConfig.git";
        branches.main.name = "deployed";
      }
    ];
  };
}
