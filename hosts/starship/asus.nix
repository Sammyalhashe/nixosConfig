{
  ...
}:
{
  boot.kernelParams = [
    "acpi_backlight=vendor"
    "asus_nb_wmi.fnlock_default=1"
  ];

  # This helps with Asus-specific hardware quirks
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
}
