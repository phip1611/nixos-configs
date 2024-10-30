{
  enableACME = true;
  http2 = true;
  http3 = true;
  quic = true; # also needed when http3 = true
  # reuseport = true; # recommended for quic
  # Upgrade HTTP to HTTPS
  forceSSL = true;
  extraConfig = ''
    # 0-RTT: Enable TLS 1.3 early data
    ssl_early_data on;
    # Enables sending in optimized batch mode using segmentation offloading.
    quic_gso on;
    # Enables the QUIC Address Validation feature. This includes sending a new
    # token in a Retry packet or a NEW_TOKEN frame and validating a token
    # received in the initial packet.
    quic_retry on;

    # Advertise http3, not done by NixOS option http3=true yet
    add_header Alt-Svc 'h3=":443"; ma=86400';

    # Add HSTS header with preloading to HTTPS requests.
    # Adding this header to HTTP requests is discouraged
    # TODO using the "map" directive creates errors on startup..
    # map $scheme $hsts_header {
    #   https 'max-age=31536000; includeSubdomains; preload';
    # }
    # add_header Strict-Transport-Security $hsts_header;
    add_header Strict-Transport-Security 'max-age=31536000; includeSubdomains; preload';

    # Minimize information leaked to other domains
    add_header 'Referrer-Policy' 'origin-when-cross-origin';

    # Disable embedding as a frame
    add_header X-Frame-Options DENY;

    # Prevent injection of code in other mime types (XSS Attacks)
    add_header X-Content-Type-Options nosniff;
  '';
}
