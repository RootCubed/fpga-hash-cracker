# FPGA NSMBW hasher

FPGA design that cracks NSMBW symbol hashes.

## Usage

1. Synthesize design with Vivado and upload to FPGA board
2. Build `complete_collisions`: `make build`
3. Search for hashes with `python .\hashcracker.py <hash>:<prefix>:<suffix>:<length>`
4. Run `complete_collisions` command given by previous command
5. (If you have a demangled hash) Filter collisions with `python .\filter_demangle.py collisions_full.txt <hash>:<prefix>:<suffix>`