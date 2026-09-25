# reboot-mollyguard

A wrapper for the `reboot` command. Before the machine reboots, the operator
types the name of the machine they are on. If the name is wrong, the wrapper
cancels the reboot.

This is a guardrail against mistakes. It is not a security control. Anyone who
can reboot the machine can type its name or call `/sbin/reboot` directly.

Works on RHEL and SLES. Requires bash 4 or later.

## How it works

- The wrapper installs to `/usr/local/sbin/reboot`.
- RHEL and SLES put `/usr/local/sbin` before `/usr/sbin` and `/sbin` in
  `PATH`, so plain `reboot` reaches the wrapper.
- The wrapper shows the machine name and asks the operator to type it.
  The operator types the short hostname or the full FQDN. Case does not
  matter.
- If the name matches, the wrapper runs the real binary
  (`/usr/sbin/reboot`) and passes all arguments through.
- The wrapper never changes `/sbin/reboot`. It reboots without a prompt.
- The wrapper refuses to run without a terminal. Scripts, cron jobs,
  and automation must call `/usr/sbin/reboot` directly.

## Install

Run as root:

```sh
sudo ./install.sh
```

Or by hand:

```sh
sudo install -m 0755 reboot /usr/local/sbin/reboot
type -a reboot    # first line must be /usr/local/sbin/reboot
```

## Uninstall

```sh
sudo ./install.sh --uninstall
```

## Example

```
$ reboot
You are about to reboot: hades
Type the machine name (hades) to confirm, anything else cancels: hades
Rebooting hades ...
```

Wrong input cancels the reboot:

```
$ reboot
You are about to reboot: hades
Type the machine name (hades) to confirm, anything else cancels: hades2
Reboot cancelled.
```

## Files

| File      | Purpose                                        |
|-----------|------------------------------------------------|
| `reboot`  | The wrapper installed to `/usr/local/sbin`     |
| `install.sh` | Installs and uninstalls the wrapper         |
