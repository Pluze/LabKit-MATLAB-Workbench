function defects = labkitPublicHelpContractDefects(root, filepath)
%LABKITPUBLICHELPCONTRACTDEFECTS Audit one public MATLAB help contract.
% Expected caller: documentation guardrails. Inputs are the repository root
% and one public function file. Output is a string column of missing sections,
% signature names, or option-field explanations. Side effects: reads source.

    [signature, helpLines] = publicFunctionHelp(filepath);
    rel = relativePath(root, filepath);
    symbol = publicApiSymbol(root, filepath);
    defects = strings(0, 1);
    required = ["Usage", "Description", "Outputs"];
    inputs = signatureInputs(signature);
    outputs = signatureOutputs(signature);
    if ~isempty(inputs)
        required(end + 1) = "Inputs";
    end
    if any(inputs == "opts")
        required(end + 1) = "Options";
    end
    for k = 1:numel(required)
        content = helpSection(helpLines, required(k));
        if isempty(content) || all(strlength(strip(content)) == 0)
            defects(end + 1, 1) = rel + " -> missing or empty " + ...
                required(k) + " section";
        end
    end

    usage = helpSection(helpLines, "Usage");
    if ~any(contains(usage, symbol + "(")) || any(contains(usage, "function "))
        defects(end + 1, 1) = rel + ...
            " -> Usage must show a public call, not a source declaration";
    end
    inputLines = strip(helpSection(helpLines, "Inputs"));
    for k = 1:numel(inputs)
        if ~any(startsWith(inputLines, inputs(k) + " - "))
            defects(end + 1, 1) = rel + " -> undocumented input " + inputs(k);
        end
    end
    outputLines = strip(helpSection(helpLines, "Outputs"));
    for k = 1:numel(outputs)
        if ~any(startsWith(outputLines, outputs(k) + " - "))
            defects(end + 1, 1) = rel + " -> undocumented output " + outputs(k);
        end
    end
    if any(inputs == "opts")
        options = helpSection(helpLines, "Options");
        namedField = regexp(cellstr(options), ...
            '^\s{2,}[A-Za-z][A-Za-z0-9_.]*\s+-\s+\S', "once");
        if ~any(~cellfun("isempty", namedField))
            defects(end + 1, 1) = rel + ...
                " -> Options must name fields and explain their values";
        end
    end
end

function [signature, helpLines] = publicFunctionHelp(filepath)
    lines = readlines(filepath, "EmptyLineRule", "read");
    first = find(startsWith(strtrim(lines), "function "), 1);
    finish = first;
    while finish < numel(lines) && endsWith(strip(lines(finish)), "...")
        finish = finish + 1;
    end
    signature = strjoin(strip(lines(first:finish)), " ");
    helpLines = strings(0, 1);
    for k = finish + 1:numel(lines)
        trimmed = strtrim(lines(k));
        if ~startsWith(trimmed, "%")
            break;
        end
        value = extractAfter(trimmed, 1);
        if startsWith(value, " ")
            value = extractAfter(value, 1);
        end
        helpLines(end + 1, 1) = value;
    end
end

function content = helpSection(lines, name)
    first = find(lines == name + ":", 1);
    if isempty(first)
        content = strings(0, 1);
        return;
    end
    finish = numel(lines) + 1;
    for k = first + 1:numel(lines)
        if lines(k) == strip(lines(k)) && endsWith(lines(k), ":")
            finish = k;
            break;
        end
    end
    content = lines(first + 1:finish - 1);
end

function names = signatureInputs(signature)
    token = regexp(char(signature), '\(([^)]*)\)', "tokens", "once");
    if isempty(token) || strlength(strip(string(token{1}))) == 0
        names = strings(0, 1);
        return;
    end
    names = strip(split(string(token{1}), ","));
    names = regexprep(names, '\s*=.*$', '');
    names = names(~ismember(names, ["varargin", "~"]));
end

function names = signatureOutputs(signature)
    left = extractBefore(string(signature), "=");
    if left == signature
        names = strings(0, 1);
        return;
    end
    left = strip(extractAfter(left, "function"));
    left = erase(left, ["[", "]"]);
    names = strip(split(left, ","));
    names = names(strlength(names) > 0 & names ~= "varargout");
end

function symbol = publicApiSymbol(root, filepath)
    parts = split(relativePath(root, filepath), "/");
    packageParts = erase(parts(startsWith(parts, "+")), "+");
    functionName = erase(parts(end), ".m");
    symbol = strjoin([packageParts; functionName], ".");
end

function rel = relativePath(root, filepath)
    rel = replace(extractAfter(string(filepath), string(root) + filesep), ...
        filesep, "/");
end
