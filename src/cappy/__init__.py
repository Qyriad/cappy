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

def build_cmdline(new_caps: list[Capability], args: list[str], sudo_args: list[str]) -> list[str]:
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
        *sudo_args,
        capsh,
        "--keep=1",
        "--user={}".format(getpass.getuser()),
        f"--caps={base_caps}+ep {caps}=ip",
        f"--addamb={caps}",
        "--",
        "-c",
        shlex.join(args),
    ]

def get_parser():
    parser = argparse.ArgumentParser(
        "cappy",
        description="Use capsh to run a program as the current user with with new capabilities",
    )

    # Treat `--list` like a subcommand. ish.
    operation = parser.add_mutually_exclusive_group(required=True)
    operation.add_argument("-l", "--list", action="store_true",
        help="list available capabilities",
    )
    operation.add_argument("caps", type=functools.partial(str.split, sep=","),
        nargs='?', # Required for mutual exclusivity.
        help="comma-separated list of capabilities to run with",
    )
    parser.add_argument("args", nargs=argparse.REMAINDER,
        help="the command-line to execute",
    )
    parser.add_argument('--sudo-args', dest='sudo_args', metavar='ARGS', type=str,
        default='--preserve-env',
        help="shell-split arguments to pass to sudo (default: %(default)s)",
    )

    return parser

def main():

    parser = get_parser()
    args = parser.parse_args()


    if args.list:
        print("\n".join(name.upper() for name in Capability))
        return

    new_caps = [Capability(cap.lower().removeprefix("cap_")) for cap in args.caps]

    sudo_args = []
    if args.sudo_args:
        sudo_args = shlex.split(args.sudo_args)

    cmdline = build_cmdline(new_caps, args.args, sudo_args)

    quoted = " ".join([shlex.quote(arg) for arg in cmdline])

    print(f"\x1b[1m{quoted}\x1b[22m", file=sys.stderr)
    # We don't need this process anymore, so we don't need a subprocess either.
    os.execv(cmdline[0], cmdline)

if __name__ == "__main__":
    main()
