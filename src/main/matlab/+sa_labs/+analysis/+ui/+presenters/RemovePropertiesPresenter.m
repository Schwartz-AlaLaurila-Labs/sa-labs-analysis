classdef RemovePropertiesPresenter < appbox.Presenter

    properties (Access = private)
        log
        entities
    end

    methods

        function obj = RemovePropertiesPresenter(entities, view)
            if nargin < 2
                view = sa_labs.analysis.ui.views.RemovePropertiesView();
            end
            obj = obj@appbox.Presenter(view);
            obj.view.setWindowStyle('modal');

            obj.log = logging.getLogger(sa_labs.analysis.app.Constants.ANALYSIS_LOGGER);
            obj.entities = entities;
        end

    end

    methods (Access = protected)

        function didGo(obj)
            properties = {};
            for entity = obj.entities
                properties = entity.unionAttributeKeys(properties);
            end
            obj.view.setAvailableProperties(properties);
        end

        function bind(obj)
            bind@appbox.Presenter(obj);
            
            v = obj.view;
            obj.addListener(v, 'KeyPress', @obj.onViewKeyPress);
            obj.addListener(v, 'Remove', @obj.onViewSelectedRemove);
            obj.addListener(v, 'Cancel', @obj.onViewSelectedCancel);
        end
    end

    methods (Access = private)

        function onViewKeyPress(obj, ~, event)
            switch event.data.Key
                case 'return'
                    obj.onViewSelectedRemove();
                case 'escape'
                    obj.onViewSelectedCancel();
            end
        end

        function onViewSelectedRemove(obj, ~, ~)
            obj.view.update();

            properties = obj.view.getSelectedProperties();
            try
                for entity = obj.entities
                    remove(entity.attributes, properties);
                end
            catch x
                obj.log.debug(x.message);
                obj.view.showError(x.message);
                return;
            end
            obj.stop();
        end

        function onViewSelectedCancel(obj, ~, ~)
            obj.stop();
        end

    end

end
