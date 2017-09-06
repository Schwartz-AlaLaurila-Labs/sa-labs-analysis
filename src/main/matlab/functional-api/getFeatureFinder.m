function finder = getFeatureFinder(projectName, varargin)

offlineAnalysisManager = getInstance('offlineAnalaysisManager');
finder = offlineAnalysisManager.getFeatureFinder(projectName, varargin{:});

end

