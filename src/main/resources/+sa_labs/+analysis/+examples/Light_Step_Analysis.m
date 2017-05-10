%%
tbUseProject('sa-labs-analysis', 'online', false);

%% Create Analysis Project

clear;
project = createAnalysisProject('Example-LightStep-Analysis', 'experiments', '20170407') %#ok

%% Create Analysis structure
analysisPreset = struct();
analysisPreset.type = 'analysis-type-1';
analysisPreset.buildTreeBy = {'displayName', ' @(e) sa_labs.analysis.examples.getAmplifiers(e)'};

%% Build Analysis structure

buildAnalysis('Example-LightStep-Analysis', analysisPreset)

%% Get the finder for tree 

finder = getFeatureFinder('Example-LightStep-Analysis', 'cellData', 'dc1');
finder.getStructure().tostring()

%%