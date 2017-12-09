classdef TreeBrowserPresenter < appbox.Presenter
    
    properties
        analysisManager
        fileRepository
    end
    
    properties (Access = private)
        log
        settings
        uuidToNode
    end
    
    methods
        
        function obj = TreeBrowserPresenter(analysisManager, fileRepository, view)
            if nargin < 4
                view = sa_labs.analysis.ui.TreeBrowserView();
            end
            obj = obj@appbox.Presenter(view);
            
            obj.log = logging.getLogger(app.Constants.ANALYSIS_LOGGER);
            obj.settings = sa_labs.analysis.TreeBrowserSettings();
            obj.fileRepository = fileRepository;
            obj.uuidToNode = containers.Map();
        end
        
    end
    
    methods (Access = protected)
        
        function willGo(obj)
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