%%
tbUseProject('sa-labs-analysis', 'online', false);

%% Create Analysis Project

clear;
project = createAnalysisProject('Example-LightStep-Analysis', 'experiments', '20170407') %#ok

%% Create Analysis structure

analysisPreset = struct();
analysisPreset.type = 'analysis-type-1';
analysisPreset.buildTreeBy = {'displayName', 'devices', 'mode'};
analysisPreset.devices.splitValue = {'Amp1', 'Amp2'};
analysisPreset.mode.splitValue = {'Cell attached'};

%% Build Analysis structure

buildAnalysis('Example-LightStep-Analysis', analysisPreset)

%% Get the finder for tree 

finder = getFeatureFinder('Example-LightStep-Analysis');
finder.getStructure().tostring()

%%