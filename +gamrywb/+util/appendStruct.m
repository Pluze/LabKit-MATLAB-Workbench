function out = appendStruct(S, item)
%APPENDSTRUCT Append one struct item to a possibly empty struct array.

    if isempty(S)
        out = item;
    else
        out = [S, item];
    end
end
