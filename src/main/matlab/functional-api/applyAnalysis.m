function finder = applyAnalysis(projectName, functions, varargin)

offlineAnalysisManager = getInstance('offlineAnalaysisManager');

ip = inputParser();
ip.addParameter('finder', offlineAnalysisManager.getFeatureFinder(projectName), @isobject)
ip.addParameter('criteria', '', @ischar);
ip.addParameter('featureGroups', [], @isobject);
ip.parse(varargin{:})
finder = ip.Results.finder;
criteria = ip.Results.criteria;
featureGroups = ip.Results.featureGroups;

if isempty(featureGroups) && ~ isempty(criteria)
    featureGroups = finder.findFeatureGroup(criteria);
end

finder = offlineAnalysisManager.applyAnalysis(finder, featureGroups, functions);
end

