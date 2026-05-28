function name = shortName(filepath)
%SHORTNAME Return file name plus extension from a path.

    [~, name, ext] = fileparts(filepath);
    name = [name ext];
end
