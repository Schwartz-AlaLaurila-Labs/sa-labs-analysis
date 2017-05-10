%%
tbUseProject('sa-labs-analysis', 'online', false);

%% Create Analysis Project

clear;
project = createAnalysisProject('Example-LightStep-Analysis', 'experiments', '20170407') %#ok

%% Create Analysis structure
analysisPreset = struct();
analysisPreset.type = 'analysis-type-1';
analysisPreset.buildTreeBy = {'displayName', 'chan1Mode, chan2Mode, chan3Mode, chan4Mode'};
analysisPreset.chan1Mode.splitValue = {'Cell attached'};
analysisPreset.chan2Mode.splitValue = {'Cell attached'};
analysisPreset.chan3Mode.splitValue = {'Cell attached'};
analysisPreset.chan4Mode.splitValue = {'Cell attached'};


%% Build Analysis structure

buildAnalysis('Example-LightStep-Analysis', analysisPreset)

%% Get the finder for tree 

finder = getFeatureFinder('Example-LightStep-Analysis', 'cellData', 'dc1');
finder.getStructure().tostring()

%%