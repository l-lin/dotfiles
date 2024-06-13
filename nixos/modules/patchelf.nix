#
# Small utility to modify the dynamic linker and RPATH of ELF executable.
#
# In computing, the Executable and Linkable Format (ELF, formerly named
# Extensible Linking Format), is a common standard file format for executable
# files, object code, shared libraries, and core dumps.
#
# Moreover, the ELF format is versatile. Its design allows it to be executed
# on various processor types. This is a significant reason why the format is
# common compared to other executable file formats.
#
# Generally, we write most programs in high-level languages such as C or C++.
# These programs cannot be directly executed on the CPU because the CPU doesn't
# understand these instructions. Instead, we use a compiler that compiles the
# high-level language into object code. Using a linker, we also link the object
# code with shared libraries to get a binary file.
#
# As a result, the binary file has instructions that the CPU can understand and
# execute. The binary file can adopt any format that defines the structure it
# should follow. However, the most common of these structures is the ELF format.
# src:
# - https://nixos.wiki/wiki/Packaging/Binaries
# - https://rootknecht.net/blog/patching-binaries-for-nixos/
# - https://github.com/NixOS/patchelf
#

{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ patchelf ];
}
