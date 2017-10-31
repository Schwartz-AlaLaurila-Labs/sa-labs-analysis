function uiFields = helpdocToFields(functionNames)

uiFields = [];

for name = each(functionNames)
    
    if isempty(name)
        continue;
    end
    
    [doc, ~] = help(which(name));
    
    if ~ isempty(doc)
        parsedDoc = strsplit(doc, '---');
        try
            prameterYaml = parsedDoc{1};
            structure = yaml.ReadYaml(prameterYaml, 0, 0, 1);
            currentUIFields = uiextras.jide.PropertyGridField.GenerateFromStruct(flattenStructure(structure));
        catch exception
            disp(getReport(exception, 'extended', 'hyperlinks', 'on'));
            continue;
        end
    end
    
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

function s = flattenStructure(structure)
structFields = setdiff(fields(structure), 'description');
s = struct();
for field = each(structFields)
    value = structure.(field).default;
    s.(field) = value;
end
end

