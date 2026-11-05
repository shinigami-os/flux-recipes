#!/usr/bin/env python3
# Speaks greetd's IPC protocol directly (4-byte little-endian length prefix +
# JSON, over the unix socket at $GREETD_SOCK) since Kira Login replaces
# regreet entirely and nothing else in the greeter session does this for us.
# The whole create_session -> auth loop -> start_session exchange has to
# happen inside one connection, so it all lives in this one process instead
# of being split across shell script invocations.
import json
import os
import pwd
import socket
import struct
import subprocess
import sys
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def log_timing(label):
    path = "/tmp/kira-login-timing.log"
    # this process runs as the greetd user, but kira-start-sleex appends to
    # the same file as the real logged-in user right after - world-writable
    # or that second write just fails silently on a permission error
    with open(path, "a") as f:
        f.write(f"{time.time():.3f} {label}\n")
    os.chmod(path, 0o666)


def resolve_username():
    # Kira's installer creates exactly one real account (whatever name the
    # user picked, not necessarily "kira" - that's only the live ISO's own
    # default) - the lowest UID in the normal user range is that account,
    # the same way useradd -m assigns it on a fresh install
    candidates = sorted(
        (u for u in pwd.getpwall() if 1000 <= u.pw_uid < 60000),
        key=lambda u: u.pw_uid,
    )
    if not candidates:
        raise RuntimeError("no local user found (uid 1000-59999)")
    return candidates[0].pw_name


USERNAME = resolve_username()


def send(sock, msg):
    data = json.dumps(msg).encode()
    sock.sendall(struct.pack("<I", len(data)) + data)


def recv(sock):
    hdr = b""
    while len(hdr) < 4:
        chunk = sock.recv(4 - len(hdr))
        if not chunk:
            raise ConnectionError("greetd closed the connection")
        hdr += chunk
    (length,) = struct.unpack("<I", hdr)
    data = b""
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            raise ConnectionError("greetd closed the connection")
        data += chunk
    return json.loads(data)


def eww(*args):
    # without --config, eww falls back to $XDG_CONFIG_HOME/eww (nonexistent
    # for the greetd user) instead of the actual running daemon's config
    # dir, and just fails to connect
    subprocess.run(["eww", "--config", "/etc/greetd/kira-login", *args], check=False)


def resolve_session(name):
    sessions = json.loads(subprocess.run(
        [os.path.join(SCRIPT_DIR, "sessions.sh")],
        capture_output=True, text=True, check=True).stdout)
    session = next((s for s in sessions if s["name"] == name), sessions[-1])

    if session["cmd"] == ["__TTY__"]:
        shell = pwd.getpwnam(USERNAME).pw_shell or "/bin/sh"
        return [shell, "-l"], ["XDG_SESSION_TYPE=tty"]

    return session["cmd"], [
        "XDG_SESSION_TYPE=wayland",
        f"XDG_SESSION_DESKTOP={name}",
        f"XDG_CURRENT_DESKTOP={name}",
    ]


def main():
    if len(sys.argv) < 2:
        print("usage: greetd-auth.py <session-name>", file=sys.stderr)
        sys.exit(1)

    session_name = sys.argv[1]
    password = sys.stdin.readline().rstrip("\n")

    sock_path = os.environ.get("GREETD_SOCK")
    if not sock_path:
        print("greetd-auth: $GREETD_SOCK is unset", file=sys.stderr)
        sys.exit(1)

    cmd, env = resolve_session(session_name)

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    # a hang anywhere in this exchange (e.g. greetd never replying to
    # cancel_session in some edge case) would otherwise leave the password
    # field stuck on the checking animation forever, with no way out
    sock.settimeout(10)
    try:
        sock.connect(sock_path)

        send(sock, {"type": "create_session", "username": USERNAME})
        resp = recv(sock)

        while resp.get("type") == "auth_message":
            answer = password if resp.get("auth_message_type") in ("visible", "secret") else None
            send(sock, {"type": "post_auth_message_response", "response": answer})
            resp = recv(sock)

        if resp.get("type") == "error":
            # a wrong password has to end this session cleanly, not just stop
            # talking to greetd - closing the socket right after sending
            # cancel_session, without waiting for its reply, looked to greetd
            # like the greeter itself had crashed, and its crash-recovery
            # response (restarting the whole greeter) is what showed up as
            # "the greeter just restarts" on a bad password
            send(sock, {"type": "cancel_session"})
            recv(sock)
            sys.exit(1)

        log_timing("start_session sent")
        send(sock, {"type": "start_session", "cmd": cmd, "env": env})
        resp = recv(sock)
        log_timing("start_session response received")
        if resp.get("type") == "error":
            eww("update", "auth_state=error")
            sys.exit(1)

        # sessions.sh reads this back next boot and sorts it to the front of
        # the dropdown, so the greeter defaults to whatever was picked last
        try:
            with open("/var/lib/greetd/last-session", "w") as f:
                f.write(session_name)
        except OSError:
            pass

        # greetd doesn't kill the outgoing greeter on a successful login -
        # start_session only schedules the new session and arms a 5-second
        # fallback timer, on the assumption the greeter notices and exits
        # itself immediately. regreet does that; this custom greeter never
        # did, so every login sat through the full 5-second fallback before
        # greetd lost patience and killed it for us.
        subprocess.run(["pkill", "-TERM", "-f", "start-greeter.sh"], check=False)
    except Exception as exc:
        print(f"greetd-auth: {exc}", file=sys.stderr)
        sys.exit(1)
    finally:
        sock.close()


if __name__ == "__main__":
    main()
