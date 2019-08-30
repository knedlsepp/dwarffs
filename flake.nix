{
  edition = 201909;

  description = "A filesystem that fetches DWARF debug info from the Internet on demand";

  outputs = { self, nixpkgs }: rec {
    packages.dwarffs =
      with nixpkgs.packages;
      with nixpkgs.builders;
      with nixpkgs.lib;

      stdenv.mkDerivation {
        name = "dwarffs-0.1.${if self ? lastModified then substring 0 8 self.lastModified else "dirty"}";

        buildInputs = [ fuse nix nlohmann_json boost ];

        NIX_CFLAGS_COMPILE = "-I ${nix.dev}/include/nix -include ${nix.dev}/include/nix/config.h -D_FILE_OFFSET_BITS=64";

        src = self;

        installPhase =
          ''
            mkdir -p $out/bin $out/lib/systemd/system

            cp dwarffs $out/bin/
            ln -s dwarffs $out/bin/mount.fuse.dwarffs

            cp ${./run-dwarffs.mount} $out/lib/systemd/system/run-dwarffs.mount
            cp ${./run-dwarffs.automount} $out/lib/systemd/system/run-dwarffs.automount
          '';
      };

    defaultPackage = packages.dwarffs;

    checks.build = packages.dwarffs;

    nixosModules.dwarffs =
      {
        systemd.packages = [ packages.dwarffs ];

        system.fsPackages = [ packages.dwarffs ];

        systemd.units."run-dwarffs.automount".wantedBy = [ "multi-user.target" ];

        environment.variables.NIX_DEBUG_INFO_DIRS = [ "/run/dwarffs" ];

        systemd.tmpfiles.rules = [ "d /var/cache/dwarffs 0755 dwarffs dwarffs 7d" ];

        users.users.dwarffs =
          { description = "Debug symbols file system daemon user";
            group = "dwarffs";
            isSystemUser = true;
          };

        users.groups.dwarffs = {};
      };
  };
}
