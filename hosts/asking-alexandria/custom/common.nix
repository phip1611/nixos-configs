{
  virtualHostConfig = {
    enableACME = true;
    http2 = true;
    http3 = true;
    quic = true; # also needed when http3 = true
    # Upgrade HTTP to HTTPS
    forceSSL = true;
  };
  securityHeadersConfig = ''
    # Add HSTS header with preloading to HTTPS requests.
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Enable CSP
    add_header Content-Security-Policy "script-src 'self'; object-src 'self'; base-uri 'self';" always;

    # Minimize information leaked to other domains
    add_header 'Referrer-Policy' 'origin-when-cross-origin';

    # Disable embedding as a frame
    add_header X-Frame-Options DENY;

    # Prevent injection of code in other mime types (XSS Attacks)
    add_header X-Content-Type-Options nosniff;

    # This might create errors
    proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
  '';
  cacheHeadersConfig = "";
  /* ''
    location ~* \.(js|css|jpg|jpeg|png|gif|js|css|ico|swf)$ {
          expires 1y;
          etag off;
          if_modified_since off;
          add_header Cache-Control "public, no-transform";
        }
  ''; */
}
