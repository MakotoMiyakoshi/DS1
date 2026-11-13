% p0010_preprocess_Dortmund.m
% Consolidated from archived code_Dortmund/p0100_imported.m and
% p0101..p0108_imported.m (parallel partition copies).
% The DS1 author confirms the actual processing used BurstCriterion=20 SD.
% The archived single-loop version with 25 is obsolete; no override here.
clear
close all
clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(projectRoot,mfilename);
if ~isfolder(outDir),mkdir(outDir);end
rawRoot = getenv('DS1_DORTMUND_RAW_DIR');
eeglabRoot = getenv('DS1_DORTMUND_EEGLAB_ROOT');
assert(isfolder(rawRoot),'Set DS1_DORTMUND_RAW_DIR to the directory of raw sub-* folders.');
assert(isfolder(eeglabRoot),'Set DS1_DORTMUND_EEGLAB_ROOT (legacy EEGLAB 2024.2.1).');
burstCriterion = 20;
addpath(eeglabRoot);
eeglab('nogui');
assert(~isempty(which('runamica15')) && ~isempty(which('loadmodout15')), ...
    'AMICA runamica15/loadmodout15 unavailable.');
assert(~isempty(which('fitTwoDipoles')),'Missing fitTwoDipoles.');
assert(~isempty(which('pop_biosig')),'Missing BIOSIG EDF importer.');

dipfitRoot = fileparts(which('pop_dipfit_settings'));
standardBEM = fullfile(dipfitRoot,'standard_BEM');
elecFile = fullfile(standardBEM,'elec','standard_1005.elc');
assert(isfile(elecFile) && isfile(fullfile(standardBEM,'standard_vol.mat')), ...
    'Installed EEGLAB DIPFIT BEM resources not found.');

allSubj = dir(fullfile(rawRoot,'sub-*'));
allSubj = allSubj([allSubj.isdir]);
assert(~isempty(allSubj),'No Dortmund sub-* folders found.');
[~,sortingOrder] = sort({allSubj.name});
allSubj = allSubj(sortingOrder);
for subjIdx = 1:numel(allSubj)
    rng(200000+subjIdx, 'twister');
    dataName = allSubj(subjIdx).name;
    try
        sourceDir = fullfile(rawRoot,dataName,'ses-1','eeg');
        eo = dir(fullfile(sourceDir,'*EyesOpen_acq-pre*.edf'));
        ec = dir(fullfile(sourceDir,'*EyesClosed_acq-pre*.edf'));
        assert(numel(eo)==1 && numel(ec)==1,'Expected exactly one EO EDF and one EC EDF for %s.',dataName);
        EEG_EO = pop_biosig(fullfile(eo(1).folder,eo(1).name));
        EEG_EC = pop_biosig(fullfile(ec(1).folder,ec(1).name));
        EEG = pop_mergeset(EEG_EO,EEG_EC);
        EEG.setname = [dataName ' Pre EO EC'];
        EEG = pop_resample(EEG,250);
        EEG = pop_firws(EEG,'fcutoff',1.5,'ftype','highpass', ...
            'wtype','hamming','forder',826,'minphase',0);
        EEG = pop_chanedit(EEG,'lookup',elecFile);
        EEG_beforeASR = EEG;
        EEG = pop_clean_rawdata(EEG,'FlatlineCriterion','off','ChannelCriterion','off', ...
            'LineNoiseCriterion','off','Highpass','off', ...
            'BurstCriterion',burstCriterion,'WindowCriterion','off', ...
            'BurstRejection','off','Distance','Euclidian', ...
            'BurstCriterionRefMaxBadChns',0, ...
            'BurstCriterionRefTolerances',[-inf 8], ...
            'WindowCriterionTolerances',[-Inf 8], ...
            'MaxMem',2^16);
        if isfield(EEG.etc,'clean_sample_mask')
            cleanSampleIdx = find(EEG.etc.clean_sample_mask);
        else
            cleanSampleIdx = 1:EEG.pnts;
        end
        EEG.etc.asrPowerReductionDb = 10*log10(var(EEG.data,0,2)./ ...
            var(EEG_beforeASR.data(:,cleanSampleIdx),0,2));
        EEG.nbchan = EEG.nbchan+1;
        EEG.data(end+1,:) = zeros(1,EEG.pnts);
        EEG.chanlocs(1,EEG.nbchan).labels = 'FCz';
        EEG = pop_reref(EEG,[]);
        EEG_downsampled = pop_resample(EEG,100);
        numICs = sum(eig(cov(double(EEG_downsampled.data'))) > 1E-6);
        amicaDir = fullfile(outDir,dataName);
        if ~isfolder(amicaDir),mkdir(amicaDir);end
        runamica15(double(EEG_downsampled.data),'outdir',amicaDir, ...
            'max_iter',2000,'max_threads',16,'pcakeep',numICs, ...
            'writestep',2000,'do_reject',1,'numrej',10, ...
            'rejsig',3,'rejstart',1,'rejint',1);
        EEG.etc.amica = loadmodout15(amicaDir);
        EEG.icaweights = EEG.etc.amica.W;
        EEG.icasphere = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs,:);
        EEG.icawinv = EEG.etc.amica.A;
        EEG.icachansind = 1:EEG.nbchan;
        EEG = iclabel(EEG,'default');
        EEG = pop_dipfit_settings(EEG,'hdmfile',fullfile(standardBEM,'standard_vol.mat'), ...
            'mrifile',fullfile(standardBEM,'standard_mri.mat'), ...
            'chanfile',elecFile,'coordformat','MNI', ...
            'coord_transform',[0 0 0 0 0 -pi/2 1 1 1]);
        EEG = pop_multifit(EEG,1:numICs,'threshold',100,'plotopt',{'normlen','on'});
        EEG = fitTwoDipoles(EEG,'LRR',35);
        EEG.etc.ds1_burst_criterion = burstCriterion;
        EEG.etc.ds1_preprocess_origin = 'code_Dortmund/p0100_imported.m or p0101..p0108_imported.m';
        pop_saveset(EEG,'filename',[dataName '.set'],'filepath',outDir);
    catch ME
        errFile = fullfile(outDir,['ERROR_' dataName '.txt']);
        fid = fopen(errFile,'w');
        if fid~=-1
            fprintf(fid,'%s\n',getReport(ME,'extended','hyperlinks','off'));
            fclose(fid);
        end
        rethrow(ME);
    end
end
fprintf('Dortmund preprocessing completed: %d participants; ASR criterion %g.\n', ...
    numel(allSubj),burstCriterion);
