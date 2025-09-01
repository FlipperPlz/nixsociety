{ pkgs, install-fsociety, lib, ... }:

{ config, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ./modules/hyprland.nix
  ];

  # ISO settings
  isoImage = {
    isoName = "nixsociety.iso";
    volumeID = "NIXSOCIETY";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  boot.kernelParams = [ "copytoram" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";

  networking = {
    networkmanager.enable = true;
    wireless.enable = false;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Graphics
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    jetbrains-mono
    nerd-fonts
  ];

  users.users.nixsociety = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "bluetooth" ];
    password = "nixsociety";
  };

  services.getty.autologinUser = "nixsociety";
  security.sudo.wheelNeedsPassword = false;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  environment.systemPackages = [ install-nixsociety ];

  systemd.user.services.hyprland-autostart = {
    description = "Auto-start Hyprland";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.hyprland}/bin/Hyprland";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}