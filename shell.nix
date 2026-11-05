{ pkgs ? (import <nixpkgs> { # we can vendor this and run our own cache
    config.allowUnfree = true; # for terraform
}), ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    vim
    git
    kubectl
    talosctl
    k9s
    kubectx
    kubernetes-helm
    fluxcd
  ];
  shellHook = ''
    export GIT_CONFIG_COUNT=2
    export GIT_CONFIG_KEY_0="user.name"
    export GIT_CONFIG_VALUE_0="Ezri"
    export GIT_CONFIG_KEY_1="user.email"
    export GIT_CONFIG_VALUE_1="me@ezrizhu.com"
  '';
}
