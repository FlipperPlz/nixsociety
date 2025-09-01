{ pkgs }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "install-nixsociety";
  version = "0.1.0";
  
  src = pkgs.lib.cleanSource ../../installer;
  
  cargoLock = {
    lockFile = ../../installer/Cargo.lock;
  };
  
  nativeBuildInputs = with pkgs; [ 
    pkg-config 
    rust-bin.stable.latest.default
  ];
  
  buildInputs = with pkgs; [ 
    openssl 
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin.apple_sdk.frameworks.Security
  ];
  
  # Skip tests during build
  doCheck = false;
  
  meta = with pkgs.lib; {
    description = "NixSociety installer";
    license = licenses.mit;
    maintainers = [ ];
  };
}