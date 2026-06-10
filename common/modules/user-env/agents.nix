# LLM/AI Agents
#
# Configures a global default AGENTS.md for coding agents.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.phip1611.common.user-env;
in
{
  config = lib.mkIf (cfg.enable) {
    home-manager.users."${cfg.username}" =
      {
        # Refers to the home-manager config, not the NixOS config
        config,
        ...
      }:
      {
        home.file =
          let
            inherit (config.lib.file) mkOutOfStoreSymlink;
          in
          {
            ".claude/CLAUDE.md".source = mkOutOfStoreSymlink ./DEFAULT_GLOBAL_AGENTS.md;
            ".codex/AGENTS.md".source = mkOutOfStoreSymlink ./DEFAULT_GLOBAL_AGENTS.md;
            ".config/opencode/AGENTS.md".source = mkOutOfStoreSymlink ./DEFAULT_GLOBAL_AGENTS.md;
            ".gemini/GEMINI.md".source = mkOutOfStoreSymlink ./DEFAULT_GLOBAL_AGENTS.md;
          };
      };
  };
}
