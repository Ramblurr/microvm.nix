{ nixpkgs, system, makeTestConfigs, ... }:

let
  pkgs = nixpkgs.legacyPackages.${system};

  configs = makeTestConfigs {
    name = "shutdown-command";
    inherit system;
    modules = [
      ({ config, lib, ... }: {
        networking = {
          hostName = "microvm-test";
          useDHCP = false;
        };
        microvm = {
          socket = "./microvm.sock";
          crosvm.pivotRoot = "/build/empty";
          testing.enableTest = config.microvm.declaredRunner.canShutdown;
        };
        system.stateVersion = lib.mkDefault lib.trivial.release;
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
    meta.timeout = 120;
  } (
    let
      resolvedTransport = nixos.config.microvm.credentials.resolvedTransport;
    in
    if resolvedTransport == "initrd-share"
    then ''
      set -euo pipefail
      set -m

      cp -a ${nixos.config.microvm.declaredRunner} runner
      chmod -R u+w runner

      mutable_secret="$PWD/mutable-secret"
      metadata_file="$PWD/runner/share/microvm/credentials/initrd-share"

      cleanup() {
        if [ -n "''${virtiofsd_pid:-}" ]; then
          kill "$virtiofsd_pid" 2>/dev/null || true
          wait "$virtiofsd_pid" 2>/dev/null || true
        fi
      }
      trap cleanup EXIT

      printf 'first secret' > "$mutable_secret"
      printf 'SECRET_BOOTSTRAP_KEY\t%s\n' "$mutable_secret" > "$metadata_file"

      runner/bin/virtiofsd-run > virtiofsd.log 2>&1 &
      virtiofsd_pid=$!

      runner/bin/microvm-run > first-run.log &
      export MAINPID=$!
      sleep 10
      echo Now shutting down
      runner/bin/microvm-shutdown
      wait "$MAINPID"

      grep -q 'first secret' credentials/SECRET_BOOTSTRAP_KEY

      printf 'second secret' > "$mutable_secret"

      runner/bin/microvm-run > second-run.log &
      export MAINPID=$!
      sleep 10
      echo Now shutting down again
      runner/bin/microvm-shutdown
      wait "$MAINPID"

      grep -q 'second secret' credentials/SECRET_BOOTSTRAP_KEY

      mkdir "$out"
    ''
    else ''
      set -m
      microvm-run > $out &
      export MAINPID=$!

      sleep 10
      echo Now shutting down
      microvm-shutdown
    ''
  )
) configs
