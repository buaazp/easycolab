"""Store service tokens in the current user's Windows Credential Manager."""

import ctypes
import sys

TUNNEL_CREDENTIAL_TARGET = "EasyColab/CloudflareTunnel"
HF_CREDENTIAL_TARGET = "EasyColab/HuggingFace"


class CREDENTIALW(ctypes.Structure):
    _fields_ = [
        ("Flags", ctypes.c_uint32),
        ("Type", ctypes.c_uint32),
        ("TargetName", ctypes.c_wchar_p),
        ("Comment", ctypes.c_wchar_p),
        ("LastWritten", ctypes.c_uint32 * 2),
        ("CredentialBlobSize", ctypes.c_uint32),
        ("CredentialBlob", ctypes.POINTER(ctypes.c_ubyte)),
        ("Persist", ctypes.c_uint32),
        ("AttributeCount", ctypes.c_uint32),
        ("Attributes", ctypes.c_void_p),
        ("TargetAlias", ctypes.c_wchar_p),
        ("UserName", ctypes.c_wchar_p),
    ]


def _credential_api():
    if sys.platform != "win32":
        raise OSError("Windows Credential Manager is unavailable on this platform")
    api = ctypes.WinDLL("Advapi32.dll", use_last_error=True)
    credential_pointer = ctypes.POINTER(CREDENTIALW)
    api.CredReadW.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.POINTER(credential_pointer)]
    api.CredWriteW.argtypes = [credential_pointer, ctypes.c_uint32]
    api.CredDeleteW.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32]
    for operation in (api.CredReadW, api.CredWriteW, api.CredDeleteW):
        operation.restype = ctypes.c_int
    api.CredFree.argtypes = [ctypes.c_void_p]
    api.CredFree.restype = None
    return api


def _last_error():
    return ctypes.get_last_error()


def _load_token(target: str) -> str:
    api = _credential_api()
    credential = ctypes.POINTER(CREDENTIALW)()
    if not api.CredReadW(target, 1, 0, ctypes.byref(credential)):
        error_code = _last_error()
        if error_code == 1168:
            return ""
        raise OSError(error_code, "Credential Manager read failed")
    try:
        entry = credential.contents
        return ctypes.string_at(entry.CredentialBlob, entry.CredentialBlobSize).decode("utf-8")
    finally:
        api.CredFree(credential)


def _save_token(target: str, account: str, token: str) -> None:
    payload = token.encode("utf-8")
    if not token or any(char.isspace() for char in token) or "\x00" in token or len(payload) > 2560:
        raise ValueError("Invalid token format or length")
    api = _credential_api()
    buffer = ctypes.create_string_buffer(payload)
    credential = CREDENTIALW()
    credential.Type = 1
    credential.TargetName = target
    credential.UserName = account
    credential.Persist = 2
    credential.CredentialBlobSize = len(payload)
    credential.CredentialBlob = ctypes.cast(buffer, ctypes.POINTER(ctypes.c_ubyte))
    if not api.CredWriteW(ctypes.byref(credential), 0):
        raise OSError(_last_error(), "Credential Manager write failed")


def _delete_token(target: str) -> None:
    api = _credential_api()
    if not api.CredDeleteW(target, 1, 0):
        error_code = _last_error()
        if error_code != 1168:
            raise OSError(error_code, "Credential Manager delete failed")


def load_tunnel_token() -> str:
    return _load_token(TUNNEL_CREDENTIAL_TARGET)


def save_tunnel_token(token: str) -> None:
    _save_token(TUNNEL_CREDENTIAL_TARGET, "tunnel-token", token)


def delete_tunnel_token() -> None:
    _delete_token(TUNNEL_CREDENTIAL_TARGET)


def load_hf_token() -> str:
    return _load_token(HF_CREDENTIAL_TARGET)


def save_hf_token(token: str) -> None:
    _save_token(HF_CREDENTIAL_TARGET, "hf-token", token)


def delete_hf_token() -> None:
    _delete_token(HF_CREDENTIAL_TARGET)
