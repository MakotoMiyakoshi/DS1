% p0400_simulateUDL.m
% TRACE migration candidate: numerical reproduction of the archived
% simulation_code.m + the forward-model calculations in simUDL_mainGUI.m.
% Preserves physical parameters, montage, concentric-sphere forward model,
% FieldTrip dipole-fitting initialization, and retry tolerances.
% Differences from legacy: no GUI, no evalin/assignin, no writes to plugin
% files, no pauses, and failures are explicit rather than silently skipped.
% This migration HAS NOT BEEN NUMERICALLY VERIFIED against results_all.csv.
clear
close all
clc
rng(20261111, 'twister'); % Fixed in the stage that might use randomness.
projectRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(projectRoot, mfilename);
if ~isfolder(outDir), mkdir(outDir); end

% Run-time environment is explicit and independent of previous MATLAB sessions.
eeglabRoot = getenv('DS1_SIM_EEGLAB_ROOT');
fieldtripRoot = getenv('DS1_SIM_FIELDTRIP_ROOT');
assert(isfolder(eeglabRoot), 'Set DS1_SIM_EEGLAB_ROOT (original: EEGLAB 2025.1.0).');
assert(isfolder(fieldtripRoot), 'Set DS1_SIM_FIELDTRIP_ROOT (original: Fieldtrip-lite250523).');
addpath(eeglabRoot);
eeglab('nogui');
addpath(fieldtripRoot);
if isfile(fullfile(fieldtripRoot,'ft_defaults.m'))
    ft_defaults;
else
    % Fieldtrip-lite250523 was the original simulation dependency.
    addpath(fullfile(fieldtripRoot,'forward'));
    addpath(fullfile(fieldtripRoot,'inverse'));
    addpath(fullfile(fieldtripRoot,'utilities'));
end
% Match the original simUDL plugin's bundled spherical triangulation algorithm.
simUDLRoot = fullfile(projectRoot, 'code', 'external', 'simUDL-dabbcd59b0d3');
addpath(fullfile(simUDLRoot, 'external', 'spheretriByGagarinov'));
assert(~isempty(which('spheretri')), 'Bundled spheretri() was not found.');
assert(~isempty(which('ft_compute_leadfield')), 'FieldTrip leadfield function not found.');
assert(~isempty(which('ft_dipolefitting')), 'FieldTrip fitting function not found.');

% Values from original simulation_code.m and simUDL GUIDE defaults.
bscrValues = [20 40 80];
radiusValues = [0.001 0.002 0.004 0.008 0.016 0.024 0.032 0.048 0.064]; % m
udlDepth = 0.002;                      % m
headRadii = [0.079 0.080 0.085 0.090]; % m, radial order from inside to outside
headOrigin = [0 0 0];                  % m
brainCond = 0.33; csfCond = 1.65; scalpCond = 0.33;
maxIterations = [5000 10000 20000];

% This is the precise original popup value 3 (64 EEG electrodes).
dipfitRoot = fileparts(which('dipfit_erpeeg'));
assert(~isempty(dipfitRoot), 'Could not locate EEGLAB DIPFIT.');
montageFile = fullfile(dipfitRoot, 'standard_BESA', 'standard-10-5-cap385.elp');
assert(isfile(montageFile), 'DIPFIT standard-10-5-cap385.elp not found.');
chanlocs1005 = readlocs(montageFile);
chanlocs1005 = chanlocs1005(3:end); % Original simUDL excludes first two fiducials.
[chanlocs1005.type] = deal('EEG');
[chanlocs1005.sph_radius] = deal(headRadii(4)*1000); % scalp radius, mm

EEG = eeg_emptyset;
EEG.nbchan = numel(chanlocs1005);
EEG.trials = 1;
EEG.pnts = 1000;
EEG.srate = 1000;
EEG.xmin = 0.001;
EEG.xmax = 1;
EEG.times = 0.001:0.001:1;
EEG.data = zeros(numel(chanlocs1005), 1000);
EEG.chanlocs = chanlocs1005;
EEG = pop_chanedit(EEG, 'convert', {'sph2all'});

usedLabels = {'Fp1','Fpz','Fp2','AF3','AF4', ...
    'F7','F5','F3','F1','Fz','F2','F4','F6','F8', ...
    'FT9','FT7','FC5','FC3','FC1','FCz','FC2','FC4','FC6','FT8','FT10', ...
    'T7','C5','C3','C1','Cz','C2','C4','C6','T8', ...
    'TP9','TP7','CP5','CP3','CP1','CPz','CP2','CP4','CP6','TP8','TP10', ...
    'P7','P5','P3','P1','Pz','P2','P4','P6','P8', ...
    'PO7','PO5','PO3','POz','PO4','PO6','PO8', ...
    'O1','Oz','O2'};
