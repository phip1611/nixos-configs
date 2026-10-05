# img-to-webp-service in the webp container.
{
  img-to-webp-service,
  ...
}:

{
  imports = [
    img-to-webp-service.nixosModules.default
  ];

  services.img-to-webp-service.enable = true;
  services.img-to-webp-service.port = (import ../net.nix).backends.webp.port;
}
