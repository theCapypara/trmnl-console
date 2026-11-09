{
  pkg-config,
  cacert,
  aws-lc,
  fetchFromGitHub,
  python314Packages,
  lib,
  rustPlatform,
  stdenv,
}:
let
  cargo_toml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  # keep this up-to-date with the submodule
  trmnlFramework = fetchFromGitHub {
    owner = "usetrmnl";
    repo = "trmnl-framework";
    tag = "v3.3.1";
    hash = "sha256-Jn+zbZVDLmwhn8iY065EXsmrRjTe62wK8TpCjDYfrkE=";
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = cargo_toml.package.name;
  version = cargo_toml.package.version;

  # The preview feature embeds files from plugin/ and the trmnl-framework
  # submodule via include_str!, so the build needs the whole repo as source.
  src = ../.;
  cargoRoot = "cli-client";
  buildAndTestSubdir = "cli-client";
  # Since actually using .submodule=true on the Flake isn't supported with `github:`
  # and even without it it's very unreliable, we add the submodule here manually via nix
  postUnpack = ''
    rm $sourceRoot/trmnl-framework -rf || true
    cp -a ${trmnlFramework} $sourceRoot/trmnl-framework
  '';

  strictDeps = true;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    aws-lc
  ];

  preCheck = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  meta = {
    homepage = cargo_toml.package.repository;
    license = lib.licenses.agpl3Plus;
  };
})
