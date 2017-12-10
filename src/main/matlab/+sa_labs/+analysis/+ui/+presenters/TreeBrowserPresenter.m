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
            import  sa_labs.analysis.*;
            if nargin < 4
                view = ui.views.TreeBrowserView();
            end
            
            obj = obj@appbox.Presenter(view);
            obj.analysisprojectName = projectName;
            obj.analysisManager = analysisManager;
            obj.log = logging.getLogger(app.Constants.ANALYSIS_LOGGER);
            obj.settings = ui.settings.TreeBrowserSettings();
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

                for cellName = each(project.getCellNames(analysisType))
                    cellData = project.getCellData(cellName);
                    n = obj.view.addCellsNode(analysisNode, cellName, cellData);
                    groupName = project.getAnalysisResultName(analysisType, cellName);
                    obj.addEpochGroup(groupName, n);
                end
            end
        end

        function addEpochGroup(obj, groupName, parentNode, parentGroupName)
            isNodeCreated = false;
            if nargin < 4
                parentGroupName = [];
                isNodeCreated = true;
            end
            
            finder = obj.featureTreeFinder;
            epochGroup = finder.find(groupName, 'hasParent', parentGroupName).toArray();
            % create node only for epoch groups
            if ~ isNodeCreated
                n = obj.view.addEpochGroupNode(parentNode, epochGroup.name, epochGroup);
            else
                n = parentNode;
            end
            obj.uuidToNode(epochGroup.uuid) = n;
            obj.addFeatures(epochGroup);            
            
            for childEpochGroup = each(finder.getChildEpochGroups(epochGroup))
                obj.addEpochGroup(childEpochGroup.name, n, epochGroup.name);
            end
        end

        function addFeatures(obj, epochGroup)
            parent = obj.uuidToNode(epochGroup.uuid);
            
            for key = each(epochGroup.getFeatureKey())
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