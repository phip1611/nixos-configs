# NixOS: Common Module

This directory contains my common NixOS configurations that are generic and can
be imported by any of my NixOS machines. In other words, this is what I want and
expect on all my machines. They affect the user environment, such as environment
variables, installed packages, and the prompt. The settings are as much as
possible independent of the underlying hardware and NixOS version. However, some
assumptions are there, such as that a reasonable fresh version of Nixpkgs is
required.

All modules are as standalone as possible, and it is possible to only use
non-GUI related configurations to keep the footprint on servers or otherwise
limited environments small.

## Prerequisites
[Home manager](https://github.com/nix-community/home-manager) must be globally
available for the `common.user.env` module. This module doesn't import
home-manager itself. Instead, the configurations provided by this module are
just an extension. An example how to set that up can be found in
[README](../README.md).
