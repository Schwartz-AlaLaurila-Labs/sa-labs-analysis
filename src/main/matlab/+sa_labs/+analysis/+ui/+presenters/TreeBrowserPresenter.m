classdef TreeBrowserPresenter < appbox.Presenter
    
    properties
        analysisManager
        fileRepository
    end
    
    properties (Access = private)
        analysisprojectName
        featureTreeFinder
        log
        settings
        uuidToNode
    end
    
    properties (Constant)
        ANALYSES_PLOTS = 'sa_labs.analysis.tree_browser.plots'
    end
    
    methods
        
        function obj = TreeBrowserPresenter(projectName, analysisManager, fileRepository, view)
            if nargin < 4
                view = sa_labs.analysis.ui.TreeBrowserView();
            end
            obj = obj@appbox.Presenter(view);
            obj.analysisprojectName = projectName;
            obj.log = logging.getLogger(app.Constants.ANALYSIS_LOGGER);
            obj.settings = sa_labs.analysis.ui.settings.TreeBrowserSettings();
            obj.fileRepository = fileRepository;
            obj.uuidToNode = containers.Map();
        end
        
    end
    
    methods (Access = protected)
        
        function willGo(obj)
            obj.initalizeAnalysisProject();
            obj.populateAvailablePlots();
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load presenter settings: ' x.message]);
            end
            obj.updateStateOfControls();
        end
        
        function willStop(obj)
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save presenter settings: ' x.message]);
            end
        end
        
        function bind(obj)
            bind@appbox.Presenter(obj);
            
            v = obj.view;
            obj.addListener(v, 'SelectedNodes', @obj.onViewSelectedNodes).Recursive = true;
            obj.addListener(v, 'AddAnalysisTree', @obj.onViewAddAnalysisTree);
        end
    end
    
    methods (Access = private)
        
        function initalizeAnalysisProject(obj)
            [finder, project] = obj.analysisManager.getFeatureFinder(obj.analysisprojectName);
            obj.featureTreeFinder = finder;
            root = obj.view.setAnalysisProjectNode(project.identifier, project);

            for analysisType = each(project.getUniqueAnalysisTypes())
                analysisNode = obj.view.addAnalysisNode(root, analysisType);

                for cellName = each(project.getCellNames(analysisType));
                    cellData = project.getCellData(cellName);
                    n = obj.view.addCellsNode(analysisNode, cellName, cellData);
                    obj.uuidToNode(cellData.uuid) = n
                    
                    groupName = project.getAnalysisResultName(analysisType, cellName);
                    obj.addEpochGroups(groupName, n);
                end
            end
        end

        function addEpochGroups(obj, groupName, parentNode, parentGroupName)
            
            if nargin < 4
                parentGroupName = [];
            end
            epochGroups = obj.featureTreeFinder.find(groupName, 'hasParent', parentGroupName).toArray();

            for epochGroup = each(epochGroups)
                n = obj.view.addEpochGroupNode(parentNode, epochGroup);
                obj.uuidToNode(epochGroup.uuid) = n;
                obj.addFeatures(epochGroup);
                obj.addEpochGroups(epochGroup.name, n, groupName);
            end
        end

        function addFeatures(obj, epochGroup)
            parent = obj.uuidToNode(epochGroup.uuid);
            
            for key = each(obj.epochGroup.getFeatureKey());
                obj.view.addFeatureNode(parent, key);
            end
        end

        function populateAvailablePlots(obj)
            plots = {meta.package.fromName(obj.ANALYSES_PLOTS).FunctionList.Name};
            functionNames = {};
            for plot = each(plots)
                functionNames{end + 1} = [obj.ANALYSES_PLOTS '.'  plot]; %#ok
            end
            obj.view.setAvailablePlots(plots, functionNames);
        end

        function onViewAddAnalysisTree(obj, ~, ~)
            analysisFolder = obj.fileRepository.analysisFolder;
            files = obj.view.showGetFile('Select Analysis Trees', '*.mat', analysisFolder);
            warning('Not implemented !');
        end

        function updateStateOfControls(obj)
            
        end
        
        function loadSettings(obj)
            if ~isempty(obj.settings.viewPosition)
                obj.view.position = obj.settings.viewPosition;
            end
        end
        
        function saveSettings(obj)
            obj.settings.viewPosition = obj.view.position;
            obj.settings.save();
        end        
    end
end