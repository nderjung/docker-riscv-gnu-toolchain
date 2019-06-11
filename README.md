# Dockerized RISC-V GNU Toolchain

## Available binaries

* spike
* gcc-riscv64-linux-gnu

## Usage

```bash
docker run -it --rm nderjung.net/riscv-gnu-toolchain \
  spike -m128 -p1 +disk=root.bin.sqsh bbl linux-4.1.y/vmlinux
```
