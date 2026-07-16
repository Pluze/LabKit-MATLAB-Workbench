function code = labkitPublicHelpExampleCode(filepath)
%LABKITPUBLICHELPEXAMPLECODE Extract executable code from a help Example.
% Expected caller: documentation example execution tests. Input is one public
% MATLAB function file. Output is the unmodified code below an Example header,
% up to the next help section or implementation. Side effects: reads source.

    lines = readlines(filepath, "EmptyLineRule", "read");
    first = find(strtrim(lines) == "% Example:", 1);
    if isempty(first)
        code = "";
        return;
    end
    output = strings(0, 1);
    for k = first + 1:numel(lines)
        trimmed = strtrim(lines(k));
        if ~startsWith(trimmed, "%")
            break;
        end
        value = extractAfter(trimmed, 1);
        if startsWith(value, " ")
            value = extractAfter(value, 1);
        end
        if value == strip(value) && endsWith(value, ":")
            break;
        end
        if startsWith(lower(strip(value)), "see also ")
            break;
        end
        if startsWith(value, "  ")
            value = extractAfter(value, 2);
        end
        output(end + 1, 1) = value;
    end
    while ~isempty(output) && strlength(strip(output(end))) == 0
        output(end) = [];
    end
    code = strjoin(output, newline);
end
