classdef EntityNodeType
    
    enumeration
        EXPERIMENT
        CELLS
        EPOCH
        ANALYSIS_RESULTS
        ANALYSIS_GROUPS
        ANALYSIS
        EPOCH_GROUP
        FEATURE
    end
    
    methods
        
        function c = char(obj)
            import sa_labs.analysis.ui.views.EntityNodeType;
             
            switch obj
                case EntityNodeType.EXPERIMENT
                    c = 'Experiment';
                case EntityNodeType.CELLS
                    c = 'Cell';
                case EntityNodeType.EPOCH
                    c = 'Epoch';
                case EntityNodeType.ANALYSIS_RESULTS
                    c = 'Analysis Results';    
                case EntityNodeType.ANALYSIS_GROUPS
                    c = 'Analysis Groups';
                case EntityNodeType.ANALYSIS
                    c = 'Analysis';   
                case EntityNodeType.EPOCH_GROUP
                    c = 'Epoch Group';
                case EntityNodeType.FEATURE
                    c = 'Feature';                                           
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

        function tf = isAnalysisResults(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.ANALYSIS_RESULTS;
        end

        function tf = isAnalysisGroups(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.ANALYSIS_GROUPS;
        end

        function tf = isAnalysis(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.ANALYSIS;
        end

        function tf = isEpochGroup(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.EPOCH_GROUP;
        end

        function tf = isFeature(obj)
            tf = obj == sa_labs.analysis.ui.views.EntityNodeType.FEATURE;
        end
    end
    
end

