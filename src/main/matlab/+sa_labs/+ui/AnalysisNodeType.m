classdef AnalysisNodeType
    
    enumeration
        ANALYSIS_GROUP
        FEATURE_GROUP
        FEATURE
        SUMMARY
    end
    
    methods
        function c = char(obj)
            import sa_labs.analysis.ui.AnalysisNodeType;
            
            switch obj
                case AnalysisNodeType.ANALYSIS_GROUP
                    c = 'Analysis Group';
                case AnalysisNodeType.FEATURE_GROUP
                    c = 'Feature Group';
                case AnalysisNodeType.FEATURE
                    c = 'Feature';
                case AnalysisNodeType.SUMMARY
                    c = 'Summary';
                otherwise
                    c = 'Unknown';
            end
        end
        
        function tf = isFeaturesFolder(obj)
            tf = obj == sa_labs.analysis.ui.AnalysisNodeType.FEATURE_GROUP;
        end
        
        function tf = isAnalysisFolder(obj)
            tf = obj == sa_labs.analysis.ui.AnalysisNodeType.ANALYSIS_GROUP;
        end
    end
end