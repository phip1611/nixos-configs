{
  enableACME = true;
  http2 = true;
  http3 = true;
  quic = true; # also needed when http3 = true
  reuseport = true; # recommended for quic
  # Upgrade HTTP to HTTPS
  forceSSL = true;
  extraConfig = ''
    # 0-RTT: Enable TLS 1.3 early data
    ssl_early_data on;
    quic_gso on;

    # Advertise http3, not done by NixOS option http3=true yet
    add_header Alt-Svc 'h3=":443"; ma=86400';
  '';
}
