# systemd Services and Timers NixOS Module

This module provides various systemd services and timers.

Generally, where a user-service would make sense, I still configure them as
global service because I'm mostly only using single-user systems. Further, I
experienced multiple issues with systemd user-services, such as they didn't
start for no clear reason or failed immediately. I didn't investigate these
failures further.
