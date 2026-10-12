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
    }

    // Reprogramming the address takes the adapter away and back, which BlueZ
    // reports like any power change.
    Connections {
        target: BluetoothService

        function onAdapterChanged() {
            Core.refresh();
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
            failures[controller.factory] = true;
            if (!reportedFailures[controller.factory])
                ToastService.showError(I18n.trFor("btAddress", "Bluetooth address not applied"), I18n.trFor("btAddress", "%1 keeps its factory address %2: %3").arg(controller.name).arg(controller.factory).arg(controller.error));
        }
        reportedFailures = failures;
    }
}
