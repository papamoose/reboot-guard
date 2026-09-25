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

## STIG compliance

Reviewed against the RHEL 9 (V2R9) and SLES 15 STIG control sets. The
wrapper causes no findings if you follow the steps below.

- Reboot auditing (RHEL-09-654195). The STIG audits execution of
  `/usr/sbin/reboot`. The wrapper executes that binary directly, so
  the audit record still fires. There is no audit gap.
- File integrity (RHEL-09-651010, RHEL-09-651015, SLES-15-010419).
  AIDE monitors `/usr` by default. The wrapper shows as an added file
  in AIDE reports until you update the baseline.
- File permission scans. The wrapper is 0755 root:root. It is not
  SUID, not world-writable, and not orphaned.
- SELinux. The wrapper is a plain script in the default `/usr`
  context. It runs under enforcing mode. Check the context after
  install with `ls -Z /usr/local/sbin/reboot`.

Steps for a clean scan:

1. Install with the RPM so the file is package-managed. Confirm with
   `rpm -qf /usr/local/sbin/reboot`.
2. Update the AIDE baseline: `sudo aide --update`.
3. Record the wrapper as an approved local change in the system
   security documentation.

Do not install the wrapper over `/usr/sbin/reboot`. That file belongs
to the `systemd` package. Overwriting it is a vendor-file finding and
it breaks the STIG reboot checks.

## Files

| File      | Purpose                                        |
|-----------|------------------------------------------------|
| `reboot`  | The wrapper installed to `/usr/local/sbin`     |
| `install.sh` | Installs and uninstalls the wrapper         |
