import io
import sys
from pathlib import Path

import numpy


def _replace_once(content: str, old: str, new: str, label: str) -> str:
    if old not in content:
        raise RuntimeError(f"missing expected block for {label}")
    if new in content:
        return content
    return content.replace(old, new, 1)


def patch_f2py2e(path: Path) -> None:
    content = path.read_text(encoding="utf-8")
    content = _replace_once(
        content,
        "    parser.add_argument(\"--backend\", choices=['meson', 'distutils'], default='distutils')\n"
        "    parser.add_argument(\"-m\", dest=\"module_name\")\n"
        "    return parser\n",
        "    parser.add_argument(\"--backend\", choices=['meson', 'distutils'], default='distutils')\n"
        "    parser.add_argument(\"--native-file\", dest=\"native_file\")\n"
        "    parser.add_argument(\"-m\", dest=\"module_name\")\n"
        "    return parser\n",
        "make_f2py_compile_parser",
    )
    content = _replace_once(
        content,
        "        \"dependencies\": args.dependencies or [],\n"
        "        \"backend\": backend_key,\n"
        "        \"modulename\": args.module_name,\n"
        "    }\n",
        "        \"dependencies\": args.dependencies or [],\n"
        "        \"backend\": backend_key,\n"
        "        \"modulename\": args.module_name,\n"
        "        \"native_file\": args.native_file,\n"
        "    }\n",
        "preparse_sysargv return",
    )
    content = _replace_once(
        content,
        "    dependencies = argy[\"dependencies\"]\n"
        "    backend_key = argy[\"backend\"]\n",
        "    dependencies = argy[\"dependencies\"]\n"
        "    native_file = argy[\"native_file\"]\n"
        "    backend_key = argy[\"backend\"]\n",
        "run_compile deps",
    )
    content = _replace_once(
        content,
        "        {\"dependencies\": dependencies},\n",
        "        {\"dependencies\": dependencies, \"native_file\": native_file},\n",
        "build_backend extra_dat",
    )
    path.write_text(content, encoding="utf-8")


def patch_meson_backend(path: Path) -> None:
    content = path.read_text(encoding="utf-8")
    content = _replace_once(
        content,
        "        setup_command = [\"meson\", \"setup\", self.meson_build_dir]\n"
        "        self._run_subprocess_command(setup_command, build_dir)\n",
        "        setup_command = [\"meson\", \"setup\", self.meson_build_dir]\n"
        "        native_file = self.extra_dat.get(\"native_file\")\n"
        "        if native_file:\n"
        "            setup_command += [\"--native-file\", native_file]\n"
        "        self._run_subprocess_command(setup_command, build_dir)\n",
        "run_meson",
    )
    path.write_text(content, encoding="utf-8")


def main() -> int:
    numpy_root = Path(numpy.__file__).parent
    f2py2e_path = numpy_root / "f2py" / "f2py2e.py"
    meson_path = numpy_root / "f2py" / "_backends" / "_meson.py"
    if not f2py2e_path.exists():
        raise FileNotFoundError(f"Missing {f2py2e_path}")
    if not meson_path.exists():
        raise FileNotFoundError(f"Missing {meson_path}")
    patch_f2py2e(f2py2e_path)
    patch_meson_backend(meson_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
