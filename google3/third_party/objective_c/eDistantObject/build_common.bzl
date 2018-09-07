"""Common defines for all BUILD files."""

COMMON_COPTS = [
    "-Werror",
    "-Wall",
    "-Wextra",
    "-Wconstant-conversion",
    "-Wenum-conversion",
    "-Wimplicit-retain-self",
    "-Wint-conversion",
    "-Wmissing-prototypes",
    "-Wno-unused-parameter",  # suppress as it is implicitly included by -Wextra.
    "-Wnull-dereference",
    "-Wshorten-64-to-32",
    "-Wundeclared-selector",
]

TESTS_RUNNERS = [
    # (suffix, tags, runner, host)
    (
        "_device",
        [
            "notap",
            "local",
        ],
        "//Runners:default_device_runner",
        "//tools/build_defs/apple/testing:ios_default_host",
    ),
    ("_nitro", [], "//googlemac/iPhone/Shared/Testing/EarlGrey/Runner:default_runner", None),
]
