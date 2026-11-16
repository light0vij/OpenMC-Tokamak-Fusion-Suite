# OpenMC Tokamak Fusion Neutronics Suite

Repository: `OpenMC-Tokamak-Fusion-Suite`

A neutronics workflow for a **spherical tokamak**, built with [OpenMC](https://docs.openmc.org) and packed in a Docker container with JupyterLab. You do not need to install OpenMC yourself. Docker does it for you.


The project follows the neutrons of a compact D–T spherical tokamak from its birth to the shutdown of the machine. Monte Carlo neutron and photon transport (OpenMC with FENDL-3.2 data) gives the **tritium breeding ratio, the neutron flux, the nuclear heating and the radiation damage of the blanket and the shields**. A **depletion calculation** then follows one full-power year of neutron activation and a 7-day cooldown, giving the tritium inventory, the main radioactive isotopes and the decay heat. Finally, the decay photons of the activated components are transported to obtain the **shutdown dose rate**, using the rigorous two-step (R2S) method. At a neutron wall loading of 1 MW/m² (62.7 MW of fusion power), the 100 cm lead–lithium blanket (90 % Li-6) reaches a tritium breeding ratio of about 1.28, the nuclear heating is about 56 MW, and the tungsten first wall receives about 2 displacements per atom per full-power year. The model is idealised (one cell per component, no structural material or coolant in the blanket, a ring source on the midplane), so the results show the workflow and the orders of magnitude, not a design.

## Summary

The project models a simplified, compact D–T fusion machine made of concentric shells: a copper rod and a tungsten diboride shield (best from https://github.com/light0vij/S-Tokamak-Shield-OpenMC) in the centre, and around the plasma a tungsten first wall, a lead–lithium breeding blanket, a steel reflector and a tungsten outer shield. It is run at a neutron wall loading of 1 MW/m² (62.7 MW of fusion power) with FENDL-3.2 data.

Four notebooks follow the neutrons, and then the radioactive material left after shutdown:

| Step | Notebook | What it does |
|---|---|---|
| 1 | `Base_Geometry_Materials.ipynb` | Builds the geometry, materials, source and settings |
| 2 | `TBR_NeutronFlux_heating_damage.ipynb` | Tritium breeding ratio, neutron flux, nuclear heating and radiation damage (DPA) |
| 3 | `Depltetion_Activation.ipynb` | One year of irradiation and 7 days of cooldown: tritium, decay heat, active isotopes |
| 4 | `SDDR.ipynb` | Shutdown dose rate from the activated materials |

The depletion chain made specifically for this project is part of the repository: `chain/chain_fendl30_fusion_complete.xml` (see `chain/Readme.md`).

> This is a simplified research and learning model, not a validated reactor design.

### Calculations performed

| Notebook | Type of calculation | Main results |
|---|---|---|
| 1. Base geometry and materials | Model building: constructive solid geometry, materials, a D–T ring source (14.08 MeV, 20 keV ion temperature) and fixed-source settings. Exact analytic cell volumes, checked with a stochastic volume calculation | OpenMC input files, `geometry_dimensions.csv` (radii and volumes read by the other notebooks), geometry plots |
| 2. TBR, flux, heating, damage | Fixed-source neutron and photon Monte Carlo transport with cell and mesh tallies: tritium production, flux, neutron and photon heating, damage energy converted to displacements per atom (NRT model) | Tritium breeding ratio, flux maps and radial profile, heating per component (MW), DPA and neutron fluence per full-power year |
| 3. Depletion and activation | Time-dependent neutron activation (predictor integrator): 1 full-power year, then cooldown to 1 day and 7 days, using the custom depletion chain | Tritium in the blanket (checked against the breeding-ratio estimate), activity of the main isotopes per component, decay heat curves |
| 4. Shutdown dose rate (SDDR) | Rigorous two-step method: decay-photon sources from the activated materials, photon transport, ICRP-116 flux-to-dose coefficients | Dose rate per component and a 2D dose map at shutdown, 1 day and 7 days |

### Model cross-sections

Side view (x–z plane) and top view (x–y plane) of the model:

<p align="center">
  <img src="images/ST_radial_build_xz.png" alt="Side view of the model (x–z plane)" width="48%">
  <img src="images/ST_radial_build_xy.png" alt="Top view of the model (x–y plane)" width="48%">
</p>
Colours: copper rod (orange), protective shield (purple), vacuum (white), plasma torus (red), breeding blanket (blue), reflector (light grey), and outer shield (dark grey). The 1 cm tungsten first wall is too thin to see at this scale.

## Installation and running

**1. Install Docker** ([Docker Desktop](https://www.docker.com/products/docker-desktop/) 

```bash
docker --version
```

Give Docker about 6 CPU cores and 12 GB of memory (Docker Desktop: *Settings → Resources*) and keep about 10 GB of free disk space.

**2. Get the code**

```bash
git clone <https://github.com/light0vij/OpenMC-Tokamak-Fusion-Suite.git> OpenMC-Tokamak-Fusion-Suite
cd OpenMC-Tokamak-Fusion-Suite
```

**3. Download the nuclear data (separately).** The data are not part of this repository. Download **FENDL-3.2 (HDF5)** into a folder called `openmc_data` inside the project. More libraries are on the [OpenMC data page](https://openmc.org/official-data-libraries/).

```bash
mkdir -p openmc_data && cd openmc_data
curl -L -o fendl-3.2-hdf5.tar.xz https://anl.box.com/shared/static/3cb7jetw7tmxaw6nvn77x6c578jnm2ey.xz
tar -xf fendl-3.2-hdf5.tar.xz
cd ..
ls openmc_data/fendl-3.2-hdf5/cross_sections.xml    # this file must exist
```

**4. Run the script.** It builds the image (first run only), tells Docker where the nuclear data and the shared folders are, and starts the container.

```bash
chmod +x OpenMC-Tokamak-Fusion-Suite.sh
./OpenMC-Tokamak-Fusion-Suite.sh
```

* **Add the path of your nuclear data library here:** open `OpenMC-Tokamak-Fusion-Suite.sh` and set the line `DATA_DIR=...` at the top to the **full path** of the folder that contains `fendl-3.2-hdf5/`, for example `DATA_DIR="/YOUR/PATH/openmc_data"`. Use an absolute path. This is the only place where the data path is set.
* The first build compiles OpenMC and can take 15–40 minutes. Later runs take seconds.

**5. Open JupyterLab** at <http://localhost:8888> (no password; it is open to your own computer only).

### Alternative: Docker Compose

```bash
docker compose up -d --build
```

Compose reads the data from `./openmc_data`. If your data are elsewhere, edit the paths under `volumes:` in `docker-compose.yml` (keep the paths after the colon).

## Running the notebooks

Open the notebooks in `notebooks/` and run them **in order**: 1 → 2 → 3 → 4. Run `SDDR.ipynb` three times, with `shutdown_step = 1`, `2` and `3` at the top (shutdown, 1 day, 7 days). The Monte Carlo runs take time (the transport run of notebook 2 took about an hour on 12 threads). For a quick test, use fewer particles.

The four `Spherical_tokamak_fendl_...` folders inside `notebooks/` are **empty on purpose**, to keep the repository small. They fill up when the notebooks run. Because `notebooks/` is a shared folder, you can open the results in JupyterLab and on your own computer, and they stay when the container is stopped or removed.

## Depletion chain

A **custom depletion chain** was generated for this project, because the standard ENDF/B chains do not follow the high-energy and light-particle channels, such as (n,t), that matter for 14.1 MeV neutrons. It combines FENDL/A-3.0 activation pathways with JEFF-3.3 decay data and patches taken from the ENDF/B-VIII.0 chain. More details (data sources, method, checks and limitations) are in `chain/Readme.md`.

The chain file is in the repository, so there is nothing to download:

| Where | Path |
|---|---|
| On your computer | `chain/chain_fendl30_fusion_complete.xml` |
| Inside the container | `/workspace/chain/chain_fendl30_fusion_complete.xml` |

It is used by the depletion and SDDR notebooks. The `chain/` folder is shared with the container.


## Repository layout

```
OpenMC-Tokamak-Fusion-Suite/
├── Dockerfile
├── docker-compose.yml
├── OpenMC-Tokamak-Fusion-Suite.sh
├── requirements.txt
├── images/            # fusion diagrams used in this README
├── chain/             # depletion chain (chain_fendl30_fusion_complete.xml) and its Readme.md
└── notebooks/         # config.py, the four notebooks, and the four (empty) result folders
```


## Credits

* P. K. Romano et al., "OpenMC: A state-of-the-art Monte Carlo code for research and development", *Annals of Nuclear Energy* 82 (2015) 90–97. <https://doi.org/10.1016/j.anucene.2014.07.048>
* FENDL-3.2, IAEA Nuclear Data Section: <https://www-nds.iaea.org/fendl/>
