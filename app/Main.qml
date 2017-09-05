import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import UAdBlock 1.0
/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "uadblock.mariogrip"

    width: units.gu(100)
    height: units.gu(75)

    property var source: 'http://someonewhocares.org/hosts/zero/hosts'
    property var target: '/etc/hosts'
    property var blocklist: '/etc/hosts.blocklist'
    property var blocklistEnabled: '/etc/hosts.blocklist-enabled'
    property var original: '/etc/hosts.without-adblock'

    property var cmdList: []

    function nextCmd(){
        if (cmdList.length == 0)
            return done();
        var next= cmdList.shift()
        console.log("next", next)
        cmd.sudo(next)
    }

    function done(){
        aIndicator.visible = false;
        if (cmd.fileExists(blocklistEnabled)){
            label.text = i18n.tr("uAdblock is enabled")
            text = i18n.tr("Disable")
        } else {
            label.text = i18n.tr("uAdblock is disabled")
            text = i18n.tr("Enable")
        }
    }

    function sudo(cmd){
        cmdList.push(cmd)
    }

    function mount(){
        sudo("mount -o rw,remount /")
    }

    function block(){
        mount()
        sudo("wget " + source + " -O " + blocklist)
        if (!cmd.fileExists(original))
            sudo("cp " + target + " " + original)

        sudo("cp " + blocklist + " " + target)
        sudo("touch "+ blocklistEnabled)
        nextCmd()
    }

    function unblock(){
        mount()
        sudo("cp " + original + " " + target)
        sudo("rm "+ blocklistEnabled)
        nextCmd()
    }

    function update(){

    }

    Page {
        header: PageHeader {
            id: pageHeader
            title: i18n.tr("uAdBlock")
            StyleHints {
                foregroundColor: UbuntuColors.darkGrey
                backgroundColor: UbuntuColors.porcelain
                dividerColor: UbuntuColors.slate
            }
        }


        ActivityIndicator {
          id: aIndicator
          opacity: visible ? 1 : 0
          visible: false
          running: visible
          anchors {
              verticalCenter: parent.verticalCenter
              horizontalCenter: parent.horizontalCenter
          }
        }


        Label {
            id: label
            visible: !aIndicator.visible

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                topMargin: 10
            }

            text: cmd.busy
            font {
                pointSize: 50
                weight: Font.Bold
            }
        }

        Button {
            objectName: "button"
            visible: !aIndicator.visible
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: label.bottom
                topMargin: units.gu(2)
            }

            text: i18n.tr("Enable")

            Component.onCompleted: {
                if (cmd.fileExists(blocklistEnabled)){
                    label.text = i18n.tr("uAdblock is enabled")
                    text = i18n.tr("Disable")
                } else {
                    label.text = i18n.tr("uAdblock is disabled")
                    text = i18n.tr("Enable")
                }
            }

            onClicked: {
                aIndicator.visible = true;
                if (cmd.fileExists(blocklistEnabled)){
                    unblock()
                } else {
                    block()
                }
            }
        }

        Cmd {
            id: cmd

            onBusyChanged: {
                console.log("next", busy)
                if (!busy)
                    nextCmd()
            }

            onPasswordRequested: {
                var popup = PopupUtils.open(passwordPopup)
                popup.accepted.connect(function(password) {
                    cmd.providePassword(password);
                })
                popup.rejected.connect(function() {
                    cmd.cancel();
                })
            }
        }

        Component {
            id: passwordPopup
            Dialog {
                id: passwordDialog
                title: "Enter password"
                text: "Your password is required for this action:"

                signal accepted(string password)
                signal rejected()

                TextField {
                    id: passwordTextField
                }
                Button {
                    text: "OK"
                    color: UbuntuColors.green
                    onClicked: {
                        passwordDialog.accepted(passwordTextField.text)
                        PopupUtils.close(passwordDialog)
                    }
                }
                Button {
                    text: "Cancel"
                    color: UbuntuColors.red
                    onClicked: {
                        passwordDialog.rejected();
                        PopupUtils.close(passwordDialog)
                    }
                }
            }
    }
}
}


