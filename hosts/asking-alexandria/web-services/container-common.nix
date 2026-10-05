# Configuration shared by all web service containers.
{
  # Like on the host; enables `networking.firewall.extraInputRules`.
  networking.nftables.enable = true;

  system.stateVersion = "26.05";
}
