{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [
    "kvm-amd"
    "amdgpu"
    "i2c-dev"
    "i2c-piix4"
    "acpi-cpufreq"
  ];

  boot.kernelParams = [
    "amdgpu.si_support=1"
    "amdgpu.cik_support=1"
    "radeon.si_support=0"
    "radeon.cik_support=0"
    "amdgpu.dc=1"
    "amdgpu.dpm=1"
    
    "acpi_osi=Linux"
    "acpi_backlight=vendor"
  ];

  hardware = {
    amdgpu = {
      enable = true;
    };

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
    };

    cpu.amd.updateMicrocode = true;

    sensor.iio.enable = true;

    acpilight.enable = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
    powertop.enable = true;
  };

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      RADEON_POWER_PROFILE_ON_AC = "high";
      RADEON_POWER_PROFILE_ON_BAT = "low";
      
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
      
      USB_AUTOSUSPEND = 1;
      USB_BLACKLIST_WWAN = 1;
      
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersupersave";
    };
  };

  services.thermald.enable = true;

  services.lm_sensors = {
    enable = true;
    configFile = pkgs.writeText "sensors.conf" ''
      chip "k10temp-*"
        label temp1 "CPU"
      
      chip "amdgpu-*"
        label temp1 "GPU"
    '';
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    hwmon
    iotop
    powertop
    
    radeontop
    rocm-smi
    
    acpi
    upower
    
    pciutils
    usbutils
    dmidecode
  ];

  services.udev.extraRules = ''
    KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
    
    KERNEL=="amdgpu*", GROUP="video", MODE="0660"
    
    KERNEL=="backlight*", GROUP="video", MODE="0660"
  '';

  users.users.nixsociety.extraGroups = [ "video" "i2c" ];
}
