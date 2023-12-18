{ config, lib, pkgs, ... }:

{

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.mfcl8690cdwcupswrapper ];
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

}
