function sandbox()
    plotCatalog = com.mathworks.mlwidgets.graphics.PlotCatalog.getInstance();
    noise = randn(1, 1000);
    plotCatalog.setPlottedVars('noise');
    plotCatalog.show();
end

