# NixOS Radicle Seed Node Module

Easily host your own Radicle seed node with NixOS

```nix
{ pkgs, ... }: {
  imports = [
    (import pkgs.fetchFromGithub {
      owner = "icetan";
      repo = "nixos-radicle-node";
      rev = "";
      sha256 = "0rs9bxxrw4wscf4a8yl776a8g880m5gcm75q06yx2cn3lw2b7v21";
    })
  ];

  services.radicle-node = {
    enable = true;
    enableWeb = true;
    alias = "example.org";
    port = 8776;
  };
}
```

Based on [Radicle Seeder's Guide](https://hackmd.io/@radicle/r1Zejbx5a).
