{...}: {
  imports = [
    # Web apps
    ./web-apps/calibre-web.nix
    ./web-apps/your_spotify.nix
    ./web-apps/code-server.nix
    ./web-apps/openvscode-server.nix

    # Wayland
    ./wayland/hypridle.nix

    # Misc
    ./misc/calibre-server.nix

    # Audio
    ./audio/spotifyd.nix

    # Monitoring
    ./monitoring/rustdesk-server.nix

    # Networking
    ./networking/tailscale.nix
    ./networking/tailscale-auth.nix
    ./networking/tailscale-derper.nix
    ./networking/v2ray.nix
    ./networking/v2raya.nix
    ./networking/wg-access-server.nix
    ./networking/wg-netmanager.nix
    ./networking/wg-quick.nix
    ./networking/wgautomesh.nix
    ./networking/wireguard.nix
    ./networking/wireguard-networkd.nix
    ./networking/wpa_supplicant.nix
    ./networking/zerotierone.nix
    ./networking/autossh.nix
    ./networking/atticd.nix
    ./networking/adguardhome.nix
    ./networking/cloudflare-dyndns.nix
    ./networking/cloudflared.nix
    ./networking/cloudflare-warp.nix
    ./networking/openvpn.nix

    # Network filesystems
    ./network-filesystems/rsyncd.nix
    ./network-filesystems/ceph.nix

    # Hardware
    ./hardware/display.nix
    ./hardware/fancontrol.nix
    ./hardware/bluetooth.nix
    ./hardware/nvidia-container-toolkit.nix

    # CI/CD
    ./continuous-integration/github-runners.nix
    ./continuous-integration/gitlab-runner.nix
    ./continuous-integration/hydra

    # Web servers
    ./web-servers/nginx/tailscale-auth.nix

    # Cluster
    ./cluster/k3s
    ./cluster/kubernetes
  ];
}
