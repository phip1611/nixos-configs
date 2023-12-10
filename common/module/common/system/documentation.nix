{ lib, config, options, ... }:

let
  cfg = config.phip1611.common.system.documentation;
in
{
  options = {
    phip1611.common.system.documentation.enable = lib.mkEnableOption "Enable man pages but no /share/doc resources";
  };

  config = lib.mkIf cfg.enable {
    documentation.enable = true;
    documentation.man.enable = true;
    documentation.dev.enable = true;
    # no /share/doc resources
    documentation.doc.enable = false;
  };
}
