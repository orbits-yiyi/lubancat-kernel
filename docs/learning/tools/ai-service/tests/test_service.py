#!/usr/bin/env python3
"""Exercise process startup and staged installation without root or a real model."""
import json
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile
import unittest


TOOLS = Path(__file__).resolve().parents[1]
LAUNCHER = TOOLS / "start-ai-server.sh"
INSTALLER = TOOLS / "install-ai-service.sh"


class ServiceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="lubancat-ai-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.project = self.root / "project with spaces"
        self.server = self.project / "build/bin/llama-server"
        self.server.parent.mkdir(parents=True)
        self.model = self.project / "models/qwen2.5-0.5b-instruct-q4_k_m.gguf"
        self.model.parent.mkdir()
        self.model.write_bytes(b"GGUF test fixture; not real weights")
        self.marker = self.root / "inference-started"
        self.server.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, pathlib, sys\n"
            "pathlib.Path(os.environ['AI_TEST_MARKER']).touch()\n"
            "print(json.dumps({'args': sys.argv[1:], 'pid': os.getpid(), "
            "'cwd': os.getcwd()}))\n"
        )
        self.server.chmod(0o755)
        self.environment = os.environ.copy()
        for name in (
            "LLAMA_DIR", "MODEL_PATH", "AI_HOST", "AI_PORT", "AI_THREADS",
            "AI_CONTEXT", "AI_PREDICT", "AI_PARALLEL",
        ):
            self.environment.pop(name, None)
        self.environment.update(
            LLAMA_DIR=str(self.project), AI_TEST_MARKER=str(self.marker)
        )

    def launch(self, *arguments, environment=None):
        return subprocess.run(
            ["bash", str(LAUNCHER), *arguments],
            env=environment or self.environment, text=True,
            capture_output=True, timeout=10,
        )

    def test_exec_preserves_main_pid_and_quotes_model_path(self):
        process = subprocess.Popen(
            ["bash", str(LAUNCHER)], env=self.environment,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        output, error = process.communicate(timeout=10)
        self.assertEqual(process.returncode, 0, error)
        result = json.loads(output)
        self.assertEqual(result["pid"], process.pid)
        self.assertEqual(result["cwd"], str(self.project))
        self.assertEqual(result["args"], [
            "-m", str(self.model), "-t", "4", "-c", "4096", "-n", "1024",
            "-np", "1", "--host", "0.0.0.0", "--port", "8080",
        ])

    def test_preflight_does_not_start_inference(self):
        result = self.launch("--check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Preflight OK", result.stdout)
        self.assertFalse(self.marker.exists())

    def test_trusted_config_controls_ipv6_and_runtime_parameters(self):
        config = self.root / "server.env"
        config.write_text(
            "LLAMA_DIR=" + shlex.quote(str(self.project)) + "\n"
            "AI_HOST=::\nAI_PORT=9090\nAI_THREADS=2\nAI_CONTEXT=2048\nAI_PREDICT=256\n"
        )
        result = self.launch("--config", str(config))
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = json.loads(result.stdout)["args"]
        self.assertEqual(arguments[arguments.index("--host") + 1], "::")
        self.assertEqual(arguments[arguments.index("--port") + 1], "9090")
        self.assertEqual(arguments[arguments.index("-t") + 1], "2")
        self.assertEqual(arguments[arguments.index("-c") + 1], "2048")
        self.assertEqual(arguments[arguments.index("-n") + 1], "256")

    def test_missing_model_fails_before_start(self):
        self.model.unlink()
        result = self.launch()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("model is missing", result.stderr)
        self.assertFalse(self.marker.exists())

    def test_invalid_parameters_fail_before_start(self):
        for name, value in (
            ("AI_PORT", "0"), ("AI_PORT", "65536"), ("AI_PORT", "word"),
            ("AI_THREADS", "0"), ("AI_CONTEXT", "-1"),
            ("AI_PREDICT", "0"), ("AI_PARALLEL", "1;echo unexpected"),
        ):
            with self.subTest(name=name, value=value):
                environment = dict(self.environment, **{name: value})
                result = self.launch(environment=environment)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(name, result.stderr)
                self.assertFalse(self.marker.exists())

    def test_staged_install_preserves_config_and_backs_up_modified_unit(self):
        stage = self.root / "staged filesystem"
        trap_bin = self.root / "trap-bin"
        trap_bin.mkdir()
        systemctl_marker = self.root / "systemctl-called"
        trap = trap_bin / "systemctl"
        trap.write_text(
            "#!/bin/sh\n"
            "touch " + shlex.quote(str(systemctl_marker)) + "\nexit 99\n"
        )
        trap.chmod(0o755)
        environment = dict(self.environment)
        environment["PATH"] = str(trap_bin) + os.pathsep + environment["PATH"]
        command = ["bash", str(INSTALLER), "--destdir", str(stage)]
        first = subprocess.run(
            command, env=environment, text=True, capture_output=True, timeout=10
        )
        self.assertEqual(first.returncode, 0, first.stderr)
        launcher = stage / "usr/local/bin/lubancat-ai-start"
        config = stage / "etc/default/lubancat-ai"
        unit = stage / "etc/systemd/system/lubancat-ai.service"
        self.assertEqual(stat.S_IMODE(launcher.stat().st_mode), 0o755)
        self.assertEqual(stat.S_IMODE(config.stat().st_mode), 0o644)
        self.assertEqual(unit.read_bytes(), (TOOLS / unit.name).read_bytes())
        custom_config = "AI_PORT=9090\nAI_CONTEXT=1024\nAI_PREDICT=128\n# preserved administrator settings\n"
        config.write_text(custom_config)
        custom_unit = unit.read_text() + "\n# administrator change\n"
        unit.write_text(custom_unit)
        second = subprocess.run(
            command, env=environment, text=True, capture_output=True, timeout=10
        )
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(config.read_text(), custom_config)
        self.assertEqual(unit.read_bytes(), (TOOLS / unit.name).read_bytes())
        backups = list(unit.parent.glob(unit.name + ".bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), custom_unit)
        self.assertFalse(systemctl_marker.exists())

    def test_staging_cannot_enable_or_target_root(self):
        stage = self.root / "must-not-exist"
        for arguments in (
            ["--destdir", str(stage), "--enable"],
            ["--destdir", "/"],
        ):
            with self.subTest(arguments=arguments):
                result = subprocess.run(
                    ["bash", str(INSTALLER), *arguments],
                    text=True, capture_output=True, timeout=10,
                )
                self.assertNotEqual(result.returncode, 0)
        self.assertFalse(stage.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
