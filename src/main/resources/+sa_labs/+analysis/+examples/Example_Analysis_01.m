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

preProcessors = {@(d) sa_labs.pre_processors.addSpikesToEpoch(d, 'device', {'Amp1'}, 'checkDetection', false)};
%
% b) run the preProcess for the selected cells present in project in order
% to save some time

cellDataArray = project.getCellDataArray();
% detecting spikes for the first cell data
offlineAnalysisManager.preProcess(cellDataArray(1), preProcessors,  'enabled', [true]);

%
open(project.file)
%% Create a simple search tree definition

analysisPreset = struct();
analysisPreset.type = 'listByProtocol';
analysisPreset.buildTreeBy = {'displayName', 'stimTime'};

% Build the tree based on the tree definition

buildAnalysis('Example-Analysis', analysisPreset)

%% Create Finder for searching through tree

finder = getFeatureFinder('Example-Analysis', 'cellData', '2017-10-02c1', 'pattern', false);
finder.getStructure().tostring()
%
%
%    '                                                        project==Example-Analysis (1)                                                         '
%    '                                                                                                                                              '
%    '                                                                      |                                                                       '
%    '                                               analysis==listByProtocol-2017-10-02c1_Amp1 (2)                                                 '
%    '                    +-----------------------------------+-------------+---------------+-----------------------------------+                   '
%    '                    |                                   |                             |                                   |                   '
%    '      displayName==Auto Center (3)         displayName==Light Step (6) displayName==Spatial Noise (8)   displayName==White Noise Flicker (10) '
%    '         +----------+---------+                         |                                                                 |                   '
%    '         |                    |                         |                             |                                   |                   '
%    'stimTime==1000 (4)  stimTime==196100 (5)       stimTime==1000 (7)            stimTime==10000 (9)                 stimTime==8000 (11)          '
%%
% a) To list all the epoch group for protocol Auto Center

featureGroup = finder.find('stimTime==1000')...
    .where(@(featureGroup) strcmpi(featureGroup.getParameter('displayName'), 'Auto Center')).toArray();

% b) To get all the epochs corresponds to the above featureGroup

epochs = featureGroup.getFeatureData('AMP1_EPOCH');

% c) To get all the spikes corresponds to the above featureGroup

spikeTimes = featureGroup.getFeatureData('AMP1_SPIKES');


