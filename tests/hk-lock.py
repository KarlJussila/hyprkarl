#!/usr/bin/env python3
"""Exercise the locker with controlled compositor, PAM, and sleep boundaries."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import time

REPO = Path(__file__).resolve().parent.parent


class LogindFixture:
    """Serve real logind-shaped D-Bus signals on an isolated bus."""

    def __enter__(self):
        from gi.repository import Gio, GLib

        self.glib = GLib
        self.preparing = False
        self.daemon = subprocess.Popen(
            ["dbus-daemon", "--session", "--nofork", "--print-address=1"],
            stdout=subprocess.PIPE, text=True)
        self.address = self.daemon.stdout.readline().strip()
        self.connection = Gio.DBusConnection.new_for_address_sync(
            self.address,
            Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT
            | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION, None, None)
        self.connection.call_sync(
            "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
            "RequestName", GLib.Variant("(su)", ("org.freedesktop.login1", 0)),
            None, Gio.DBusCallFlags.NONE, -1, None)
        interface = Gio.DBusNodeInfo.new_for_xml('''<node>
          <interface name="org.freedesktop.login1.Manager">
            <property name="PreparingForSleep" type="b" access="read"/>
            <signal name="PrepareForSleep"><arg type="b"/></signal>
          </interface>
        </node>''').interfaces[0]
        self.connection.register_object(
            "/org/freedesktop/login1", interface, None,
            lambda *_: GLib.Variant("b", self.preparing), None)
        self.loop = GLib.MainLoop()
        self.thread = threading.Thread(target=self.loop.run)
        self.thread.start()
        return self

    def sleep(self, preparing):
        self.preparing = preparing
        self.connection.emit_signal(
            None, "/org/freedesktop/login1", "org.freedesktop.login1.Manager",
            "PrepareForSleep", self.glib.Variant("(b)", (preparing,)))

    def __exit__(self, *_):
        self.connection.close_sync(None)
        self.loop.quit()
        self.thread.join()
        self.daemon.terminate()
        self.daemon.wait()


def wait_for(condition, timeout=3):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if condition():
            return
        time.sleep(0.05)
    raise AssertionError("Timed out waiting for locker state")


def main():
    with LogindFixture() as logind, tempfile.TemporaryDirectory(prefix="hk-lock-test-") as directory:
        root = Path(directory)
        locker = root / "repo/config/quickshell"
        shutil.copytree(REPO / "config/quickshell", locker, symlinks=True)
        shutil.copytree(REPO / "defaults", root / "repo/defaults")
        # Change only the external compositor import; exercise production QML logic.
        entry = locker / "lock.qml"
        entry.write_text(entry.read_text().replace(
            "import Quickshell.Wayland", "import FixtureWayland"))
        state = locker / "modules/lock/LockState.qml"
        state.write_text(state.read_text().replace("  id: root", """  id: root
  onFingerprintBusyChanged: Quickshell.execDetached([
    "fixture-log", fingerprintBusy ? "start" : "stop", "fingerprint", String(Date.now())
  ])""", 1))

        settings = root / "config/quickshell/settings"
        settings.mkdir(parents=True)
        (settings / "shell.json").write_text('{"version":1,"lock":{"fingerprintEnabled":false}}\n')
        pam = root / "config/quickshell/pam"
        pam.mkdir()
        fingerprint_policy = pam / "fingerprint"
        fingerprint_policy.write_text("auth required pam_unix.so\n")
        current = root / "state/hyprkarl/current"
        artifact = root / "state/hyprkarl/themes/test"
        current.mkdir(parents=True)
        artifact.mkdir(parents=True)
        theme = REPO / "tests/fixtures/quickshell-modules"
        shutil.copy(theme / "theme.json", current)
        shutil.copy(theme / "quickshell.json", artifact)

        commands = root / "bin"
        commands.mkdir()
        recorder = commands / "record"
        recorder.write_text('''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys
command = Path(sys.argv[0]).name
if command == "systemctl":
    assert sys.argv[1:] == ["suspend"]
    assert Path(os.environ["LOCK_TEST_GATE"]).read_text() == "secure"
with open(os.environ["LOCK_TEST_EVENTS"], "a") as stream:
    stream.write(json.dumps([command, *sys.argv[1:]]) + "\\n")
''')
        recorder.chmod(0o755)
        for command in ("systemctl", "hyprctl", "fixture-log"):
            (commands / command).symlink_to(recorder)

        gate = root / "gate"
        events = root / "events"
        gate.write_text("pending")
        events.touch()
        env = dict(
            os.environ,
            HYPRKARL_PATH=str(REPO),
            HYPRKARL_LOCK_SOURCE=str(entry),
            XDG_CONFIG_HOME=str(root / "config"),
            XDG_STATE_HOME=str(root / "state"),
            QML_IMPORT_PATH=str(REPO / "tests/fixtures/quickshell-lock"),
            QT_QPA_PLATFORM="offscreen",
            QT_QUICK_BACKEND="software",
            LOCK_TEST_GATE=str(gate),
            LOCK_TEST_EVENTS=str(events),
            DBUS_SYSTEM_BUS_ADDRESS=logind.address,
            PATH=f"{commands}:{REPO / 'bin'}:{os.environ['PATH']}",
        )

        def run(*args, check=True):
            return subprocess.run(args, env=env, check=check, capture_output=True,
                                  text=True, timeout=10)

        def instances():
            output = run("qs", "list", "--all", "--json").stdout
            return [instance for instance in json.loads(output)
                    if instance["config_path"] == str(entry)]

        def actions():
            return [json.loads(line) for line in events.read_text().splitlines()]

        def suspend_count():
            return actions().count(["systemctl", "suspend"])

        def stop():
            if instances():
                run("qs", "-p", str(entry), "kill")
                wait_for(lambda: not instances())

        try:
            run(str(REPO / "bin/hk-suspend"))
            initial = instances()
            assert len(initial) == 1
            assert initial[0]["id"] not in run(
                "qs", "list", "-p", str(locker), "--json").stdout, \
                "Desktop-shell commands selected the lock entry point"
            assert not actions(), "An action ran before compositor confirmation"
            run(str(REPO / "bin/hk-lock"))
            run(str(REPO / "bin/hk-suspend"))
            assert instances()[0]["id"] == initial[0]["id"]
            assert not actions(), "Repeated requests bypassed secure locking"

            gate.write_text("secure")
            wait_for(lambda: suspend_count() == 1)
            wait_for(lambda: ["hyprctl", "switchxkblayout", "all", "0"] in actions())
            run(str(REPO / "bin/hk-suspend"))
            wait_for(lambda: suspend_count() == 2)
            assert actions().count(["hyprctl", "switchxkblayout", "all", "0"]) == 1
            assert len(instances()) == 1
            print("PASS: pending and already-secure requests reuse one locker")
            stop()

            gate.write_text("pending")
            events.write_text("")
            run(str(REPO / "bin/hk-suspend"))
            wait_for(lambda: not instances(), timeout=8)
            assert not actions(), "An unconfirmed lock allowed suspension"
            print("PASS: failed compositor confirmation never suspends")

            (settings / "shell.json").write_text('{"version":1,"lock":{"fingerprintEnabled":true}}\n')
            events.write_text("")
            gate.write_text("secure")

            def fingerprint_actions(action):
                return [event for event in actions()
                        if event[:3] == ["fixture-log", action, "fingerprint"]]

            run(str(REPO / "bin/hk-lock"))
            wait_for(lambda: len(fingerprint_actions("start")) == 1)
            logind.sleep(True)
            wait_for(lambda: len(fingerprint_actions("stop")) == 1)
            time.sleep(0.3)
            assert len(fingerprint_actions("start")) == 1
            logind.sleep(False)
            wait_for(lambda: len(fingerprint_actions("start")) == 2)

            run(str(REPO / "bin/hk-suspend"))
            wait_for(lambda: len(fingerprint_actions("stop")) == 2)
            time.sleep(0.3)
            assert len(fingerprint_actions("start")) == 2
            logind.sleep(True)
            logind.sleep(False)
            wait_for(lambda: len(fingerprint_actions("start")) == 3)
            print("PASS: fingerprint stops before sleep and starts fresh on resume")
            (settings / "shell.json").write_text('{"version":1,"lock":{"fingerprintEnabled":false}}\n')
            wait_for(lambda: len(fingerprint_actions("stop")) == 3)
            logind.sleep(True)
            logind.sleep(False)
            time.sleep(0.3)
            assert len(fingerprint_actions("start")) == 3
            print("PASS: disabling fingerprint stops scanning and keeps resume inert")
            stop()
            (settings / "shell.json").write_text('{"version":1,"lock":{"fingerprintEnabled":true}}\n')

            events.write_text("")
            logind.sleep(True)
            run(str(REPO / "bin/hk-lock"))
            time.sleep(0.3)
            assert not fingerprint_actions("start")
            logind.sleep(False)
            wait_for(lambda: len(fingerprint_actions("start")) == 1)
            print("PASS: a locker launched during sleep preparation waits for resume")
            stop()

            events.write_text("")
            fingerprint_policy.write_text("auth required /nonexistent/hyprkarl-test-pam.so\n")
            run(str(REPO / "bin/hk-lock"))
            wait_for(lambda: len(fingerprint_actions("start")) >= 3, timeout=5)
            starts = fingerprint_actions("start")
            assert int(starts[1][3]) - int(starts[0][3]) >= 1000
            assert int(starts[2][3]) - int(starts[1][3]) >= 2000
            stop()
            print("PASS: reader errors retry with increasing recovery time")

            entry.write_text("this is invalid QML\n")
            events.write_text("")
            assert run(str(REPO / "bin/hk-suspend"), check=False).returncode != 0
            assert not actions(), "Broken QML allowed suspension"
            print("PASS: failed QML startup never suspends")
        except Exception:
            print(run("qs", "-p", str(entry), "log", "--tail", "40", check=False).stdout)
            print("Recorded actions:", actions())
            raise
        finally:
            stop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
