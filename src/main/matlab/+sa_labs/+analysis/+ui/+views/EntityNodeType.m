classdef EntityNodeType
    
    enumeration
        EXPERIMENT
        CELLS
        EPOCH
    end
    
    methods
        
        function c = char(obj)
            import sa_labs.analysis.ui.views.EntityNodeType;
             
            switch obj
                case EntityNodeType.EXPERIMENT
                    c = 'Experiment';
                case EntityNodeType.CELLS
                    c = 'Cell Folder';
                case EntityNodeType.EPOCH
                    c = 'Epoch';
                otherwise
                    c = 'Unknown';
            end
        end
        
        function tf = isExperiment(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.EXPERIMENT;
        end
        
        function tf = isCell(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.CELLS;
        end
        
        function tf = isEpoch(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.EPOCH;
        end
    end
    
end

