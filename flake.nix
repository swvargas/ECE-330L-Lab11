{
  description = "STM32F407G-DISC1 dev environment (CMake/Ninja + flash/debug)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # GNU Arm Embedded toolchain + newlib
        armToolchain = pkgs.gcc-arm-embedded;

        flashTools = with pkgs; [
          stlink # st-flash, st-info, etc.
          openocd
        ];

        buildTools = with pkgs; [
          cmake
          ninja
          gnumake
          python3
        ];

        editorTools = with pkgs; [
          clang-tools # clangd, clang-format
          bear # optional: generate compile_commands.json for non-cmake builds
          gdb # host gdb (often ok)
        ];

        usbTools = with pkgs; [
          libusb1
          udev
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          name = "stm32f407-dev";

          packages = [ armToolchain ] ++ buildTools ++ editorTools ++ flashTools ++ usbTools;

          # Optional: helps some tools locate libs/udev at runtime
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libusb1 ];

          shellHook = ''
            echo "STM32F4 dev shell"
            echo " - arm-none-eabi-gcc: $(arm-none-eabi-gcc --version | head -n1)"
            echo " - openocd: $(openocd --version | head -n1)"
            echo " - st-flash: $(st-flash --version 2>/dev/null | head -n1 || true)"
            echo ""
            echo "Common commands:"
            echo "  cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
            echo "  cmake --build build"
            echo "  st-flash write build/<name>.bin 0x08000000"
            echo "  openocd -f interface/stlink.cfg -f target/stm32f4x.cfg"
          '';
        };
      }
    );
}
