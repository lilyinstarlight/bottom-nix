# bottom-nix

An implementation of the [Bottom encoding format](https://github.com/bottom-software-foundation/spec) in Nix


## Usage

```sh
nix eval --raw -f bottom.nix --apply 'bottom: bottom.encodeFile ./bottom.nix'
```
