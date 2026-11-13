# DS1 TRACE stage map (2026-11-12)

The DS1 author has specified that when several scripts perform essentially the same analysis, the one with the larger p-number is generally the final version. Earlier source files are not active parts of this reconstructed pipeline.

| Active stage(s) | Dependency / role | Status |
| --- | --- | --- |
| p0000_preprocess_Leipzig | BrainVision raw EEG -> cleaned / AMICA / DIPFIT `.set` | ASR=20 SD confirmed |
| p0010_preprocess_Dortmund | EDF raw EEG -> cleaned / AMICA / DIPFIT `.set` | ASR=20 SD confirmed; supersedes obsolete 25-SD single-loop variant |
| p0100-p0103 | Outputs from p0000 -> Leipzig dipoles, IC variance and FOOOF | Existing DS1 code migrated |
| p0110-p0113 | Outputs from p0010 -> Dortmund dipoles, IC variance and FOOOF | Existing DS1 code migrated |
| p0200-p0232 | Cortical mesh, DIPFIT check, AAL cortical/subcortical masks | Existing DS1 code migrated |
| p0400_simulateUDL | Forward-inverse simulation, independent of empirical geometry | MATLAB numerical verification pending |
| p0410_plotSimUDL | Simulation plots loaded from p0400 | MATLAB numerical verification pending |
| p1300_estimateDipDepth | p0100/p0101/p0103/p0110/p0111/p0113/p0210/p0221/p0222/p0231/p0232 -> corrected geometry | **Canonical** dipole depth / normal / angle computation |
| p1310_visualizeDipDepth | p1300 and p0210 -> depth and diagnostic figures | Additional diagnostic |
| p1322_finalizeAngleFigures | p1300 -> local-normal vs MNI radial sensitivity | Final p132x version, replaces p1320/p1321 |
| p1341_finalizeFigure007 | p1300 and p0210 -> manuscript Figure 7 | Final p1330/p1340/p1341 version |
| p1400_figure8AngleDepth | p1300 -> manuscript Figure 8 | Final joint angle-depth version |

**Excluded old stages:** `p0300_estimateDipDepth`, `p0310_vis_dipoleOrientations`, `p0311_vis_dipoleOrientations_layoutMatched`, `p0320_vis_depth` (use p1300 and later); `p1320_finalizeAngleFigures`, `p1321_finalizeAngleFigures`, `p1330_finalizeFigure007`, `p1340_finalizeFigure007` (use p1322 and p1341). Source ZIPs are separately archived outside the published active pipeline.

The prefix of each MATLAB script identifies its own output directory. The MATLAB source and the metadata files have been statically inspected; complete execution is not verified. The current staging is a development candidate rather than a reproducibility release.
