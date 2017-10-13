classdef DataCuratorPresenter < appbox.Presenter

	properties
		viewSelectedCloseFcn
	end 

	properties (Access = protected)
		offlineAnalysisManager
	end

	properties (Access = private)
		log
		settings
		uuidToNode
	end

	methods 
		function obj = DataCuratorPresenter(offlineAnalysisManager, view)
			import sa_labs.analysis.*;
			if nargin < 2
			    view = ui.views.DataCuratorView();
			end
			obj = obj@appbox.Presenter(view);
			obj.offlineAnalysisManager = offlineAnalysisManager;
			obj.settings = ui.settings.DataCuratorSettings();
			obj.log = logging.getLogger(app.Constants.ANALYSIS_LOGGER);
			obj.uuidToNode = containers.Map();
		end
	end

	methods (Access = protected)
        
        function willGo(obj)
        	obj.populateCellDataFilters();
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load presenter settings: ' x.message]);
            end
            obj.updateStateOfControls();
        end

        function willStop(obj)
            obj.viewSelectedCloseFcn = [];
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save presenter settings: ' x.message]);
            end
        end

        function bind(obj)
            bind@appbox.Presenter(obj);

            v = obj.view;
            obj.addListener(v, 'LoadH5File', @obj.onViewLoadH5File);
            obj.addListener(v, 'ReParse', @obj.onViewReParse);
          	obj.addListener(v, 'SelectedNodes', @obj.onViewSelectedNodes).Recursive = true;

        end

        function onViewSelectedClose(obj, ~, ~)
            if ~isempty(obj.viewSelectedCloseFcn)
                obj.viewSelectedCloseFcn();
            end
        end		
	end

	methods (Access = private)
        
		function onViewLoadH5File(obj, ~, ~)
			obj.populateCellDataEntity();
		end

		function populateCellDataEntity(obj)
			pattern = obj.view.getH5FileLocation();
			cellDataArray = obj.offlineAnalysisManager.getParsedCellData(pattern);
			obj.view.setExperimentNode(pattern, cellDataArray);

			for cellData = each(cellDataArray)
				obj.addCellDataNode(cellData);
			end
			obj.view.expandNode(obj.view.getCellFolderNode());
		end

		function addCellDataNode(obj, cellData)
			parent = obj.view.getCellFolderNode();
			n = obj.view.addCellDataNode(parent, cellData.recordingLabel, cellData);
            obj.uuidToNode(cellData.uuid) = n;
            
            for epoch = each(cellData.epochs)
            	if ~ epoch.excluded || epoch.filtered
            		obj.addEpochDataNode(epoch);
            	end
            end
		end

		function addEpochDataNode(obj, epoch)
			parent = obj.uuidToNode(epoch.parentCell.uuid);
            epochNumber = num2str(epoch.get('epochNumber'));
			n = obj.view.addEpochDataNode(parent, epochNumber, epoch);
            obj.uuidToNode(epoch.uuid) = n;			
		end

        function populateCellDataFilters(obj)
        	filters = obj.offlineAnalysisManager.getCellDataFilters();
        	obj.view.loadCellDataFilters({filters.name});
        end	
        
        function onViewSelectedNodes(obj, ~, ~)
            % obj.view.stopEditingProperties();
            obj.view.update();

            entities = obj.getSelectedEntitySet();
            obj.populateDetailsForEntitySet(entities);
        end

        function entities = getSelectedEntitySet(obj)
            nodes = obj.view.getSelectedNodes();
            entities = [];
            for node = each(nodes)
                entity = obj.view.getNodeEntity(node);
                if ~ isempty(entity)
                    entities = [entities, entity]; %#ok
                end
            end
        end

        function populateDetailsForEntitySet(obj, entities)
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