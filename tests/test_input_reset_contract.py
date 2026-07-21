import pathlib
import unittest


ROOT = pathlib.Path(__file__).parents[1]
RESET = ROOT / "app" / "linux" / "bin" / "wechat-input-reset"
STOP = ROOT / "app" / "linux" / "bin" / "wechat-desktop-stop"
DESKTOP = ROOT / "app" / "linux" / "bin" / "wechat-desktop"
STATUS = ROOT / "app" / "linux" / "bin" / "wechat-desktop-status"
WIDGET = ROOT / "app" / "windows" / "clipboard-widget.ps1"
INSTALLER = ROOT / "scripts" / "install.ps1"
LAUNCHERS = ROOT / "app" / "windows" / "launchers"


class InputResetContractTests(unittest.TestCase):
    def test_capability_check_happens_before_any_reset(self):
        script = RESET.read_text(encoding="utf-8")

        self.assertIn("Usage: wechat-input-reset [--check]", script)
        self.assertIn("framework=fcitx4", script)
        self.assertIn("input_method=sogoupinyin", script)
        self.assertLess(script.index('if [ "$check_only" -eq 1 ]'), script.index('flock -n 9'))
        self.assertLess(script.index('flock -n 9'), script.index("wechat-desktop-stop --force"))

    def test_reset_is_locked_and_scoped_to_the_managed_display(self):
        script = RESET.read_text(encoding="utf-8")

        self.assertIn('input-reset.lock', script)
        self.assertIn('process_on_display "$pid"', script)
        self.assertIn('wechat_pid_for_display', script)
        self.assertIn('fcitx_pid_for_display', script)
        self.assertIn('stale_queue_count_after_cleanup', script)

    def test_stop_does_not_use_user_wide_wechat_patterns(self):
        script = STOP.read_text(encoding="utf-8")

        self.assertIn('managed_wechat_pids', script)
        self.assertIn('$state_dir/wechat.pid', script)
        self.assertIn('process_on_display "$pid"', script)
        self.assertNotIn('pgrep -u "$uid" -x wechat', script)
        self.assertNotIn("pgrep -u \"$uid\" -f '/opt/wechat/'", script)

    def test_desktop_records_the_managed_wechat_pid(self):
        script = DESKTOP.read_text(encoding="utf-8")

        pid_write = 'printf \'%s\\n\' "$$" >"$state_dir/wechat.pid"'
        self.assertIn(pid_write, script)
        self.assertLess(script.index(pid_write), script.index('exec "$wechat_command" "$@"'))

    def test_status_reports_input_and_wechat_processes_for_the_managed_display(self):
        script = STATUS.read_text(encoding="utf-8")

        self.assertIn("pids_by_comm_on_display wechat", script)
        self.assertIn("pids_by_comm_on_display fcitx", script)
        self.assertIn('process_on_display "$pid"', script)

    def test_widget_checks_support_and_confirms_restart(self):
        script = WIDGET.read_text(encoding="utf-8")

        self.assertIn('"wechat-input-reset", "--check"', script)
        self.assertIn('重置搜狗输入法', script)
        self.assertIn('MessageBox]::Show', script)
        self.assertIn('未发送的输入内容会丢失', script)
        self.assertIn("^status=ok", script)
        self.assertLess(script.index('MessageBox]::Show'), script.index('"wechat-input-reset")'))

    def test_installer_persists_distro_for_every_distro_aware_launcher(self):
        installer = INSTALLER.read_text(encoding="utf-8")
        self.assertIn('Join-Path $InstallRoot "distro.txt"', installer)
        self.assertIn("^[A-Za-z0-9._-]+$", installer)

        distro_aware = []
        for launcher in LAUNCHERS.iterdir():
            if launcher.suffix.lower() not in {".cmd", ".vbs"}:
                continue
            text = launcher.read_text(encoding="utf-8")
            if "WSL_WECHAT_DISTRO" in text:
                distro_aware.append(launcher.name)
                self.assertIn("distro.txt", text, launcher.name)

        self.assertGreaterEqual(len(distro_aware), 10)


if __name__ == "__main__":
    unittest.main()
