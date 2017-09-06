function migrateToOldAnalysis(project)

% set global variable for old analysis
setOldAnalysisPath();

% copy old celldata to folder
cellDataList = project.getCellDataList();
for i = 1 : numel(cellDataList)
    saveCellData(cellDataList{i}, i);
end

% create temp folder for experiment
exp = project.experimentDate;
makeTempFolderForExperiment(exp);

end

function saveCellData(newCellData, id)

oldCellData = CellData();
% TODO add other attributes
oldCellData.attributes = newCellData.attributes;
oldCellData.savedFileName = [newCellData.savedFileName 'c' num2str(id)];

n = numel(newCellData.epochs);
oldCellData.epochs = EpochData.empty(0, n);

for i = 1 : n
    e = EpochData();
    e.attributes = newCellData.epochs(i).attributes;
    e.dataLinks = newCellData.epochs(i).dataLinks;
    e.parentCell = oldCellData;
    
    if isKey(e.attributes, 'SPIKES')
        e.attributes('spikes_ch1') =  e.attributes('SPIKES').data';
        remove(e.attributes, 'SPIKES');
    end
    if isKey(e.dataLinks, 'Amp1')
         e.dataLinks('Amplifier_Ch1') =  e.dataLinks('Amp1');
         remove(e.dataLinks, 'Amp1');
    end
    oldCellData.epochs(i) = e;
end

global ANALYSIS_FOLDER
cellDataDir = fullfile([ANALYSIS_FOLDER 'cellData\']);
cellData = oldCellData;
save([cellDataDir oldCellData.savedFileName '.mat'], 'cellData');
end


function setOldAnalysisPath()

if ~ isPathSet() && ispc()
    fileRepo = getInstance('fileRepository');
    
    p = userpath();
    if p(end) == ';'
        p(end) = '';
    end
    documents = fileparts(p);
    global ANALYSIS_FOLDER %#ok
    ANALYSIS_FOLDER = [documents '\v1-data\analysis\'];
    global RAW_DATA_FOLDER %#ok
    RAW_DATA_FOLDER = fileRepo.rawDataFolder;
    global ANALYSIS_CODE_FOLDER %#ok
    ANALYSIS_CODE_FOLDER = [p '\projects\SymphonyAnalysis'];
    global PREFERENCE_FILES_FOLDER %#ok
    PREFERENCE_FILES_FOLDER = which('PreferenceFiles');
    addpath(genpath(ANALYSIS_CODE_FOLDER));
    createAnalysisFolders();
    global CELL_DATA_FOLDER %#ok
    CELL_DATA_FOLDER = [ANALYSIS_FOLDER 'cellData\'];
end

end

function tf = isPathSet()

tf = exist('ANALYSIS_FOLDER', 'var')...
    &&  exist('RAW_DATA_FOLDER', 'var')...
    && exist('ANALYSIS_CODE_FOLDER', 'var')...
    && exist('PREFERENCE_FILES_FOLDER', 'var');
end

function createAnalysisFolders()

global ANALYSIS_FOLDER

treeDir = fullfile([ANALYSIS_FOLDER 'analysisTrees\']);
cellDataDir = fullfile([ANALYSIS_FOLDER 'cellData\']);
projDir = fullfile([ANALYSIS_FOLDER 'Projects\']);

if ~ exist(treeDir, 'dir')
    mkdir(treeDir);
end
if ~ exist(cellDataDir, 'dir')
    mkdir(cellDataDir);
end
if ~ exist(projDir, 'dir')
    mkdir(projDir);
end
end
