final: prev:
let
  # cargo-setup-hook now makes -sys crates link system libraries, but
  # these packages don't depend on them, so their builds panic.
  withSystemLibs =
    pkg:
    pkg.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.pkg-config ];
      buildInputs =
        (old.buildInputs or [ ])
        ++ (with final; [
          aws-lc
          oniguruma
          sqlite
          zlib
          zstd
        ]);
    });
in
prev.lib.genAttrs [
  "codex"
  "electrs"
  "goose-cli"
  "liana"
  "lianad"
  "presenterm"
  "russ"
] (name: withSystemLibs prev.${name})
