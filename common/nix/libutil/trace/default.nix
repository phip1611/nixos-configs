{ ansi, toPretty }:

# Exports tracing helpers.

let
  stylize = msg: ansi.stylize [ ansi.style.bold ansi.color.fg.cyan ] msg;

  # Traces a value with a prefix and returns the specified return expression.
  # The message is prefixed with the given string and the value to be traced
  # prettyfied.
  prettyWithPrefix =
    prefix:
    val:
    ret:
    builtins.trace
      (
        "${stylize prefix}${toPretty { } val}"
      )
      ret;

  # Wrapper around `tracePrettyWithPrefix` with no prefix.
  pretty =
    val:
    ret:
    prettyWithPrefix "" val ret;

  # Wrapper around `tracePrettyWithPrefix` where the value to be traced is also
  # returned.
  prettyValWithPrefix =
    prefix:
    val:
    prettyWithPrefix prefix val val;

  # Wrapper around `tracePrettyValWithPrefix` with no prefix.
  prettyVal =
    val:
    prettyValWithPrefix "" val;
in
{
  inherit prettyWithPrefix pretty prettyValWithPrefix prettyVal;
}
