classdef FileRepositorySettings < appbox.Settings 
    
    properties
        startupFile
        searchPath
        analysisFolder
        rawDataFolder
        preferenceFolder
        dateFormat
        logFile
    end
    
    methods
        
        function obj = FileRepositorySettings()
            
            if ~ exist(obj.analysisFolder, 'dir')
                mkdir(obj.analysisFolder)
            end
            logDir = [obj.analysisFolder filesep '.logs'];
            if ~ exist(logDir, 'dir')
                mkdir(logDir);
            end
            if ~ exist(obj.rawDataFolder, 'dir')
                mkdir(obj.rawDataFolder)
            end
            if ~ exist(obj.preferenceFolder, 'dir')
                mkdir(obj.preferenceFolder)
            end
        end
        
        function f = get.startupFile(obj)
            f = obj.get('startupFile', '');
        end
        
        function set.startupFile(obj, f)
            validateattributes(f, {'char', 'function_handle'}, {'2d'});
            obj.put('startupFile', f);
        end
        
        function set.searchPath(obj, p)
            validateattributes(p, {'char', 'function_handle'}, {'2d'});
            obj.put('searchPath', p);
        end
        
        function p = get.searchPath(obj)
            p = obj.get('searchPath', sa_labs.analysis.app.App.getResource('examples'));
        end
        
        function f = get.analysisFolder(obj)
            f = obj.get('analysisFolder', fullfile(char(java.lang.System.getProperty('user.home')), 'data', 'analysis'));
        end
        
        function set.analysisFolder(obj, f)
            validateattributes(f, {'char', 'function_handle'}, {'2d'});
            obj.put('analysisFolder', f);
        end
        
        function f = get.rawDataFolder(obj)
            f = obj.get('rawDataFolder', fullfile(char(java.lang.System.getProperty('user.home')), 'data', 'rawDataFolder'));
        end
        
        function set.rawDataFolder(obj, f)
            validateattributes(f, {'char', 'function_handle'}, {'2d'});
            obj.put('rawDataFolder', f);
        end
        
        function f = get.preferenceFolder(obj)
            f = obj.get('preferenceFolder', fullfile(char(java.lang.System.getProperty('user.home')), 'data', 'PreferenceFiles'));
        end
        
        function set.preferenceFolder(obj, f)
            validateattributes(f, {'char', 'function_handle'}, {'2d'});
            obj.put('preferenceFolder', f);
        end
        
        function f = get.dateFormat(obj)
            f = obj.get('dateFormat', @(date) datestr(date, 'yyyymmdd'));
        end
        
        function set.dateFormat(obj, f)
            validateattributes(f, { 'function_handle'}, {'2d'});
            obj.put('dateFormat', f);
        end

        function f = get.logFile(obj)
             f = obj.get('logFile', fullfile(obj.analysisFolder, '.logs', [char(date) '-analysis.log']));
        end

        function set.logFile(obj, f)
            validateattributes(p, {'char', 'function_handle'}, {'2d'});
            obj.put('logFile', f);
        end
    end
    
end

