function defects = labkitPublicHelpContractDefects(root, filepath)
%LABKITPUBLICHELPCONTRACTDEFECTS Audit one public MATLAB help contract.
% Expected caller: documentation guardrails. Inputs are the repository root
% and one public function or class file. Output is a string column of missing sections,
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
    for k = 1:numel(required)
        content = helpSection(helpLines, required(k));
        if isempty(content) || all(strlength(strip(content)) == 0)
            defects(end + 1, 1) = rel + " -> missing or empty " + ...
                required(k) + " section";
        end
    end

    usage = helpSection(helpLines, "Usage");
    classApi = startsWith(strip(signature), "classdef");
    publicCall = any(contains(usage, symbol + "(")) || ...
        (classApi && any(contains(usage, symbol + ".")));
    if ~publicCall || any(contains(usage, "function "))
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
    errorBehavior = [ ...
        helpSection(helpLines, "Errors"); ...
        helpSection(helpLines, "Failure Behavior"); ...
        helpSection(helpLines, "Error Behavior")];
    if isempty(errorBehavior) || all(strlength(strip(errorBehavior)) == 0)
        defects(end + 1, 1) = rel + ...
            " -> missing explicit Errors or Failure Behavior section";
    end
    if ~any(startsWith(strip(helpLines), "See also "))
        defects(end + 1, 1) = rel + " -> missing See also related APIs";
    end

    optionFields = implementedOptionFields(filepath, signature);
    requiredOptions = [ ...
        helpSection(helpLines, "Required Name-Value Arguments"); ...
        helpSection(helpLines, "Required Options")];
    optionHelp = [ ...
        requiredOptions; ...
        helpSection(helpLines, "Optional Name-Value Arguments"); ...
        helpSection(helpLines, "Optional Options"); ...
        helpSection(helpLines, "Name-Value Arguments"); ...
        helpSection(helpLines, "Options")];
    if any(ismember(inputs, ["opts", "props"])) && ...
            (isempty(optionHelp) || all(strlength(strip(optionHelp)) == 0))
        defects(end + 1, 1) = rel + ...
            " -> missing or empty Options section";
    end
    for k = 1:numel(optionFields)
        field = optionFields(k);
        block = documentedFieldBlock(optionHelp, field);
        if isempty(block)
            defects(end + 1, 1) = rel + ...
                " -> undocumented option " + field;
            continue;
        end
        if isempty(documentedFieldBlock(requiredOptions, field)) && ...
                ~documentsDefault(block)
            defects(end + 1, 1) = rel + ...
                " -> option " + field + " has no documented default";
        end
        if ~describesLegalValues(block)
            defects(end + 1, 1) = rel + ...
                " -> option " + field + " does not describe legal values";
        end
    end
end

function tf = documentsDefault(block)
    text = lower(strjoin(block, " "));
    tf = any(contains(text, [ ...
        "default", "when omitted", "if omitted", "omit it", ...
        "when absent", "if absent"]));
end

function fields = implementedOptionFields(filepath, signature)
    source = implementationSource(filepath);
    mainSource = mainFunctionSource(filepath);
    variables = intersect(signatureInputs(signature), ["opts", "props"], ...
        "stable");
    if contains(signature, "varargin")
        tokens = regexp(source, ...
            '([A-Za-z][A-Za-z0-9_]*)\s*=\s*(?:optionStruct|parseOptions)\s*\(\s*varargin\s*\)', ...
            "tokens");
        for k = 1:numel(tokens)
            variables(end + 1, 1) = string(tokens{k}{1});
        end
    end
    variables = unique(variables, "stable");
    variables = variables(~ismissing(variables) & strlength(variables) > 0);
    fields = strings(0, 1);
    for variable = variables(:).'
        escaped = regexptranslate("escape", char(variable));
        helperExpression = [ ...
            '(?:optionValue|requiredOption|requireOption|fieldOrDefault)' ...
            '\s*\(\s*' escaped '\s*,\s*[''"]' ...
            '([A-Za-z][A-Za-z0-9_]*)[''"]'];
        tokens = regexp(source, helperExpression, "tokens");
        for k = 1:numel(tokens)
            fields(end + 1, 1) = string(tokens{k}{1});
        end
        memberExpression = [escaped ...
            '\.([A-Za-z][A-Za-z0-9_]*)(?![A-Za-z0-9_]|\s*=)'];
        tokens = regexp(mainSource, memberExpression, "tokens");
        for k = 1:numel(tokens)
            fields(end + 1, 1) = string(tokens{k}{1});
        end
    end
    fields = unique(fields, "stable");
end

function source = implementationSource(filepath)
    lines = readlines(filepath, "EmptyLineRule", "read");
    keep = ~startsWith(strtrim(lines), "%");
    source = char(strjoin(lines(keep), newline));
end

function source = mainFunctionSource(filepath)
    lines = readlines(filepath, "EmptyLineRule", "read");
    functionLines = find(startsWith(strtrim(lines), "function "));
    if numel(functionLines) > 1
        lines = lines(1:functionLines(2) - 1);
    end
    keep = ~startsWith(strtrim(lines), "%");
    source = char(strjoin(lines(keep), newline));
end

function block = documentedFieldBlock(lines, field)
    stripped = strip(lines);
    first = find(startsWith(stripped, field + " - "), 1);
    if isempty(first)
        block = strings(0, 1);
        return;
    end
    finish = numel(lines) + 1;
    for k = first + 1:numel(lines)
        if ~isempty(regexp(stripped(k), ...
                '^[A-Za-z][A-Za-z0-9_]*\s+-\s+\S', "once"))
            finish = k;
            break;
        end
    end
    block = lines(first:finish - 1);
end

function tf = describesLegalValues(block)
    text = lower(strjoin(block, " "));
    markers = ["allowed", "must", "logical", "positive", "nonnegative", ...
        "numeric", "text", "string", "character", "function handle", ...
        "empty", "cell", "table", "struct", "scalar", "array", ...
        "vector", "range", "one of", "supported", "canonical", ...
        "finite", "integer", "identifier", "path", "fraction", "seconds", ...
        "frames", "pixels", "degrees", "percent", "volts", ...
        "amperes", "unit", "version", "date", "result", "callback", ...
        "action id", "product name"];
    quotedValues = regexp(char(text), '"[^"]+"', "match");
    bracketedDomain = regexp(char(text), ...
        '\[[^\]\r\n]+(?:,|\s)[^\]\r\n]+\]', "once");
    tf = any(contains(text, markers)) || numel(quotedValues) >= 2 || ...
        ~isempty(bracketedDomain);
end

function [signature, helpLines] = publicFunctionHelp(filepath)
    lines = readlines(filepath, "EmptyLineRule", "read");
    functionStart = find(startsWith(strtrim(lines), "function "), 1);
    classStart = find(startsWith(strtrim(lines), "classdef"), 1);
    starts = [functionStart, classStart];
    starts = starts(~isnan(starts) & starts > 0);
    if isempty(starts)
        error("LabKit:Docs:MissingDeclaration", ...
            "Public API file has no function or class declaration: %s", ...
            filepath);
    end
    first = min(starts);
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
    if startsWith(strip(signature), "classdef")
        names = strings(0, 1);
        return;
    end
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
    if startsWith(strip(signature), "classdef")
        names = strings(0, 1);
        return;
    end
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
