# Stack Setup (English reference)

> The German [Stack-Setup_de.md](Stack-Setup_de.md) is the canonical working
> version. Follow it for exact commands; this page is a short English
> reference.

## Prerequisites

Ubuntu or a fresh Linux VM, `zsh`, Antidote, Powerlevel10k, `just`, `uv`,
`direnv`, Mamba, and VS Code. The setup installs `nala`, `zsh`, `fzf`, `btop`,
`neofetch`, `gh`, `shellcheck`, `shfmt`, and `ripgrep`.

## Steps

1. Update the base system and install build tools.
2. Install ZSH, Antidote, the plugins, and Powerlevel10k.
3. Set `INTERACTIVE_COMMENTS` exactly once. Do not write an `echo` command
   into `.zshrc`; remove duplicates from an earlier setup.
4. Install `just`, `uv`, `direnv`, and Mamba.
5. Create the reduced `ds12` data-science environment. It contains Google
   Colab, JupyterLab, Scikit-Learn, JAX, and Numba, but no CUDA, PyTorch, or
   TensorFlow promise.
6. Install VS Code extensions and the harness.
7. Clone the repository, source `luxuspythonstack.sh`, and symlink
   `lupysta` into `~/.agents/skills/lupysta`.
8. Verify the installation:
   ```shell
   type pyinit act jl
   pyinit --help
   ```

## Migration and uninstall

- Do not install the old `luxuspythonstack` skill and `lupysta` in parallel.
- Existing projects are not updated automatically.
- Remove the skill link and the `source` line to uninstall. Generated
  projects remain independent of the installed skill.

## See also

- [Stack documentation (English reference)](Luxus-Python-Stack.md)
- [Repository README](../README.md)
