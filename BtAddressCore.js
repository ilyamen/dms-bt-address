.pragma library

// Shared by the background component and the settings page: runs the helper and
// publishes its status through PluginService global vars, so both update together.

var PLUGIN_ID = "btAddress";
var ADDRESS_RE = /^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/;
// pkexec exits with 126 when the password dialog is dismissed
var PKEXEC_DISMISSED = 126;

var proc = null;
var store = null;

function init(procSingleton, pluginService) {
    proc = procSingleton;
    store = pluginService;
}

function publish(key, value) {
    if (store)
        store.setGlobalVar(PLUGIN_ID, key, value);
}

function current(key, fallback) {
    return store ? store.getGlobalVar(PLUGIN_ID, key, fallback) : fallback;
}

function pluginDir() {
    return store?.availablePlugins[PLUGIN_ID]?.pluginDirectory ?? "";
}

// `status` needs no privileges, and the copy shipped with the plugin also reports
// which version of the service is installed, so it works before installing too.
function refresh() {
    if (!proc)
        return;
    proc.runCommand("btAddress.status", ["python3", "-I", pluginDir() + "/system/dms-bt-addr", "status"], (output, exitCode) => {
        if (exitCode !== 0) {
            publish("status", null);
            return;
        }
        try {
            publish("status", JSON.parse(output));
        } catch (e) {
            publish("status", null);
        }
    }, 300);
}

// Privileged commands go through pkexec, so the DMS polkit agent asks for the
// password. stderr is folded into stdout to show why a command failed.
function runPrivileged(id, command) {
    if (!proc || current("busy", false))
        return;
    publish("busy", true);
    publish("error", "");
    proc.runCommand(id, ["sh", "-c", "exec pkexec \"$@\" 2>&1", "sh"].concat(command), (output, exitCode) => {
        publish("busy", false);
        if (exitCode !== 0 && exitCode !== PKEXEC_DISMISSED)
            publish("error", output.trim() || ("exit code " + exitCode));
        refresh();
    }, 0, proc.noTimeout);
}

function helperPath() {
    return current("status", null)?.installed?.path ?? "";
}

function setAddress(device, address) {
    runPrivileged("btAddress.set", [helperPath(), "set", device, address]);
}

function resetAddress(device) {
    runPrivileged("btAddress.reset", [helperPath(), "reset", device]);
}

function installService() {
    runPrivileged("btAddress.install", ["/bin/sh", pluginDir() + "/system/install.sh", "install"]);
}

function uninstallService() {
    runPrivileged("btAddress.uninstall", ["/bin/sh", pluginDir() + "/system/install.sh", "uninstall"]);
}

function normalize(address) {
    return address.trim().toUpperCase().replace(/-/g, ":");
}

function isValid(address) {
    const normalized = normalize(address);
    return ADDRESS_RE.test(normalized) && normalized !== "00:00:00:00:00:00" && normalized !== "FF:FF:FF:FF:FF:FF";
}
