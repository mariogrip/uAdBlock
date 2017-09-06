import QtQuick 2.4
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
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

    Settings {
        id: settings

        property string lastUpdate: "Never"
    }

    property var source: 'https://raw.githubusercontent.com/mariogrip/uAdBlock/master/host-files/hosts'
    property var updateFile: "https://raw.githubusercontent.com/mariogrip/uAdBlock/master/host-files/updated"
    property var target: '/etc/hosts'
    property var blocklist: '/etc/hosts.blocklist'
    property var blocklistEnabled: '/etc/hosts.blocklist-enabled'
    property var original: '/etc/hosts.without-adblock'

    property var cmdList: []

    property var uBlockEnabled: false
    property var noUpdate: false

    function checkForNewVersion(cb)
    {
        aIndicator.visible = true;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                var newVersion = xhr.responseText;
                aIndicator.visible = false;
                cb(newVersion);
            }
        }
        xhr.open('GET', updateFile, true);
        xhr.send(null);
    }

    function nextCmd(){
        if (cmdList.length == 0)
            return done();
        var next= cmdList.shift()
        console.log("next", next)
        cmd.sudo(next)
    }

    function done(){
        uBlockEnabled = cmd.fileExists(blocklistEnabled)
        if (uBlockEnabled) {
            checkForNewVersion(function(newVersion) {
                settings.lastUpdate = newVersion
                lastUpdated.value = timeConverter(settings.lastUpdate)
            })
        }else{
            aIndicator.visible = false;
        }

    }

    function sudo(cmd){
        cmdList.push(cmd)
    }

    function mount(){
        sudo("mount -o rw,remount /")
    }

    function block(){
        aIndicator.visible = true;
        mount()
        sudo("wget " + source + " -O " + blocklist)
        if (!cmd.fileExists(original))
            sudo("cp " + target + " " + original)

        sudo("cp " + blocklist + " " + target)
        sudo("touch "+ blocklistEnabled)
        nextCmd()
    }

    function unblock(){
        aIndicator.visible = true;
        mount()
        sudo("cp " + original + " " + target)
        sudo("rm "+ blocklistEnabled)
        nextCmd()
    }

    function timeConverter(UNIX_timestamp){
      if (!(new Date(UNIX_timestamp * 1000)).getTime() > 0)
          return "Never"
      var a = new Date(UNIX_timestamp * 1000);
      var months = [i18n.tr('Jan'), i18n.tr('Feb'), i18n.tr('Mar'), i18n.tr('Apr'), i18n.tr('May'), i18n.tr('Jun'), i18n.tr('Jul'), i18n.tr('Aug'), i18n.tr('Sep'), i18n.tr('Oct'), i18n.tr('Nov'), i18n.tr('Dec')];
      var year = a.getFullYear();
      var month = months[a.getMonth()];
      var date = a.getDate();
      var hour = a.getHours();
      var min = a.getMinutes();
      var sec = a.getSeconds();
      var time = date + ' ' + month + ' ' + year + ' ' + hour + ':' + min + ':' + sec ;
      return time;
    }

    Page {
        title: i18n.tr("uAdBlock")

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

        Flickable {
            anchors.fill: parent
            visible: !aIndicator.visible

            Column {
                id: configuration
                anchors.fill: parent


                ListItem.SingleValue {
                    objectName: "WarningItem"
                    height: warningColumn.childrenRect.height + units.gu(2)

                    Column {
                        anchors.fill: parent
                        anchors.topMargin: units.gu(1)

                        id: warningColumn
                        spacing: units.gu(2)
                        Icon {
                            id: warnIcon
                            width: parent.width/4
                            height: width
                            name: "security-alert"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            id: warnText
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: i18n.tr("Please note that this app will modify your readonly filesystem")
                        }
                    }
                }

                ListItem.Standard {
                    text: i18n.tr("uAdBlock enabled")
                    enabled: true
                    control: Switch {
                        id: enableSw
                        checked: uBlockEnabled
                        onClicked: {
                            if(uBlockEnabled){
                                unblock()
                            } else {
                                block()
                            }
                        }
                    }
                    Component.onCompleted: {
                        uBlockEnabled = cmd.fileExists(blocklistEnabled)
                    }
                }

                ListItem.SingleValue {
                    id: lastUpdated
                    enabled: uBlockEnabled
                    objectName: "lastUpdate"
                    text: i18n.tr("Last updated")
                    value: {
                        return timeConverter(settings.lastUpdate)
                    }
                }

                ListItem.SingleValue {
                    text: i18n.tr("Check for update")
                    progression: !noUpdate
                    enabled: uBlockEnabled
                    onClicked: {
                        checkForNewVersion(function(newVersion) {
                            if (newVersion !== settings.lastUpdate){
                                var popup = PopupUtils.open(newVersionPopup)
                                popup.accepted.connect(function() {
                                    block()
                                })
                                popup.rejected.connect(function() {
                                     console.log("nope")
                                })
                            }
                            noUpdate = true
                            value = i18n.tr("No update available")
                        })
                    }
                }


                Label {
                    text: i18n.tr("Error")
                    color: "red"
                    visible: false
                    id: error
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: button.bottom
                    }
                }

                TextArea {
                    id: errorLog
                    visible: false
                    readOnly: true
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: error.bottom
                    }
                }

            }
        }


        Cmd {
            id: cmd

            onFinished: {
                if (!success){
                    cmdList = []
                    nextCmd();
                    error.visible = true;
                    errorLog.visible = true;
                    errorLog.text = stdout
                    return;
                }

                if (!busy)
                    nextCmd()
            }

            onPasswordRequested: {
                var popup = PopupUtils.open(passwordPopup)
                popup.accepted.connect(function(password) {
                    cmd.providePassword(password);
                })
                popup.rejected.connect(function() {
                    cmdList = []
                    nextCmd();
                    cmd.cancel();
                })
            }
        }

        Component {
            id: newVersionPopup
            Dialog {
                id: newVersionDialog
                title: i18n.tr("New version available")
                text: i18n.tr("New adblock list available, Want to update?")

                signal accepted()
                signal rejected()

                Button {
                    text: i18n.tr("Yes")
                    color: UbuntuColors.green
                    onClicked: {
                        newVersionDialog.accepted()
                        PopupUtils.close(newVersionDialog)
                    }
                }
                Button {
                    text: i18n.tr("No")
                    color: UbuntuColors.red
                    onClicked: {
                        newVersionDialog.rejected();
                        PopupUtils.close(newVersionDialog)
                    }
                }
            }
        }

        Component {
            id: passwordPopup
            Dialog {
                id: passwordDialog
                title: i18n.tr("Enter password")
                text: i18n.tr("Your password is required for this action:")

                signal accepted(string password)
                signal rejected()

                TextField {
                    id: passwordTextField
                    echoMode: TextInput.Password
                }
                Button {
                    text: i18n.tr("OK")
                    color: UbuntuColors.green
                    onClicked: {
                        passwordDialog.accepted(passwordTextField.text)
                        PopupUtils.close(passwordDialog)
                    }
                }
                Button {
                    text: i18n.tr("Cancel")
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


