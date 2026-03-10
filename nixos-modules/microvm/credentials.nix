{ config, lib, pkgs, utils, ... }:

let
  credentialShareTag = "microvm-credentials";
  credentialShareMountPoint = "/run/microvm-credentials-source";
  credentialShareSource = "./credentials";

  useInitrdShare = config.microvm.credentials.resolvedTransport == "initrd-share";
  credentialNames = builtins.attrNames config.microvm.credentialFiles;
  mountUnit = "${utils.escapeSystemdPath credentialShareMountPoint}.mount";
  credentialNameArgs = lib.concatStringsSep " " (map lib.escapeShellArg credentialNames);
in
lib.mkIf config.microvm.guest.enable {
  microvm.shares = lib.mkIf useInitrdShare (lib.mkAfter [ {
    tag = credentialShareTag;
    source = credentialShareSource;
    mountPoint = credentialShareMountPoint;
    proto = "virtiofs";
    readOnly = true;
  } ]);

  boot.initrd.systemd.services.microvm-import-credentials = lib.mkIf useInitrdShare {
    description = "Import MicroVM credentials from the internal credential share";
    wantedBy = [ "initrd.target" ];
    before = [ "initrd-switch-root.target" ];
    after = [ mountUnit ];
    requires = [ mountUnit ];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail

      source_dir=${lib.escapeShellArg credentialShareMountPoint}
      target_dir=/run/credentials/@initrd

      ${pkgs.coreutils}/bin/mkdir -p "$target_dir"
      ${pkgs.coreutils}/bin/chmod 0700 "$target_dir"

      if [ ! -d "$source_dir" ]; then
        echo "Credential source mount is missing: $source_dir" >&2
        exit 1
      fi

      credentials=( ${credentialNameArgs} )
      if [ "''${#credentials[@]}" -eq 0 ]; then
        exit 0
      fi

      for credential_name in "''${credentials[@]}"; do
        source_file="$source_dir/$credential_name"
        target_file="$target_dir/$credential_name"

        if [ ! -f "$source_file" ]; then
          echo "Configured credential file is missing from initrd share: $source_file" >&2
          exit 1
        fi

        ${pkgs.coreutils}/bin/install -D -m 0400 "$source_file" "$target_file"
      done
    '';
  };
}
