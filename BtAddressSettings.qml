import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "BtAddressCore.js" as Core

// Nothing here is stored by DMS: addresses live in the system service's config,
// which every change goes through with pkexec.
PluginSettings {
    id: root

    pluginId: "btAddress"

    readonly property var shared: PluginService.globalVars["btAddress"] ?? ({})
    readonly property var status: shared.status ?? null
    readonly property bool busy: shared.busy === true
    readonly property string errorText: shared.error ?? ""
    readonly property var installed: status?.installed ?? null
    readonly property bool upToDate: installed !== null && installed.version === status.version
    readonly property bool ready: upToDate && status.running

    Component.onCompleted: {
        Core.init(Proc, PluginService);
        Core.refresh();
    }

    StyledText {
        width: parent.width
        text: I18n.trFor("btAddress", "Give the Bluetooth adapter an address of your own, for example so Windows and Linux on one machine stop overwriting each other's pairings. Devices know the computer by its address, so pair them again after changing it.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: serviceColumn.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: serviceColumn

            x: Theme.spacingM
            y: Theme.spacingM
            width: parent.width - Theme.spacingM * 2
            spacing: Theme.spacingS

            Row {
                spacing: Theme.spacingS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.ready ? "check_circle" : "warning"
                    size: Theme.iconSize
                    color: root.ready ? Theme.success : Theme.warning
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (!root.status)
                            return I18n.trFor("btAddress", "Checking the service…");
                        if (!root.installed)
                            return I18n.trFor("btAddress", "Service not installed");
                        if (!root.upToDate)
                            return I18n.trFor("btAddress", "Service out of date: %1 installed, %2 available").arg(root.installed.version).arg(root.status.version);
                        if (!root.status.running)
                            return I18n.trFor("btAddress", "Service not running");
                        return I18n.trFor("btAddress", "Service running");
                    }
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }
            }

            StyledText {
                width: parent.width
                visible: !root.ready
                text: I18n.trFor("btAddress", "A small system service sets the address again whenever the adapter powers on, since many adapters forget it. Installing it asks for your password.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }

            DankButton {
                visible: root.status !== null && !root.ready
                enabled: !root.busy
                text: !root.installed ? I18n.trFor("btAddress", "Install service") : !root.upToDate ? I18n.trFor("btAddress", "Update service") : I18n.trFor("btAddress", "Restart service")
                iconName: "download"
                onClicked: Core.installService()
            }
        }
    }

    StyledText {
        width: parent.width
        visible: root.status?.error ?? false
        text: I18n.trFor("btAddress", "Can't read the Bluetooth controllers: %1").arg(root.status?.error ?? "")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.error
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        visible: root.status !== null && !root.status.error && (root.status.controllers ?? []).length === 0
        text: I18n.trFor("btAddress", "No Bluetooth adapters found.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Repeater {
        model: root.status?.controllers ?? []

        StyledRect {
            id: card

            required property var modelData
            readonly property bool managed: modelData.target !== null

            width: parent.width
            height: cardColumn.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: cardColumn

                x: Theme.spacingM
                y: Theme.spacingM
                width: parent.width - Theme.spacingM * 2
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingS

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: card.modelData.powered ? "bluetooth" : "bluetooth_disabled"
                        size: Theme.iconSize
                        color: Theme.surfaceText
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "%1 · hci%2 · %3".arg(card.modelData.name).arg(card.modelData.index).arg(card.modelData.manufacturer)
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }
                }

                StyledText {
                    text: card.modelData.factory ? I18n.trFor("btAddress", "Factory address: %1").arg(card.modelData.factory) : I18n.trFor("btAddress", "Factory address: known after Bluetooth is turned off and on")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    width: parent.width
                    text: {
                        switch (card.modelData.state) {
                        case "applied":
                            return I18n.trFor("btAddress", "Using %1").arg(card.modelData.target);
                        case "pending":
                            return card.modelData.powered ? I18n.trFor("btAddress", "Applying %1…").arg(card.modelData.target) : I18n.trFor("btAddress", "%1 is applied when Bluetooth is turned on").arg(card.modelData.target);
                        case "failed":
                            return I18n.trFor("btAddress", "%1 not applied: %2").arg(card.modelData.target).arg(card.modelData.error);
                        default:
                            return I18n.trFor("btAddress", "Using the factory address");
                        }
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: card.modelData.state === "failed" ? Theme.error : card.modelData.state === "applied" ? Theme.success : Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    width: parent.width
                    visible: !card.modelData.canSetAddress
                    text: I18n.trFor("btAddress", "The driver of this adapter can't change its address.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: card.modelData.canSetAddress

                    DankTextField {
                        id: addressField

                        width: parent.width - applyButton.width - (resetButton.visible ? resetButton.width + parent.spacing : 0) - parent.spacing
                        // The address in use, or the last one used, or the factory one:
                        // something to edit rather than type from scratch
                        text: card.modelData.target ?? card.modelData.lastAddress ?? card.modelData.factory ?? card.modelData.address
                        placeholderText: "XX:XX:XX:XX:XX:XX"
                        maximumLength: 17
                        onAccepted: if (applyButton.enabled) applyButton.clicked()
                    }

                    DankButton {
                        id: applyButton

                        anchors.verticalCenter: parent.verticalCenter
                        enabled: root.ready && !root.busy && Core.isValid(addressField.text) && (Core.normalize(addressField.text) !== (card.modelData.target ?? card.modelData.address) || card.modelData.state === "failed")
                        text: I18n.trFor("btAddress", "Apply")
                        onClicked: Core.setAddress(card.modelData.device, Core.normalize(addressField.text))
                    }

                    DankButton {
                        id: resetButton

                        anchors.verticalCenter: parent.verticalCenter
                        visible: card.managed
                        enabled: root.ready && !root.busy
                        text: I18n.trFor("btAddress", "Factory")
                        onClicked: Core.resetAddress(card.modelData.device)
                    }
                }
            }
        }
    }

    StyledText {
        width: parent.width
        visible: root.errorText !== ""
        text: root.errorText
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.error
        wrapMode: Text.WordWrap
    }

    DankButton {
        visible: root.installed !== null
        enabled: !root.busy
        text: I18n.trFor("btAddress", "Remove service")
        iconName: "delete"
        onClicked: Core.uninstallService()
    }
}
