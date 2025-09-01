{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.systemPackages = with pkgs; [
    kitty
    dolphin
    wofi
    rofi-wayland
    rofi-power-menu
    rofi-file-browser-extended
    waybar
    networkmanagerapplet
    swaylock
    firefox
    htop

    wireplumber 
    playerctl
    brightnessctl
    pavucontrol
    wlogout

    grim
    slurp
    wl-clipboard

    bluez
  ];

  system.activationScripts.userConfigs = ''
    mkdir -p /home/nixsociety/.config

    cp -r ${../config/hypr} /home/nixsociety/.config/hypr
    cp -r ${../config/waybar} /home/nixsociety/.config/waybar

    # Set permissions
    chown -R nixsociety:users /home/nixsociety/.config
    chmod -R 755 /home/nixsociety/.config
  '';
}