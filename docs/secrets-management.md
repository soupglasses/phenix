# Secrets management

Secrets are generated through a tool called Sops created by mozilla. This is
then consumed by NixOS via [`sops-nix`](https://github.com/Mic92/sops-nix).
Sops lets us deal with many encryption standards (pgp, age, ssh, etc.) under one
common tool and CLI framework.

## Generating a secret key

You currently have 3 options for creating a new secret key to operate with sops
and its secrets. Age keys are the recommended choice for their ease of use.

NOTE: All `ed25519` based ssh keys (excluding `-sk` versions) will have `age` keys
generated for them. So ensure extra caution when adding such a key.

### 1. Use `ssh-to-age` to autogenerate an `age`-key from your `ssh`-key

Requires an `ed25519` based generated ssh key with the secret readable by the
local device. This is used by `ssh-to-age` to generate a private `age`.
A handy tool is exposed to you through `nix run .#first-run` to generate this
`age` key, put it under `.secrets/age.txt`, and set `SOPS_AGE_KEY_FILE`
for you.

### 2. Use an `age` key manually

To generate a new one, use `mkdir -p ~/.config/sops/age` and then
`age-keygen -o ~/.config/sops/age/keys.txt`.
You need to keep this file safe yourself. You should not need to set
up `SOPS_AGE_KEY_FILE` as this is the standard location to put age keys.

### 3. Use a `pgp` key manually

Public key needs to be available in `keys.openpgp.org`. Use the fingerprint
of the key with `gpg --fingerprint`. Feel free to remove the extra spaces
from the fingerprint. Generating and how to use a `pgp` key is left up to
you.

Formatting: `echo "FINGERPRINT" | awk '{ gsub(/ /,""); print tolower($0) }'`

## Enrolling a new user

Someone with access to sops will need to go and add your key to the
`state/users.json` file, then run `sops updatekeys secrets/XXX.yaml`
on the relevant secrets you need access to.

## Adding secrets access to a new host

1. Install nixos on the host.
2. Run `ssh-keyscan host`.
3. Copy the ed25519 key to the `state/machines.json` file.
4. Run `nix run .#sops-gen-lockfile`.
5. Run `sops updatekeys secrets/XXX.yaml`.
6. deploy the configuration with secrets to the machine.

## Removing a user or server

1. Go into `state/users.json` or `state/servers.json` and remove all keys for
the user/server.
2. Run `nix run .#sops-gen-lockfile`.
3. Run `sops updatekeys secrets/XXX.yaml` to remove the key from the file.
4. Rotate the internal data-key with `sops --rotate --in-place secrets/XXX.yaml`.
5. Rotate any API keys manually which may have been available to the previous key.

> **Warning**:
>
> Do not run `sops updatekeys` only, as it will only sync the data-key between
the users defined in `.sops.yaml`. With this command, it will still use the
previous secret key that the user we are removing still has access to.
To stop a rogue user from fetching the data-key in our git history and decrypting
the new rotated keys, remember to also run `--rotate --in-place`.
