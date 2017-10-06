function [project, offlineAnalysisManager] = createAnalysisProject(projectName, varargin)

import sa_labs.analysis.*;

ip = inputParser();
ip.addParameter('experiments', '', @(e) ischar(e) || iscellstr(e));
ip.addParameter('user', getenv('username'), @ischar);
ip.addParameter('description', 'Hope it will be defined later !', @ischar);
ip.addParameter('override', false, @islogical);

ip.parse(varargin{:});
experiments = ip.Results.experiments;
user = ip.Results.user;
description = ip.Results.description;
canOverRide = ip.Results.override;

offlineAnalysisManager = getInstance('offlineAnalaysisManager');
try
    if canOverRide
        overrideProject();
    end
    project = offlineAnalysisManager.initializeProject(projectName);
    if isNewExperiment(experiments, project.experimentList)
        project.addExperiments(experiments);
        offlineAnalysisManager.createProject(project);
    end
    
catch exception
    
    if ~ strcmp(exception.identifier, app.Exceptions.NO_PROJECT.msgId)
        rethrow(exception);
    end
    
    overrideProject();
end

    function overrideProject()
        import sa_labs.analysis.*;
        
        fileRepo = getInstance('fileRepository');
        
        project = entity.AnalysisProject();
        project.identifier = projectName;
        project.analysisDate = fileRepo.dateFormat(date);
        project.addExperiments(experiments);
        project.performedBy = user;
        project.description = description;
        
        offlineAnalysisManager.createProject(project);
    end
end

function tf = isNewExperiment(experiments, experimentList)
tf =  ~ isempty(experiments) && any(~ ismember(experiments, experimentList));
end