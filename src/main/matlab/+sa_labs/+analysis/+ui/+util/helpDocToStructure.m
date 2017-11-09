function [structure, flattenedStructure] = helpDocToStructure(name)

structure = struct();
flattenedStructure = struct();
[doc, ~] = help(which(name));

if ~ isempty(doc)
    parsedDoc = strsplit(doc, '---');
    try
        prameterYaml = parsedDoc{1};
        structure = yaml.ReadYaml(prameterYaml, 0, 0, 1);
        flattenedStructure = flattenStructure(structure);
    catch exception
        disp(getReport(exception, 'extended', 'hyperlinks', 'on'));
    end
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