[~, selectedIdx] = intersect({EEG.chanlocs.labels}', usedLabels);
EEG = pop_select(EEG, 'channel', selectedIdx);
assert(EEG.nbchan == 64, 'Expected 64 channels from simUDL popup selection 3.');

elec = struct();
elec.unit = 'm';
elec.elecpos = [[EEG.chanlocs.X]' [EEG.chanlocs.Y]' [EEG.chanlocs.Z]']/1000;
elec.chanpos = elec.elecpos;
elec.label = {EEG.chanlocs.labels}';

% spheretri(40000) is the original high-resolution UDL construction.
% The original GUI recomputed the same vertices for every BSCR/radius.
[vertexUnit, ~] = spheretri(40000);
currentLayerRadius = headRadii(1)-0.002;
dipPosAll = (vertexUnit*currentLayerRadius)';
[~, phi] = cart2sph(dipPosAll(1,:), dipPosAll(2,:), dipPosAll(3,:));
theta = pi/2-phi;
arcLength = theta*currentLayerRadius;

numRuns = numel(bscrValues)*numel(radiusValues);
resultsData = nan(numRuns, 4);
runIdx = 0;
for bscr = bscrValues
    headmodel = struct();
    headmodel.type = 'concentricspheres';
    headmodel.unit = 'm';
    headmodel.r = headRadii;
    headmodel.o = headOrigin;
    headmodel.cond = [brainCond csfCond brainCond/bscr scalpCond];

    for radius = radiusValues
        runIdx = runIdx+1;
        radiusMm = round(radius*1000);
        fprintf('BSCR %d / UDL radius %d mm (%d/%d)\n', bscr, radiusMm, runIdx, numRuns);
        selectedDipoles = arcLength <= radius;
        if ~any(selectedDipoles)
            % The legacy reference CSV has NaN at radius 1 mm for each BSCR.
            % Record an actual empty-source failure, not a fabricated zero.
            resultsData(runIdx,:) = [bscr radiusMm NaN NaN];
            warning('No UDL vertices selected for radius %.3g m at BSCR=%d.',radius,bscr);
            continue;
        end
        udlPos = dipPosAll(:, selectedDipoles);
        udlMom = udlPos/currentLayerRadius; % outward radial moment, original simUDL.
        udlPos(3,:) = udlPos(3,:) - (udlDepth-0.002);

        lfUDL = zeros(EEG.nbchan, size(udlPos,2));
        for dipIdx = 1:size(udlPos,2)
            lfUDL(:, dipIdx) = ft_compute_leadfield(udlPos(:,dipIdx)', elec, headmodel) * udlMom(:,dipIdx);
        end
        lfmScalingFactor = ft_scalingfactor('V/(A*m)','uV/(nA*m)');
        lf = sum(lfUDL, 2)*lfmScalingFactor;
        dataFt = struct();
        dataFt.label = {EEG.chanlocs.labels}';
        dataFt.avg = lf;
        dataFt.time = 0;
        dataFt.dimord = 'chan_time';

        success = false;
        for attempt = 1:numel(maxIterations)
            cfg = struct();
            cfg.numdipoles = 1;
            cfg.symmetry = [];
            cfg.gridsearch = 'no';
            cfg.nonlinear = 'yes';
            cfg.headmodel = headmodel;
            cfg.elec = elec;
            cfg.model = 'regional';
            cfg.latency = 'all';
            cfg.dip.pos = mean(udlPos', 1);
            cfg.dip.mom = [0; 0; 1];
            cfg.dipfit.display = 'off';
            cfg.dipfit.maxiter = maxIterations(attempt);
            cfg.dipfit.TolFun = 1e-9;
            try
                source = ft_dipolefitting(cfg, dataFt);
                success = true;
                break;
            catch ME
                fprintf(2, 'Fitting attempt %d failed: %s\n', attempt, ME.message);
                if attempt == numel(maxIterations)
                    if radiusMm ~= 1
                        rethrow(ME); % Fail explicitly for unexpected fit failures.
                    else
                        % The archived CSV has undefined 1-mm values. Preserve
                        % a documented failed fit as NaN, not zero.
                        warning('1-mm UDL fit failed at BSCR %d: %s',bscr,ME.message);
                    end
                end
            end
        end
        if ~success
            resultsData(runIdx,:) = [bscr radiusMm NaN NaN];
            continue;
        end
        estDepthMm = headmodel.r(1)*1000 - source.dip.pos(3)*1000;
        depthBiasMm = abs(estDepthMm - udlDepth*1000);
        residualVariance = source.dip.rv;
        resultsData(runIdx,:) = [bscr, radiusMm, depthBiasMm, residualVariance];

        EEG_save = struct();
        EEG_save.chanlocs = EEG.chanlocs;
        EEG_save.etc.simUDL.headmodel = headmodel;
        EEG_save.etc.simUDL.udlPos = udlPos;
        EEG_save.etc.simUDL.udlMom = udlMom;
        EEG_save.etc.simUDL.leadfieldMatrix = lfUDL;
        EEG_save.etc.simUDL.lfmScalingFactor = lfmScalingFactor;
        EEG_save.dipfit.dipoleEst.posxyz = source.dip.pos*1000;
        EEG_save.dipfit.dipoleEst.momxyz = source.dip.mom'*1000;
        EEG_save.dipfit.dipoleEst.rv = residualVariance;
        EEG_save.dipfit.dipoleEst.datapot = source.Vdata;
        EEG_save.dipfit.dipoleEst.sourcepot = source.Vmodel;
        EEG_save.params = struct('bscr',bscr,'radius_mm',radiusMm, ...
            'depth_mm',udlDepth*1000,'est_depth',estDepthMm, ...
            'depth_bias',depthBiasMm,'residual_variance',residualVariance);
        save(fullfile(outDir, sprintf('EEG_bscr%d_r%d_udl%d.mat', bscr, radiusMm, round(udlDepth*1000))), ...
            'EEG_save', '-v7.3');
    end
end
assert(size(resultsData,1)==27 && all(isfinite(resultsData(resultsData(:,2)>1,3:4)),'all'), ...
    'Expected 27 rows and finite fit results for all UDL radii >=2 mm.');
T = array2table(resultsData,'VariableNames', ...
    {'BSCR','Radius_mm','Depth_Bias_mm','Residual_Variance'});
writetable(T, fullfile(outDir,'results_all.csv'));
save(fullfile(outDir,'results_all.mat'),'T','resultsData','bscrValues','radiusValues','udlDepth');
fprintf('Completed %d simulations.\n',numRuns);
