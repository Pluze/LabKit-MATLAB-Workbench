function tag = tagFromPath(filepath)
%TAGFROMPATH Derive a safe export tag from the final millimeter token.
tokens = regexp(filepath, '(\d+(?:\.\d+)?mm)', 'tokens');
if isempty(tokens)
    tag = "unknown_mm";
else
    tag = string(tokens{end}{1});
end
tag = regexprep(tag, '[^A-Za-z0-9_.-]', '_');
end
