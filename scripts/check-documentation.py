"""Check rendered tutorial structure and typecheck every standalone DocC Swift sample."""

import json
from pathlib import Path
import subprocess
import sys
import shutil


def tutorial_errors(page):
    errors = []
    for section in page.get("sections", []):
        for task in section.get("tasks", []):
            if not task.get("contentSection"):
                errors.append("tutorial section has no introduction")
            steps = task.get("stepsSection", [])
            if not steps:
                errors.append("tutorial section has no steps")
            for step in steps:
                code = step.get("code")
                if code and code not in page.get("references", {}):
                    errors.append(f"missing code reference: {code}")
    return errors


def check():
    root = Path(__file__).resolve().parents[1]
    scratch = root / ".build/docs"
    build = Path(subprocess.check_output(
        ["swift", "build", "--scratch-path", scratch, "--show-bin-path"], cwd=root, text=True
    ).strip())
    flags = set()
    description_path = build / "description.json"
    if description_path.exists():
        description = json.loads(description_path.read_text())
        # Reuse SwiftPM's SDK, testing framework, C module, and macro search paths.
        for command in description["swiftCommands"].values():
            command_args = command["otherArguments"]
            for index, flag in enumerate(command_args[:-1]):
                value = command_args[index + 1]
                if flag in ("-I", "-F", "-sdk", "-plugin-path") and value != "-Xcc":
                    flags.add((flag, value))

    output = build.parents[1]
    modules = build / "Modules" if (build / "Modules").exists() else build
    module_cache = (
        output / "ModuleCache.noindex"
        if (output / "ModuleCache.noindex").exists()
        else build / "ModuleCache"
    )
    args = ["swiftc", "-typecheck", "-swift-version", "6", "-I", str(modules),
            "-module-cache-path", str(module_cache)]
    if sys.platform == "darwin":
        platform_path = subprocess.check_output(
            ["xcrun", "--show-sdk-platform-path"], text=True
        ).strip()
        args.extend(["-F", str(Path(platform_path) / "Developer/Library/Frameworks")])
        swiftc = Path(subprocess.check_output(["xcrun", "--find", "swiftc"], text=True).strip())
        plugin = swiftc.parents[2] / "usr/lib/swift/host/plugins/testing"
        server = subprocess.check_output(["xcrun", "--find", "swift-plugin-server"], text=True).strip()
        if plugin.exists():
            args.extend(["-external-plugin-path", f"{plugin}#{server}"])
    macro = next(
        (path for path in (build / "RobinMacros-tool", build / "RobinMacros") if path.exists()),
        None,
    )
    if macro:
        args.extend(["-load-plugin-executable", str(macro) + "#RobinMacros"])
    for flag in sorted(flags):
        if flag[0] == "-plugin-path":
            if sys.platform == "darwin":
                server = subprocess.check_output(
                    ["xcrun", "--find", "swift-plugin-server"], text=True
                ).strip()
            else:
                server = shutil.which("swift-plugin-server")
            args.extend(["-external-plugin-path", flag[1] + "#" + str(server)])
        else:
            args.extend(flag)
    # Host-tool and target maps define the same C modules; prefer the tool variant.
    maps = list(build.glob("*-tool.build/module.modulemap"))
    maps += [
        path for path in build.glob("*.build/module.modulemap")
        if not (build / (path.parent.stem + "-tool.build") / "module.modulemap").exists()
    ]
    maps += list((output / "Intermediates.noindex/GeneratedModuleMaps").glob("*.modulemap"))
    maps += list((root / "Sources").rglob("module.modulemap"))
    maps += list((scratch / "checkouts").rglob("module.modulemap"))
    for path in sorted(maps):
        args.extend(["-Xcc", "-fmodule-map-file=" + str(path.resolve())])
    args.extend(["-Xcc", "-I" + str(scratch / "checkouts/swift-cmark/src/include")])
    failures = []
    samples = sorted((root / "Sources").glob("**/Documentation.docc/**/*.swift"))
    for path in samples:
        command = args + (["-parse-as-library"] if "@main" in path.read_text() else [])
        result = subprocess.run(command + [str(path)], capture_output=True, text=True)
        if result.returncode:
            failures.append(f"{path.relative_to(root)}:\n{result.stderr}")
    tutorials = list((root / ".robin/site/reference").glob("*/data/tutorials/**/*.json"))
    if not tutorials:
        failures.append("No rendered tutorials found; run mise run docs first.")
    for path in tutorials:
        for error in tutorial_errors(json.loads(path.read_text())):
            failures.append(f"{path.relative_to(root)}: {error}")
    if failures:
        sys.exit("\n".join(failures))
    print(f"Checked {len(samples)} Swift samples and {len(tutorials)} tutorial pages.")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        assert tutorial_errors({"sections": [{"tasks": [{"contentSection": [], "stepsSection": []}]}]})
        assert not tutorial_errors({"sections": [{"tasks": [{
            "contentSection": [{"content": []}], "stepsSection": [{"code": "sample"}]
        }]}], "references": {"sample": {}}})
        assert tutorial_errors({"sections": [{"tasks": [{
            "contentSection": [{}], "stepsSection": [{"code": "missing"}]
        }]}]})
    else:
        check()
