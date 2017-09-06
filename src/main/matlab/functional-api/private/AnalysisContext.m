ctx = struct();

ctx.fileRepository.class = 'sa_labs.analysis.app.FileRepository';

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
