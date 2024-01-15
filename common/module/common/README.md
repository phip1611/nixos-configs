# NixOS: Common Module

This directory contains my common NixOS configurations that are generic and can
be imported by any of my NixOS machines. In other words, this is what I want and
expect on all my machines. They affect the user environment, such as environment
variables, installed packages, and the prompt. The settings are as much as
possible independent of the underlying hardware and NixOS version. However, some
assumptions are there, such as that a reasonable fresh version of Nixpkgs is
required.

## Configuration

All modules are as standalone as possible, and it is possible to further
configure the options. By default, you just should set
`config.phip1611.common.enable = true`.

## Prerequisites

The NixOS options of [Home manager](https://github.com/nix-community/home-manager) must be available; you need to add the
module manually.
