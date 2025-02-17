# Cappy — Use capsh to run a program as the current user with with new capabilities

I made this because
```bash
$ sudo capsh --keep=1 --user=$USER "--caps=cap_setpcap,cap_setuid,cap_setgid+ep cap_sys_admin=ip cap_dac_override=ip cap_perfmon=ip cap_sys_ptrace=ip cap_sys_rawio=ip" --addamb=cap_sys_admin,cap_dac_override,cap_perfmon,cap_sys_ptrace,cap_sys_rawio -- -c "glances"
```

Was a lot to type.
