{ self, nixpkgs, system, makeTestConfigs }:

let
  pkgs = nixpkgs.legacyPackages.${system};

  configs = makeTestConfigs {
    name = "shutdown-command";
    inherit system;
    modules = [
      ({ config, ... }: {
        networking = {
          hostName = "microvm-test";
          useDHCP = false;
        };
        microvm = {
          socket = "./microvm.sock";
          crosvm.pivotRoot = "/build/empty";
          testing.enableTest = config.microvm.declaredRunner.canShutdown;
        };
      })
    ];
  };

in
builtins.mapAttrs (_: nixos:
  pkgs.runCommandLocal "microvm-test-shutdown-command" {
    nativeBuildInputs = [
      nixos.config.microvm.declaredRunner
      pkgs.p7zip
    ];
    requiredSystemFeatures = [ "kvm" ];
  } ''
    set -m
    microvm-run > $out &

    sleep 10
    echo Now shutting down
    microvm-shutdown
  ''
) configs
