%% Set the matlab path !
tbUseProject('sa-labs-analysis');

%% Create the analysis project

clear;
[project, offlineAnalysisManager] = createAnalysisProject('Example-Analysis', 'experiments', '2017-10-02', 'override', true);
% open the project file

%% Create and run the pre-processor ! 
%
% Although spike detection is not a pre processing step, for the time being
% including spike detection process in the pre-processing step.
%
% a) Declare the pre processor function

preProcessors = {@(d) sa_labs.pre_processors.addSpikesToEpoch(d, 'device', {'Amp1', 'Amp2', 'Amp3'}, 'checkDetection', false)};
%
% b) run the preProcess for the selected cells present in project in order
% to save some time

cellDataArray = project.getCellDataArray();
% detecting spikes for the first cell data
offlineAnalysisManager.preProcess(cellDataArray(1), preProcessors,  'enabled', [false]);
%
%
open(project.file)
%% Create a simple search tree definition

analysisPreset = struct();
analysisPreset.type = 'listByProtocol';
analysisPreset.buildTreeBy = {'displayName', 'stimTime', 'devices'};

% Build the tree based on the tree definition

buildAnalysis('Example-Analysis', analysisPreset)

%% Create Finder for searching through tree

finder = getFeatureFinder('Example-Analysis', 'cellData', '2017-10-02c2');
finder.getStructure().tostring()

%%
% a) To list all the epoch group for protocol Auto Center

epochGroup = finder.find('displayName==Auto Center').toArray();
epochs = epochGroup.getFeatureData('EPOCH');

%%
% b) To get all the epochs corresponds to the above featureGroup

epochs = epochGroup.getFeatureData('AMP1_EPOCH');

% c) To get all the spikes corresponds to the above featureGroup

spikeTimes = epochGroup.getFeatureData('AMP1_SPIKES');


