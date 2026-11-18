{
  runCommand,
}:

let
  theme = ./.;
in
runCommand "plymouth-theme-phips-unlock" { } ''
  theme_dir="$out/share/plymouth/themes/phips-unlock"
  install -Dm444 ${theme}/phips-unlock.plymouth "$theme_dir/phips-unlock.plymouth"
  install -Dm444 ${theme}/phips-unlock.script "$theme_dir/phips-unlock.script"
  install -Dm444 ${theme}/assets/prompt-card.png "$theme_dir/prompt-card.png"
  install -Dm444 ${theme}/assets/entry.png "$theme_dir/entry.png"
  install -Dm444 ${theme}/assets/bullet.png "$theme_dir/bullet.png"
  substituteInPlace "$theme_dir/phips-unlock.plymouth" --replace-fail @THEME_DIR@ "$theme_dir"
''
