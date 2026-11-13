% p0410_plotSimUDL.m
% Terminal figure stage. No computations are imported from the legacy CSV;
% figures use p0400_simulateUDL/results_all.csv generated in this pipeline.
clear
close all
clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(projectRoot,mfilename);
if ~isfolder(outDir), mkdir(outDir); end
inputCsv = fullfile(projectRoot,'p0400_simulateUDL','results_all.csv');
assert(isfile(inputCsv),'Run p0400_simulateUDL before p0410_plotSimUDL.');
T = readtable(inputCsv);
assert(height(T)==27,'Expected exactly 27 simulation rows.');
assert(all(isfinite(T.Depth_Bias_mm(T.Radius_mm>1))) && ...
       all(isfinite(T.Residual_Variance(T.Radius_mm>1))), ...
    'The simulated radii >=2 mm must have finite results.');
% The original reference contains NaN at radius 1 mm for each BSCR.
% Do not replace these with zero or include them as plotted samples.
bscrValues = [20 40 80];
figure('Position',[100 100 700 600],'Color','w'); hold on
for idx = 1:numel(bscrValues)
    k = bscrValues(idx);
    rows = T.BSCR == k & isfinite(T.Depth_Bias_mm);
    plot(T.Radius_mm(rows),T.Depth_Bias_mm(rows),'-o','LineWidth',2,'MarkerSize',7);
end
set(gca,'XScale','log','XTick',[1 2 4 8 16 24 32 48 64]);
xlim([1 70]); xlabel('UDL radius (mm)'); ylabel('Depth bias (mm)');
legend({'BSCR = 20','BSCR = 40','BSCR = 80'},'Location','northwest');
grid on; axis square;
exportgraphics(gcf,fullfile(outDir,'depthBiasGraph.pdf'),'ContentType','vector');
exportgraphics(gcf,fullfile(outDir,'depthBiasGraph.png'),'Resolution',300);

figure('Position',[100 100 700 600],'Color','w'); hold on
for idx = 1:numel(bscrValues)
    k = bscrValues(idx);
    rows = T.BSCR == k & isfinite(T.Residual_Variance);
    plot(T.Radius_mm(rows),100*T.Residual_Variance(rows),'-o','LineWidth',2,'MarkerSize',7);
end
set(gca,'XScale','log','XTick',[1 2 4 8 16 24 32 48 64]);
xlim([1 70]); xlabel('UDL radius (mm)'); ylabel('Residual variance (%)');
legend({'BSCR = 20','BSCR = 40','BSCR = 80'},'Location','northwest');
grid on; axis square;
exportgraphics(gcf,fullfile(outDir,'rvGraph.pdf'),'ContentType','vector');
exportgraphics(gcf,fullfile(outDir,'rvGraph.png'),'Resolution',300);
