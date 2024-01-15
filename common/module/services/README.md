# NixOS: Services Module

This module provides various systemd services. Generally, I add them as global
instead of user services, especially because I'm mostly only using single-user
systems. Further, I experienced multiple issues with systemd user-services, such
as they didn't start for no clear reason or failed immediately.
