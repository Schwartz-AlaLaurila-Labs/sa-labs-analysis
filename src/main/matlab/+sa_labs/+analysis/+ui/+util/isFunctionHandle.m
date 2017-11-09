function tf = isFunctionHandle(value)
tf = ischar(value) && ~ isempty((strfind(value, '@')) == 1);
end