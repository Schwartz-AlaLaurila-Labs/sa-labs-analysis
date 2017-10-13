classdef AnalayserPresenter < appbox.Presenter
    
    properties
        viewSelectedCloseFcn
    end
    
    properties (Access = private)
        log
        settings
        dataService
        featureManager
        uuidToNode
    end
    
    methods
        
        function obj = AnalaysisManagerPresenter(analysisManager, view)
            if nargin < 4
                view = sa_labs.analysis.ui.AnalaysisManagerView();
            end
            obj = obj@appbox.Presenter(view);
            
            obj.log = log4m.LogManager.getLogger(class(obj));
            obj.settings = sa_labs.analysis.AnalysisManagerSettings();
            obj.dataService = analysisManager.dataService;
            featureManager = analysisManager.getFeatureManager();
            obj.detailedEntitySet = symphonyui.core.persistent.collections.EntitySet();
            obj.uuidToNode = containers.Map();
        end
        
    end
    
    methods (Access = protected)
        
        function willGo(obj)
            obj.populateEntityTree();
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load presenter settings: ' x.message], x);
            end
            obj.updateStateOfControls();
        end
        
        function willStop(obj)
            obj.viewSelectedCloseFcn = [];
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save presenter settings: ' x.message], x);
            end
        end
        
        function bind(obj)
            bind@appbox.Presenter(obj);
            
            v = obj.view;
            obj.addListener(v, 'SelectedNodes', @obj.onViewSelectedNodes).Recursive = true;
            obj.addListener(v, 'SelectedEpochGroupSignal', @obj.onViewSelectedEpochGroupSignal);
            obj.addListener(v, 'SelectedFeatureSignal', @obj.onViewSelectedFeatureSignal);
            obj.addListener(v, 'AddFeature', @obj.onViewAddFeature);
            obj.addListener(v, 'SendEntityToWorkspace', @obj.onViewSelectedSendEntityToWorkspace);
            obj.addListener(v, 'DeleteEntity', @obj.onViewSelectedDeleteEntity);
            
        end
        
        function onViewSelectedClose(obj, ~, ~)
            if ~isempty(obj.viewSelectedCloseFcn)
                obj.viewSelectedCloseFcn();
            end
        end
    end
    
    methods (Access = private)
        
        function populateEntityTree(obj)
        end
        
        function loadSettings(obj)
        end
        
        function saveSettings(obj)
        end
        
        function updateStateOfControls(obj)
        end
        
        function onViewSelectedNodes(obj, ~, ~)
        end
        
        function onViewSelectedEpochGroupSignal(obj, ~, ~)
        end
        
        function onViewAddFeature(obj, ~, ~)
        end
        
        function onViewSelectedSendEntityToWorkspace(obj, ~, ~)
        end
        
        function onViewSelectedDeleteEntity(obj, ~, ~)
        end
        
    end
end