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
`petsc-configure.py` honours `DEV` and `PETSC_INSTALL` too. For
persistent per-machine settings, put the exports in `local.env` next to
`common.sh` (gitignored, sourced automatically).

## Notes

- PETSc is used purely as a dependency provider (MPI, hypre, metis,
  parmetis); the parallel MFEM build sets `MFEM_USE_PETSC=OFF`, so MFEM
  is not coupled to the PETSc version. Optional I/O packages (netcdf,
  hdf5, gslib, ...) are commented out in `petsc-configure.py` — the MFEM
  builds don't enable the corresponding `MFEM_USE_*` options.
- `build_*.sh` wipe the build directory by default; pass `-k`/`--keep`
  for an incremental build.
- Laptop-specific: `eduroam.sh` (Cambridge eduroam via nmcli; prompts
  for the username and token, never store them in the file).
