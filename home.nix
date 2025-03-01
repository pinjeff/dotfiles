{ config, pkgs, ... }:
let
  username = "jeff";
  homeDirectory = "/home/${username}";
  dotfiles = "${homeDirectory}/.config/home-manager";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  home = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = username;
    homeDirectory = homeDirectory;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "24.11"; # Please read the comment before changing.

    # You can also manage environment variables but you will have to manually
    # source
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    sessionVariables = {
      EDITOR = "nvim";
    };

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      bat
      croc
      delta
      du-dust
      entr
      eza
      fd
      lazydocker
      lazygit
      lf
      mold
      neovim
      nixpkgs-fmt
      ouch
      ripgrep
      tealdeer
      tmux
      tokei
      tree-sitter
    ];
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    tmux.enableShellIntegration = true;
  };

  home.file = {
    ".cargo/config.toml".source = link cargo/config.toml;
  };

  xdg.configFile = {
    "nvim/init.lua".source = link "${dotfiles}/neovim/init.lua";
    "tmux/tmux.conf".source = link "${dotfiles}/tmux/tmux.conf";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
