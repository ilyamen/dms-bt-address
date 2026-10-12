import QtQuick
import qs.Common

QtObject {
    function check(done) {
        Proc.runCommand("btAddress.depCheck", ["sh", "-c", "command -v python3 && command -v pkexec"], (stdout, exitCode) => {
            if (exitCode === 0) {
                done(null);
                return;
            }
            done({
                "title": I18n.trFor("btAddress", "python3 and pkexec are required"),
                "details": I18n.trFor("btAddress", "The address service is a Python script and changing the address needs root through polkit. Install python3 and polkit, then re-enable the plugin.")
            });
        });
    }
}
