function [instance, ctxt] = getInstance(name)

LOGGER_NAME = sa_labs.analysis.app.Constants.ANALYSIS_LOGGER;
instance = [];
persistent context;
try
    if isempty(context)
        try
            logging.clearLogger(LOGGER_NAME);
        catch e %#ok
            % do nothing
        end
        context = mdepin.getBeanFactory(which('AnalysisContext.m'));
        setLogger();
    end
    
    if isempty(name)
        ctxt = context;
        return
    end
    instance = context.getBean(name);
    
catch exception
    disp(['Error getting instance (' name ') ' exception.message]);
end
ctxt = context;
setLogger();

    function setLogger()
        logger = logging.getLogger(LOGGER_NAME);
        if strfind(logger.fullpath, char(date))
            return
        end
        path = context.getBean('fileRepository').logFile;
        logger = logging.getLogger(LOGGER_NAME);
        logger.setFilename(path);
        logger.setLogLevel(logging.logging.INFO);
        logger.setCommandWindowLevel(logging.logging.WARNING);
    end
end
