ctx = struct();

ctx.fileRepository.class = 'sa_labs.analysis.app.FileRepository';
ctx.fileRepository.entityMigrationsFolder = 'sa_labs.analysis.entity.migrations';
% ctx.fileRepository.analysisFolder = 'R:\ala-laurila_lab\users\narayas2';
% ctx.fileRepository.rawDataFolder = 'R:\ala-laurila_lab\data\takeshd1\rawdata';

ctx.analysisDao.class = 'sa_labs.analysis.dao.AnalysisFolderDao';
ctx.analysisDao.repository = 'fileRepository';

ctx.preferenceDao.class = 'sa_labs.analysis.dao.PreferenceDao';
ctx.preferenceDao.repository = 'fileRepository';

ctx.parserFactory.class = 'sa_labs.analysis.factory.ParserFactory';
ctx.analysisFactory.class = 'sa_labs.analysis.factory.AnalysisFactory';

ctx.offlineAnalaysisManager.class = 'sa_labs.analysis.app.OfflineAnalaysisManager';
ctx.offlineAnalaysisManager.analysisDao = 'analysisDao';
ctx.offlineAnalaysisManager.parserFactory = 'parserFactory';
ctx.offlineAnalaysisManager.analysisFactory = 'analysisFactory';
