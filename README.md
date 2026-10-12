# Bluetooth Address for DankMaterialShell

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) plugin that gives the Bluetooth adapter an address of your choice and keeps it there.

The usual reason to want this is dual boot. Windows and Linux share one adapter, so headphones and other devices see a single computer with one address. Each OS pairs with its own link key, and every pairing overwrites the key the other OS stored. Then the device connects for a second and drops, and BlueZ logs `br-connection-key-missing`. With a different address on Linux, devices see two computers and keep a pairing for each.

## How it works

The kernel can set a controller's public address through the mgmt interface (`btmgmt public-addr`). On many adapters the address doesn't last. MediaTek MT79xx chips, for example, reload their firmware on every power-on and come back with the factory address. The kernel writes the address it was given only once, right after it is set.

The plugin installs a small system service, `dms-bt-addr`, that listens to the kernel's Bluetooth management events. Whenever a managed adapter powers on with its factory address, the service has the kernel program the chosen address again. This takes about a second, and BlueZ sees the adapter with the new address before anything connects.

There is no polling: the service sleeps until the kernel reports a change. It needs nothing beyond Python's standard library. It gives up on an adapter that keeps losing the address instead of power-cycling it forever, and it reports that in DMS.

The settings page lists every adapter. It shows whether the adapter's driver supports changing the address at all (the kernel reports this per controller), the factory address and the one in use. Changes go through polkit, so DMS asks for your password.

## Requirements

- DMS 1.6.0 or newer
- `python3` and polkit (`pkexec`)
- systemd
- A Bluetooth controller whose driver can set the public address. Most current Intel, MediaTek, Realtek, Broadcom and Qualcomm drivers can; the settings page says so if yours can't.

Tested on a MediaTek MT7925 (`btusb`/`btmtk`).

## Installation

### From a registry

In DMS Settings → Plugins, add the registry `https://github.com/ilyamen/dms-plugin-registry.git`. Then install **Bluetooth Address** from Browse, or run:

```sh
dms plugins install btAddress
```

### Manually

```sh
git clone https://github.com/ilyamen/dms-bt-address ~/.config/DankMaterialShell/plugins/btAddress
```

Enable the plugin in Settings → Plugins and open its settings. Press **Install service**, then enter an address for the adapter and press **Apply**. The field suggests the factory address with the locally administered bit set: it stays unique to your adapter and can't clash with any vendor address.

After changing the address, pair your devices again: they know the computer by its old address.

## Command line

The service and the settings page both use one script, which works on its own too:

```sh
/usr/local/libexec/dms-bt-addr status                                   # JSON, no root needed
sudo /usr/local/libexec/dms-bt-addr set 44:FA:66:66:30:D6 46:FA:66:66:30:D6
sudo /usr/local/libexec/dms-bt-addr reset 44:FA:66:66:30:D6
journalctl -u dms-bt-addr                                               # what the service did
```

The configuration is `/etc/dms-bt-addr.conf`, one `FACTORY = ADDRESS` line per adapter.

For packaging, `system/install.sh` honours `PREFIX` (default `/usr/local`).

## Removal

Press **Remove service** in the plugin settings, or run `sudo sh system/install.sh uninstall`. Adapters that reload their firmware get the factory address back the next time they power on; the others get it back after a reboot.

## License

MIT
