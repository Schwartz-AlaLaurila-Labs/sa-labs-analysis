function uiFields = helpdocToFields(functionNames)

uiFields = [];

for name = each(functionNames)
    
    if isempty(name)
        continue;
    end
    
    [structure, flattenedStructure] = sa_labs.analysis.ui.util.helpDocToStructure(name);
    currentUIFields = uiextras.jide.PropertyGridField.GenerateFromStruct(flattenedStructure);
    for uiField = each(currentUIFields)
        nameWithPackage = strsplit(name, '.');
        functionName = nameWithPackage{end};
        uiField.DisplayName = appbox.humanize(uiField.Name);
        uiField.Category = appbox.humanize(functionName);
        uiField.Description = structure.(uiField.Name).description;
    end
    uiFields = [uiFields currentUIFields]; %#ok
end

if isempty(uiFields)
    uiFields = uiextras.jide.PropertyGridField.empty(0,1);
end

end
