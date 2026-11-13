# External inputs and environment

Required data and toolboxes are not included in the repository. Prior to running each stage, install the exact historical dependency release when available, and set variables listed below. Never hand-edit or move the resulting p-numbered stage outputs.

| Variable | Meaning |
| --- | --- |
| `DS1_LEIPZIG_RAW_DIR` | Original LEMON `sub-*` folder hierarchy including `RSEEG/sub-*.vhdr` |
| `DS1_DORTMUND_RAW_DIR` | Dortmund `sub-*` folder hierarchy including `ses-1/eeg/*.edf` |
| `DS1_LEIPZIG_EEGLAB_ROOT` | EEG preprocessing installation; historical scripts used EEGLAB 2021.1 |
| `DS1_LEIPZIG_FIELDTRIP_ROOT` | Leipzig-era FieldTrip installation |
| `DS1_DORTMUND_EEGLAB_ROOT` | Dortmund preprocessing installation; historical scripts used EEGLAB 2024.2.1 |
| `DS1_ANALYSIS_EEGLAB_ROOT` | EEGLAB installation used for population-stage analysis |
| `DS1_FIELDTRIP_ROOT` | Full FieldTrip including template AAL atlas `ROI_MNI_V4.nii` |
| `DS1_RIBBON_TOOLBOX_ROOT` | Frozen `ribbonanalysistoolbox2024` (not bundled) |
| `DS1_SIM_EEGLAB_ROOT` | Simulation's original EEGLAB installation (2025.1.0) |
| `DS1_SIM_FIELDTRIP_ROOT` | Simulation's FieldTrip-lite release (historically 250523) |
| `DS1_INPOLYHEDRON_ROOT` | Legacy independent geometric helper, if used by other stages |
| `DS1_CBREWER_ROOT` / `DS1_DABOXPLOT_ROOT` | Legacy plotting helpers |

The **ASR BurstCriterion is fixed at 20 SD** in both active preprocessing stages, as confirmed by the author. `DS1_DORTMUND_BURST` is intentionally not consulted.

Also required, subject to dependency verification: `runamica15`, `loadmodout15`, `pop_firws`, `clean_rawdata`, `fitTwoDipoles`, and other EEGLAB/FieldTrip/DIPFIT extensions. `DipoleDensityExtended` is NOT required for the corrected p1300 geometry; unrelated upstream scripts may depend on other packages. No automatic version upgrade should be performed without regression checks.

The root `README.md` is an explicit exception to the author's otherwise strict TRACE root layout rule, to enable proper rendering on GitHub.
