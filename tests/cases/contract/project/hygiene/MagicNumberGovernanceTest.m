classdef MagicNumberGovernanceTest < matlab.unittest.TestCase
    %MAGICNUMBERGOVERNANCETEST Guard explanations for calculation constants.

    methods (Test, TestTags = {'Integration', 'Style'})
        function productionCalculationConstantsAreExplained(testCase)
            root = setupLabKitTestPath();
            files = calculationSourceFiles(root);
            findings = unexplainedConstantFindings(root, files);
            testCase.verifyEmpty(findings, ...
                ['Nontrivial calculation constants require a nearby ' ...
                '"% Constant:" comment naming their source or purpose. ' ...
                'Findings: ' strjoin(cellstr(findings), ', ')]);
        end

        function scannerRejectsUnexplainedHighPrecisionConstants(testCase)
            lines = [
                "gain = 0.123456 .* signal;"
                "% Constant: published device conversion gain."
                "converted = 0.654321 .* signal;"
            ];
            findings = unexplainedLines("example.m", lines);
            testCase.verifyEqual(findings, "example.m:1");
        end
    end
end

function files = calculationSourceFiles(root)
    [status, output] = system(sprintf([ ...
        'git -C "%s" ls-files --cached --others --exclude-standard ' ...
        '+labkit apps'], root));
    assert(status == 0, 'Could not list tracked calculation source files.');
    files = string(splitlines(strtrim(output)));
    files = files(endsWith(files, ".m"));
    slashFiles = replace(files, "\", "/");
    productionSource = startsWith(slashFiles, "+labkit/") | ...
        startsWith(slashFiles, "apps/");
    excludedSource = contains(slashFiles, "/+debug/") | ...
        endsWith(slashFiles, "/buildWorkbenchLayout.m") | ...
        endsWith(slashFiles, "/version.m") | ...
        endsWith(slashFiles, "/requirements.m");
    files = files(productionSource & ~excludedSource);
end

function findings = unexplainedConstantFindings(root, files)
    findings = strings(1, 0);
    for index = 1:numel(files)
        filepath = fullfile(root, char(files(index)));
        findings = [findings unexplainedLines(files(index), readlines(filepath))];
    end
end

function findings = unexplainedLines(file, lines)
    findings = strings(1, 0);
    pattern = ['(?<![A-Za-z0-9_])(\d+\.\d{4,}|' ...
        '\d+(?:\.\d+)?[eE][+-]?\d+|273\.15)(?![A-Za-z0-9_])'];
    for lineIndex = 1:numel(lines)
        line = string(lines(lineIndex));
        if startsWith(strtrim(line), "%") || ...
                isExplicitUiColor(file, line) || ...
                isempty(regexp(char(line), pattern, 'once'))
            continue;
        end
        firstContextLine = max(1, lineIndex - 8);
        context = lines(firstContextLine:lineIndex);
        if ~any(contains(context, "% Constant:"))
            findings(end + 1) = replace(string(file), "\", "/") + ...
                ":" + string(lineIndex);
        end
    end
end

function tf = isExplicitUiColor(file, line)
    normalizedFile = replace(string(file), "\", "/");
    tf = contains(normalizedFile, "/+userInterface/") && ...
        (contains(line, "Color") || contains(line, "color"));
end
