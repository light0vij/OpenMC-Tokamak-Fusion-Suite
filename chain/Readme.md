# Custom OpenMC Fusion Depletion Chain (`chain_fendl30_fusion_complete.xml`)

A hybrid depletion chain for OpenMC (0.16.0), built to follow neutron activation, tritium breeding and decay photons in a 14.1 MeV D–T spherical tokamak model. It is used by the depletion notebook (inventories, decay heat) and by the SDDR notebook (decay-photon sources for the shutdown dose rate). The build is in `chainfile_synthesis.ipynb`.

## 1. Why this chain was built

- **The ENDF/B chains were not sufficient.** Pre-built chains such as `chain_endfb80_sfr.xml` and `chain_endfb81_thermal.xml` follow only a short default reaction list: (n,2n), (n,3n), (n,4n), (n,γ), (n,p) and (n,α). Light-particle channels such as (n,t), (n,d), (n,np) and (n,na) are missing, so the depletion solver could not follow Li-6(n,t) tritium breeding.
- **A TENDL-based fusion chain could not be downloaded** in the working environment at the time.
- **Practice.** The chain was built from evaluated data with `openmc.data` and `openmc.deplete`, to learn how reactions, branching ratios and decay data fit together.
- **Smaller chain (intended).** Excluding fission and not supplying fission product yields keeps it free of fission-related content. Its size and run time were **not measured** or compared with a TENDL chain.

## 2. Data used

| Data | Library | Source | Role |
|---|---|---|---|
| Transport cross sections | FENDL-3.2 (HDF5) | <https://anl.box.com/shared/static/3cb7jetw7tmxaw6nvn77x6c578jnm2ey.xz> | Reaction rates during depletion (not stored in the chain); also used for the Li-7 check |
| Neutron activation pathways | FENDL/A-3.0 (ENDF format, 816 target nuclides) | <https://www-nds.iaea.org/fendl_library/websites/fendl32/> | Reaction channels, Q-values and products |
| Radioactive decay | JEFF-3.3 radioactive decay data, file `JEFF33-rdd_all.asc` | OECD/NEA: <https://www.oecd-nea.org/dbdata/jeff/jeff33/downloads/JEFF33-rdd.zip> | Half-lives, decay modes and photon spectra |
| Patch reference | `chain_endfb80_sfr.xml` (ENDF/B-VIII.0 chain) | <https://anl.box.com/shared/static/x3kp739hr5upmeqpbwx9zk9ep04fnmtg.xml> | Source of reactions missing from the FENDL-derived chain |

The chain defines the pathways, Q-values, branching and decay data. During depletion OpenMC takes the reaction **rates** from the FENDL-3.2 transport library, so a channel only has an effect if the transport library contains that reaction.

## 3. Method

1. **Reaction list.** All reaction names in `openmc.deplete.chain.REACTIONS` except `'fission'` (82 channels, including the threshold and light-particle ones).
2. **Safe loading.** The JEFF-3.3 tape is unpacked into one evaluation per nuclide. Every file in the FENDL/A folder is test-parsed with `openmc.data.endf.Evaluation` inside a `try/except`, so documentation or index files do not stop the build.
3. **Base chain.** `Chain.from_endf` is called with the decay evaluations, the FENDL/A files, the reaction list and no fission yields (`fpy_files=[]`). OpenMC then prints a notice that about 110 fissionable actinides get U-235 placeholder yields. The fission reaction is excluded, so these placeholders should have no effect on the tokamak materials.
4. **Patch.** Any reaction (type and target) that is missing from the FENDL-derived chain but present in `chain_endfb80_sfr.xml` is copied over, but only if its target nuclide exists in the new chain. This restored channels such as W-186(n,2n)W-185 that were absent from the first FENDL-only builds. The cause was not investigated (probably the isomer layout of the FENDL/A files).
5. **Branching normalisation.** For each nuclide and reaction type the branching ratios are summed and rescaled to 1 when the sum deviates by more than 10⁻⁶. This keeps ground and metastable branches consistent after patching. Example: W-184(n,γ) splits into W-185 (0.895) and W-185m (0.105).
6. **Tritium channels.** OpenMC records only the heavy residual of a reaction, so Li-6(n,t) ends in He-4 and the triton is not tracked. The chain therefore redirects Li-6(n,t) to H-3 (`ReactionTuple('(n,t)', 'H3', 4.783e6, 1.0)`) and keeps Li-7(n,n′α)T as `(n,na)` → H-3 (Q = −2.467 MeV).
7. **Checks.** The build prints the Li-7 transport check (MT 22), the dropped reaction names (none), `Chain.validate` output (no warnings) and the reaction lists of Li-6, Li-7, W-184, W-186, Pb-204 and Cu-63.
8. **Export** to `/workspace/chain/chain_fendl30_fusion_complete.xml`.

## 4. Validation status and limitations

- **Done:** branching sums validated, key channels printed, and (in the depletion notebook, with an earlier build) the tritium inventory compared with TBR × source rate × time (4.351 kg against 4.36 kg). **Repeat the tritium check after every rebuild.**
- **Not done:** no benchmark against an independent code (FISPACT-II) or a TENDL FNS chain, and no measured chain size or run time.
- **Li-7(n,n′α)T is inactive in depletion.** The Li-7 transport file has no MT 22 (`MT=22 in Li-7 transport library: False`), so the channel exists in the chain but gets no reaction rate. Depletion therefore tracks tritium from Li-6 only. Compare it with the Li-7 part of the TBR tally to see how large the difference is.
- **Hybrid data.** The chain combines FENDL/A-3.0 pathways, JEFF-3.3 decay data and ENDF/B-VIII.0 patches, so Q-values and branching come from different libraries.
- **Isomer branching** uses the FENDL/A data or ENDF/B defaults, not a fusion-spectrum collapse.
- **Not for fission systems.** Fission yields are absent. Do not use the chain for materials that contain actinides.
- **Decay photons only.** Beta bremsstrahlung and other secondary radiation are not in the SDDR source.

## 5. Usage

```python
import openmc
import openmc.deplete

chain_path = '/workspace/chain/chain_fendl30_fusion_complete.xml'
openmc.config['cross_sections'] = '/nuclear_data/fendl-3.2-hdf5/cross_sections.xml'
openmc.config['chain_file'] = chain_path        # needed by get_decay_photon_energy (SDDR)

settings.photon_transport = False               # photons are not needed for the activation step
model = openmc.Model(geometry=geometry, materials=materials, settings=settings)

operator = openmc.deplete.CoupledOperator(
    model, chain_file=chain_path,
    normalization_mode='source-rate',
    reduce_chain_level=5)                       # check the effect with len(operator.chain.nuclides)
```
Use the same chain file in the depletion and SDDR notebooks, and rerun both after any rebuild.
