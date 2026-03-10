# Configuration options

By including the `microvm` module a set of NixOS options is made
available for customization. These are the most important ones:

| Option                         | Purpose                                                                                             |
|--------------------------------|-----------------------------------------------------------------------------------------------------|
| `microvm.hypervisor`           | Hypervisor to use by default in `microvm.declaredRunner`                                            |
| `microvm.vcpu`                 | Number of Virtual CPU cores                                                                         |
| `microvm.mem`                  | RAM allocation in MB                                                                                |
| `microvm.interfaces`           | Network interfaces                                                                                  |
| `microvm.volumes`              | Block device images                                                                                 |
| `microvm.shares`               | Shared filesystem directories                                                                       |
| `microvm.devices`              | PCI/USB devices for host-to-vm passthrough                                                          |
| `microvm.socket`               | Control socket for the Hypervisor so that a MicroVM can be shutdown cleanly                         |
| `microvm.user`                 | (qemu only) User account which Qemu will switch to when started as root                             |
| `microvm.forwardPorts`         | (qemu user-networking only) TCP/UDP port forwarding                                                 |
| `microvm.vfkit.extraArgs`      | (vfkit only) Extra arguments to pass to vfkit                                                       |
| `microvm.vfkit.logLevel`       | (vfkit only) Log level: "debug", "info", or "error" (default: "info")                               |
| `microvm.vfkit.rosetta.enable` | (vfkit only) Enable Rosetta for running x86_64 binaries on ARM64 (Apple Silicon only)               |
| `microvm.kernelParams`         | Like `boot.kernelParams` but will not end up in `system.build.toplevel`, saving you rebuilds        |
| `microvm.storeOnDisk`          | Enables the store on the boot squashfs even in the presence of a share with the host's `/nix/store` |
| `microvm.writableStoreOverlay` | Optional string of the path where all writes to `/nix/store` should go to.                          |
| `microvm.credentialFiles`      | Credential file mapping consumed by systemd `ImportCredential=` / `LoadCredential=`                  |

Credential transport notes:

- `qemu` uses `fw_cfg` by default.
- other hypervisors use `initrd-share`, copying credentials through an internal share and importing them from `/run/credentials/@initrd/`.
- `initrd-share` requires `boot.initrd.systemd.enable = true`.
- Source credential files must exist at VM start and must not be symlinks; staging fails fast with a clear error when a source is missing or invalid.

See [the options declarations](
https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/options.nix)
for a full reference.
