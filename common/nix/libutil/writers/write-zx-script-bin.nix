# This returns a writer that creates an executable Google ZX script in `<pkg>/bin/%name`
# with the provided content. Similar to `writeShellScriptBin`, it consumes the name of
# the script and the NodeJS/ZX-script content as parameters.

{
  writeShellScriptBin,
  writeTextFile,
  zx,
}:

name: text:

let
  mjsBin = writeTextFile {
    name = "${name}-mjs";
    executable = true;
    # For Google ZX, the .mjs extension is mandatory.
    destination = "/bin/${name}.mjs";
    text = ''
      #!${zx}/bin/zx
      ${text}
    '';
  };
in
# Wrapper enables to call the zx-script without the .mjs extension. It
# calls zx directly, as a script as shebang interpreter passes the path of
# the wrapper as additional argument and doesn't work on macOS.
writeShellScriptBin name ''
  exec ${zx}/bin/zx ${mjsBin}/bin/${name}.mjs "$@"
''
