{
  description = "A collection of tools to help with developing for Panic's Playdate.";

  inputs = {
    playdatesdk = {
      url = "https://download-cdn.panic.com/playdate_sdk/Linux/PlaydateSDK-2.0.3.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, playdatesdk }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; };
      version = "2.0.3";

      mkPlaydateDerivation = { pname, description, buildInputs ? [], installPhase }: (pkgs.stdenv.mkDerivation {
        pname = pname;
        version = version;
        buildInputs = buildInputs ++ [ pkgs.stdenv.cc.cc.lib ];
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        installPhase = installPhase;
        src = playdatesdk;
        PLAYDATE_SDK_PATH = playdatesdk;
        meta = {
          homepage = "https://play.date/dev";
          description = "${description} - part of the Playdate SDK";
          platforms = pkgs.lib.platforms.linux;
        };
      });

      pdc = mkPlaydateDerivation {
        pname = "pdc";
        buildInputs = [ pkgs.zlib pkgs.libpng ];
        installPhase = ''
          mkdir -p $out/bin
          cp -r ${playdatesdk}/bin/pdc $out/bin/pdc
        '';
        description = "The PlayDateCompiler, used for compiling Playdate projects";
      };

      pdutil = mkPlaydateDerivation {
        pname = "pdutil";
        installPhase = ''
          mkdir -p $out/bin
          cp -r ${playdatesdk}/bin/pdutil $out/bin/pdutil
        '';
        description = "The PlayDateUtil, used for interacting with the PlayDate device";
      };

      PlaydateSimulator = mkPlaydateDerivation {
        pname = "PlaydateSimulator";
        buildInputs = [ pkgs.webkitgtk ];
        installPhase = ''
          mkdir -p $out/bin
          cp -r ${playdatesdk}/bin/PlaydateSimulator $out/bin/pds
        '';
        description = "The PlaydateSimulator, used for simulating and interacting with the PlayDate device";
      };

      PlaydateSimulatorWrapped = pkgs.buildFHSUserEnv {
        name = "PlaydateSimulator";
        targetPkgs = pkgs: [ pkgs.alsa-lib PlaydateSimulator ];
        runScript = "pds";
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pdc
                     pdutil
                     PlaydateSimulatorWrapped
                   ];
        PLAYDATE_SDK_PATH = playdatesdk;
      };
  };
}
