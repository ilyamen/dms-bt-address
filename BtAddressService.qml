import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "BtAddressCore.js" as Core

// The address itself is kept by the system service; this only follows its status
// for the settings page and reports when it gives up on a controller.
PluginComponent {
    id: root

    readonly property var status: PluginService.globalVars["btAddress"]?.status ?? null
    property var reportedFailures: ({})

    Component.onCompleted: {
        Core.init(Proc, PluginService);
        Core.refresh();
        powerCheck.restart();
    }

    // Quickshell builds its adapter object from BlueZ's first announcement and
    // misses a power change that follows within the same instant. That is what
    // happens when the controller comes back after suspend or an address change:
    // BlueZ announces it off and switches it on at once, so the Control Center
    // shows Bluetooth off while it is on, and the first click turns it off. Once
    // the adapter has settled, compare with BlueZ and write the real value back:
    // that corrects the tile and changes nothing in BlueZ.
    Timer {
        id: powerCheck
        interval: 2000
        onTriggered: root.syncPowered()
    }

    function syncPowered() {
        const adapter = BluetoothService.adapter;
        if (!adapter || !DMSService.isConnected)
            return;
        DMSService.dbusGetProperty("system", "org.bluez", adapter.dbusPath, "org.bluez.Adapter1", "Powered", response => {
            const powered = response?.result?.value;
            if (typeof powered !== "boolean" || BluetoothService.adapter !== adapter || adapter.enabled === powered)
                return;
            console.warn("btAddress:", adapter.dbusPath, "shown as", adapter.enabled ? "on" : "off", "while BlueZ reports it", powered ? "on" : "off", "- correcting");
            adapter.enabled = powered;
        });
    }

    // Reprogramming the address takes the adapter away and back, which BlueZ
    // reports like any power change.
    Connections {
        target: BluetoothService

        function onAdapterChanged() {
            Core.refresh();
            powerCheck.restart();
        }

        function onEnabledChanged() {
            Core.refresh();
        }
    }

    onStatusChanged: {
        const failures = {};
        for (const controller of status?.controllers ?? []) {
            if (controller.state !== "failed")
                continue;
            failures[controller.device] = true;
            if (!reportedFailures[controller.device])
                ToastService.showError(I18n.trFor("btAddress", "Bluetooth address not applied"), I18n.trFor("btAddress", "%1 stays on %2: %3").arg(controller.name).arg(controller.address).arg(controller.error));
        }
        reportedFailures = failures;
    }
}
