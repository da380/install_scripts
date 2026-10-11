# install_scripts

Scripts for setting up a dev machine and building the numerical stack
(PETSc-provided dependencies → MFEM → AdGIA / mfemElasticity), plus a
couple of laptop-specific extras.

## Layout assumptions

Everything lives under one root, by default `~/dev`:

```
$DEV/
  petsc/                 PETSc source (clone of gitlab.com/petsc/petsc)
  petsc-install/         PETSc prefix install (MPI, hypre, metis, parmetis)
  mfem/                  MFEM source
  mfem_serial_build/     serial MFEM build tree
  mfem_parallel_build/   parallel MFEM build tree
  glvis/                 GLVis source (optional)
  glvis_build/           GLVis build tree
  gmsh/                  Gmsh source (optional)
  AdGIA/                 project source; builds in build_serial/ and build_parallel/
  mfemElasticity/        project source; builds likewise
```

## Install order on a fresh machine

1. `./apt_setup.sh` — system packages (deliberately no MPI/hypre/metis:
   PETSc builds those).
2. PETSc: clone it, then `cd $DEV/petsc && ~/dev/install_scripts/petsc-configure.py`,
   followed by the `make` / `make install` commands configure prints.
3. MFEM: `./build_mfem.sh serial` and/or `./build_mfem.sh parallel`
   (or the `mfem_serial.sh` / `mfem_parallel.sh` wrappers). The serial
   build also builds GLVis when `$DEV/glvis` exists.
4. `./gmsh_setup.sh` — Gmsh from source with OCC/FLTK (optional).
5. Projects: `./build_adgia_serial.sh`, `./build_adgia_parallel.sh`,
   `./build_elasticity_serial.sh`, `./build_elasticity_parallel.sh`
   (all thin wrappers around `build_project.sh`; `-h` shows the options).

### One-shot: `build_all.sh`

Steps 2–3–5 for the common AdGIA workflow are wrapped in one script:

```sh
./build_all.sh            # PETSc → serial MFEM (+GLVis) → parallel MFEM
                          #       → serial AdGIA → parallel AdGIA
./build_all.sh --skip-petsc   # reuse an existing PETSc install
./build_all.sh -n             # dry run: show the plan, build nothing
```

It assumes the sources are already cloned under `$DEV` (`petsc/`,
`mfem/`, `glvis/` optional, `AdGIA/`) and checks all of them before
starting, so a missing source is not discovered an hour into the PETSc
build. `--skip-mfem` / `--skip-adgia` skip the other stages;
mfemElasticity is not included.

### Seeing what a script will do

`build_mfem.sh`, `build_project.sh` (and its wrappers) and
`build_all.sh` all take `-n` / `--dry-run`: they print the resolved
configuration — paths, compilers, option defaults, and the exact cmake
command — and exit without building anything. `petsc-configure.py -n`
likewise prints the configure options and exits; without `-n` it prints
them before configuring.

## Using these scripts on another machine

All paths and compilers are defaults in `common.sh`, overridable from
the environment — nothing needs editing:

```sh
export DEV=/scratch/david          # root directory
export MPICC=mpicc MPICXX=mpicxx   # e.g. use the cluster's MPI instead
                                   # of PETSc's MPICH
./build_mfem.sh parallel
```

Overridables: `DEV`, `PETSC_INSTALL`, `SERIAL_CC`, `SERIAL_CXX`,
`MPICC`, `MPICXX`, `MFEM_SERIAL_BUILD`, `MFEM_PARALLEL_BUILD`.
`petsc-configure.py` honours `DEV`, `PETSC_INSTALL` and
`PETSC_EXTRA_OPTIONS` too. For persistent per-machine settings, use
`local.env` (next section).

### Extra PETSc packages without editing the script

`petsc-configure.py` takes additional configure options two ways:

- One-off, on the command line (anything it does not recognise is
  forwarded to PETSc configure unchanged):

  ```sh
  cd $DEV/petsc && ~/dev/install_scripts/petsc-configure.py --download-hdf5=1
  ```

- Persistently, via `PETSC_EXTRA_OPTIONS` — a space-separated list,
  with shell quoting for options that contain spaces:

  ```sh
  export PETSC_EXTRA_OPTIONS="--download-netcdf=1 --download-hdf5=1"
  ```

  Put the export in `local.env` and `build_all.sh` picks it up
  automatically; when running `petsc-configure.py` by hand, export it
  in the shell (the script does not read `local.env` itself). Check
  with `petsc-configure.py -n`, which marks the extra options in the
  printed list.

## Persistent per-machine settings: `local.env`

Exporting variables in the shell works for one-off overrides, but they
are gone with the shell session. For settings a machine should always
use, create a file called `local.env` next to `common.sh` (i.e. in this
directory) and put the exports there:

```sh
# local.env on the cluster — plain shell, sourced not executed
export DEV=/scratch/david     # everything lives here instead of ~/dev
export MPICC=mpicc            # use the system MPI wrappers instead of
export MPICXX=mpic++          # the ones from the PETSc install
```

How it works:

- `common.sh` sources `local.env` automatically (when it exists) at the
  start of every `build_*.sh` run, so there is nothing to activate.
- It is in `.gitignore`, so each machine keeps its own copy and `git
  pull` never touches or conflicts with it. It is also why a fresh clone
  has no `local.env` — create it only on machines that need overrides.
- Any of the overridables listed above can go in it. Anything left out
  falls back to the defaults in `common.sh`.
- Precedence quirk: `local.env` is sourced *before* the defaults are
  applied, so its exports also win over variables exported in the shell.
  `DEV=/tmp/x ./build_mfem.sh serial` will NOT override a `DEV` set in
  `local.env` — comment the line out there instead.
- `petsc-configure.py` is Python and does not read `local.env` itself;
  it only sees `DEV`/`PETSC_INSTALL` already exported in the
  environment. Export them in the shell when running it by hand, or run
  it via `build_all.sh`, which sources `local.env` and passes them on.
- To check what a script will actually use, run it with `-n`/`--dry-run`
  (see above): it prints the resolved paths and compilers and exits.

## Notes

- AdGIA requires MFEM >= 4.9 and its configure fails on anything older
  (v4.10 is its reference version), so keep the `$DEV/mfem` clone
  reasonably current.
- AdGIA's `meshes/`, `benchmarks/` and `postprocess/` directories are
  poetry projects; run `poetry install` in each before building so the
  mesh generation and the generated launchers use those environments
  (without them the launchers fall back on `python3`). The resolution of
  the generated meshes can be changed with `build_adgia_*.sh
  --mesh-scale X` (smaller is finer).
- PETSc is used purely as a dependency provider (MPI, hypre, metis,
  parmetis); the parallel MFEM build sets `MFEM_USE_PETSC=OFF`, so MFEM
  is not coupled to the PETSc version. Optional I/O packages (netcdf,
  hdf5, gslib, ...) are commented out in `petsc-configure.py` — the MFEM
  builds don't enable the corresponding `MFEM_USE_*` options.
- `build_*.sh` wipe the build directory by default; pass `-k`/`--keep`
  for an incremental build.
- Laptop-specific: `eduroam.sh` (Cambridge eduroam via nmcli; prompts
  for the username and token, never store them in the file).
