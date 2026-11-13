# DS1: EEG source geometry and ICA physiological interpretation

MATLAB research pipelines accompanying the DS1 study submitted to *Cortex*: forward–inverse simulations and empirical analyses of dipole depth and orientation from Leipzig/LEMON and Dortmund EEG recordings.

**Status: public development snapshot (2026-11-12).** The geometry/angle computation was corrected after an error was identified in an earlier pipeline. **No end-to-end MATLAB run or numerical reproduction of the manuscript has been verified in this environment.** Treat the code as source for independent reproduction, not as an already-validated release.

## Layout and TRACE convention

- `README.md` at the repository root is the author's explicitly requested GitHub display exception.
- `code/` contains only p-numbered MATLAB stage scripts at its top level; supporting material is in `code/docs/`, `code/tests/`, and pinned third-party sources in `code/external/`.
- Each `code/pNNNN_stage.m` generates outputs **only** in its matching repository-root directory `pNNNN_stage/`.
- Stage scripts are intended to execute once in ascending p-number order, in fresh MATLAB sessions. Earlier stages' output directories must not be edited by hand.
- Raw EEG, generated `.set`/`.mat` files, and manuscript figures are **not** redistributed in this repository.

## Empirical analysis

| Stages | Purpose |
|---|---|
| `p0000_preprocess_Leipzig` | LEMON BrainVision preprocessing, ASR BurstCriterion **20 SD**, AMICA, ICLabel and DIPFIT |
| `p0010_preprocess_Dortmund` | Dortmund EDF preprocessing, ASR BurstCriterion **20 SD**, AMICA, ICLabel and DIPFIT |
| `p0100–p0113` | Dataset-specific dipole collection, ICA activity variance and spectral modeling |
| `p0200–p0232` | Cortical mesh, head model and AAL-based anatomical masks |
| `p1300_estimateDipDepth` | **Corrected** nearest-triangle geometry, signed depth, template-normal and MNI-radial angles, IC grouping |
| `p1310_visualizeDipDepth` | Revised depth plots and diagnostic figures |
| `p1322_finalizeAngleFigures` | Latest reference-axis sensitivity figure (not the manuscript's joint-histogram Figure 8) |
| `p1341_finalizeFigure007` | Latest manuscript **Figure 7** |
| `p1400_figure8AngleDepth` | Latest manuscript **Figure 8**, joint angle-depth histograms |

**Supersession rule:** for substantially overlapping scripts, the higher p-number is normally the final version. The legacy `p0300`/`p0310`/`p0311`/`p0320` geometry/visualization codes are **excluded**: do not use their depth or angle estimates. Similarly, `p1320`, `p1321`, `p1330`, and `p1340` were superseded by `p1322` or `p1341`. Their original uploads are retained separately by the author, not included as active pipeline stages.

### Geometry fix

Earlier nearest-triangle calculations had two defects: reversed barycentric weights along edge BC, and vertex-region cases returning `[0 0 0]` instead of the appropriate mesh vertex. `p1300` recomputes global closest points and derives axial (polarity-invariant) angles in the range 0–90 degrees. Downstream figures load **only** `p1300_estimateDipDepth/dipoleGeometry.mat`. Validation checks are included, but must be run on actual data.

### Primary data and environment

Set the appropriate environment variables to point to separately obtained raw EEG datasets and installed toolboxes. See [environment details](code/docs/ENVIRONMENT.md) and [stage map](code/docs/STAGE_MAP.md). These include historical EEGLAB/FieldTrip and AMICA requirements; different stages may need different frozen versions.

Start stages from a clean MATLAB session, for example:

```matlab
run(fullfile('ABSOLUTE_PATH_TO_DS1','code','p1300_estimateDipDepth.m'));
```

This example requires the earlier stages to have completed. All pipeline scripts should be run in ascending p-number order with their dependencies installed. The figure stages will fail explicitly if geometry QA or source data counts do not match their expected results.

## Forward–inverse simulation

- `p0400_simulateUDL.m`: 27 parameter combinations (three skull-to-brain conductivity ratios × nine UDL radii), using a non-GUI FieldTrip workflow adapted from the author's simUDL.
- `p0410_plotSimUDL.m`: simulation summary figures and CSV-based visualization.
- The simUDL snapshot (authored by Makoto Miyakoshi) is in `code/external/`; its included sphere triangulation library has its own license.

Simulation stages are independent of the corrected empirical dipole geometry stages. Their source code is included; numerical equivalence to the original GUI simulation remains to be checked.

## Reproducibility status

**Unverified development code.** A working installation of MATLAB R2023a plus external toolboxes, corresponding raw EEG and exact upstream outputs, and controlled regression against the manuscript are required. See [audit and blockers](code/docs/AUDIT.md). Please do not cite this version as a complete computational reproduction until those checks pass. A Git commit hash should be specified when citing the exact submitted code version.