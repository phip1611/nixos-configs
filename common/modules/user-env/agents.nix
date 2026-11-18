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
    home-manager.users."${cfg.username}" = {
      home.file = {
        ".claude/CLAUDE.md".source = ./DEFAULT_GLOBAL_AGENTS.md;
        ".codex/AGENTS.md".source = ./DEFAULT_GLOBAL_AGENTS.md;
        ".config/opencode/AGENTS.md".source = ./DEFAULT_GLOBAL_AGENTS.md;
        ".gemini/GEMINI.md".source = ./DEFAULT_GLOBAL_AGENTS.md;
      };
    };
  };
}
