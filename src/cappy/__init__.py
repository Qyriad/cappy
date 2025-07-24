import argparse
from enum import StrEnum, auto
import functools
import getpass
import os
import shlex
import shutil
import sys

class Capability(StrEnum):
    audit_control = auto()
    audit_read = auto()
    audit_write = auto()
    block_suspend = auto()
    bpf = auto()
    checkpoint_restore = auto()
    chown = auto()
    dac_override = auto()
    dac_read_search = auto()
    fowner = auto()
    fsetid = auto()
    ipc_lock = auto()
    kill = auto()
    lease = auto()
    linux_immutable = auto()
    mac_admin = auto()
    mac_override = auto()
    mknod = auto()
    net_admin = auto()
    net_bind_service = auto()
    # Apparently doesn't really exist?
    #net_broadcast = auto()
    net_raw = auto()
    perfmon = auto()
    setgid = auto()
    setfcap = auto()
    setpcap = auto()
    setuid = auto()
    sys_admin = auto()
    sys_boot = auto()
    sys_chroot = auto()
    sys_module = auto()
    sys_nice = auto()
    sys_pacct = auto()
    sys_ptrace = auto()
    sys_rawio = auto()
    sys_resource = auto()
    sys_time = auto()
    sys_tty_config = auto()
    syslog = auto()
    wake_alarm = auto()

    def full_name(self):
        return f"CAP_{str(self).upper()}"

    @classmethod
    def full_names(cls):
        return [item.full_name() for item in cls]

# These capabilities are required just for capsh to actually like. work.
BASE_CAPS = [
    Capability.setpcap,
    Capability.setuid,
    Capability.setgid,
]

def build_cmdline(new_caps: list[Capability], args: list[str]) -> list:
    base_caps = ",".join([cap.full_name() for cap in BASE_CAPS])
    caps = ",".join([cap.full_name() for cap in new_caps])

    sudo = shutil.which("sudo")
    if sudo is None:
        raise ValueError("'sudo' not found in PATH, is it installed?")
    capsh = shutil.which("capsh")
    if capsh is None:
        raise ValueError("'capsh' not found in PATH, is it installed?")

    return [
        sudo,
        capsh,
        "--keep=1",
        "--user={}".format(getpass.getuser()),
        f"--caps={base_caps}+ep {caps}=ip",
        f"--addamb={caps}",
        "--",
        "-c",
        shlex.join(args),
    ]

def main():
    # HACK
    if sys.argv[1] in ("-l", "--list"):
        print("\n".join(name.upper() for name in Capability))
        return

    parser = argparse.ArgumentParser(
        "cappy",
        description="Use capsh to run a program as the current user with with new capabilities",
    )

    parser.add_argument("-l", "--list", action="store_true",
        help="list available capabilities",
    )
    parser.add_argument("caps", type=functools.partial(str.split, sep=","),
        help="comma-separated list of capabilities to run with",
    )
    parser.add_argument("args", nargs=argparse.REMAINDER,
        help="the command-line to execute",
    )

    args = parser.parse_args()

    new_caps = [Capability(cap.lower().removeprefix("cap_")) for cap in args.caps]

    cmdline = build_cmdline(new_caps, args.args)

    quoted = " ".join([shlex.quote(arg) for arg in cmdline])

    print(f"\x1b[1m{quoted}\x1b[22m", file=sys.stderr)
    # We don't need this process anymore, so we don't need a subprocess either.
    os.execv(cmdline[0], cmdline)

if __name__ == "__main__":
    main()
