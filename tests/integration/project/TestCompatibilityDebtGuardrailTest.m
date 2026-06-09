classdef TestCompatibilityDebtGuardrailTest < matlab.unittest.TestCase
    %TESTCOMPATIBILITYDEBTGUARDRAILTEST Keep test migration debt isolated.

    methods (Test, TestTags = {'Integration', 'Style'})
        function appUnitTestsDoNotReadAppSourceForBehavior(testCase)
            root = setupLabKitTestPath();
            files = collectMFiles(fullfile(root, 'tests', 'unit', 'apps'));
            patterns = [ ...
                "appEntryFile\s*\(", ...
                "readAppOwnedSource", ...
                "contains\s*\(\s*source", ...
                "fileread\s*\(\s*appFile", ...
                "sourceParts"];

            findings = filesMatchingAnyPattern(root, files, patterns);
            testCase.verifyTrue(isempty(findings), ...
                ['Unit app tests should verify package behavior directly, not read ' ...
                'app source strings as a behavior proxy. Findings: ' ...
                strjoin(cellstr(findings), ', ')]);
        end

        function dtaLegacyBridgeAssertionsStayIsolated(testCase)
            root = setupLabKitTestPath();
            files = [ ...
                collectMFiles(fullfile(root, 'tests', 'unit', 'labkit', 'dta')), ...
                collectMFiles(fullfile(root, 'tests', 'unit', 'apps', 'electrochem'))];
            allowed = string(fullfile(root, 'tests', 'unit', 'labkit', 'dta', ...
                'DtaCompatibilityBridgeTest.m'));
            files = setdiff(files, allowed);

            legacyField = "(item|chronoItem|eisItem|aligned)\.(t|Vf|Im|alignTime|tAligned|Freq|Time|Pt|Zreal|Zimag|negZimag|Zmod|Zphz|Idc|Vdc)\b";
            legacyText = "stable-compatible|mirror legacy|Legacy .* should mirror";
            findings = filesMatchingAnyPattern(root, files, [legacyField, legacyText]);
            testCase.verifyTrue(isempty(findings), ...
                ['DTA legacy bridge assertions belong in DtaCompatibilityBridgeTest. ' ...
                'Ordinary DTA/app tests should use canonical fields. Findings: ' ...
                strjoin(cellstr(findings), ', ')]);
        end

        function projectDebtGuardrailsUseCurrentGovernanceLabels(testCase)
            root = setupLabKitTestPath();
            files = collectMFiles(fullfile(root, 'tests', 'integration', 'project'));
            findings = filesMatchingAnyPattern(root, files, "Phase\s+\d+");
            testCase.verifyTrue(isempty(findings), ...
                ['Project guardrail messages should use current governance labels, ' ...
                'not historical roadmap phase names. Findings: ' ...
                strjoin(cellstr(findings), ', ')]);
        end

        function exactDebtInventoriesStayNamedAndNarrow(testCase)
            root = setupLabKitTestPath();
            files = collectMFiles(fullfile(root, 'tests', 'integration', 'project'));
            inventoryFunctions = strings(1, 0);
            for k = 1:numel(files)
                content = fileread(files(k));
                tokens = regexp(content, ...
                    '(?m)^function\s+\w+\s*=\s*(expected\w*Debt\w*)\s*\(', ...
                    'tokens');
                for i = 1:numel(tokens)
                    inventoryFunctions(end+1) = string(relativePath(root, files(k))) + ...
                        " -> " + string(tokens{i}{1});
                end
            end

            expected = [ ...
                "tests/integration/project/ProjectDebtGuardrailTest.m -> expectedAppPrivateDebtFiles", ...
                "tests/integration/project/ProjectDebtGuardrailTest.m -> expectedOversizedRunnerDebtFiles", ...
                "tests/integration/project/ProjectDocumentationGuardrailTest.m -> expectedPrivateContractDebtFiles"];
            unexpected = setdiff(inventoryFunctions, expected);
            testCase.verifyTrue(isempty(unexpected), ...
                ['New exact debt inventories need an explicit governance reason. ' ...
                'Prefer capability guardrails for package layout and test quality. Findings: ' ...
                strjoin(cellstr(unexpected), ', ')]);
        end

        function trackedEditorNoiseFilesAreForbidden(testCase)
            root = setupLabKitTestPath();
            files = gitTrackedFiles(root);
            noise = files(endsWith(files, ".DS_Store") | endsWith(files, ".asv") | ...
                endsWith(files, ".bak") | endsWith(files, "~"));
            testCase.verifyTrue(isempty(noise), ...
                ['Tracked editor or OS noise files are not allowed: ' ...
                strjoin(cellstr(noise), ', ')]);
        end
    end
end

function files = collectMFiles(folder)
    if ~isfolder(folder)
        files = strings(1, 0);
        return;
    end
    entries = dir(fullfile(folder, '**', '*.m'));
    files = strings(1, 0);
    for k = 1:numel(entries)
        if ~entries(k).isdir
            files(end+1) = string(fullfile(entries(k).folder, entries(k).name));
        end
    end
    files = unique(files);
end

function findings = filesMatchingAnyPattern(root, files, patterns)
    findings = strings(1, 0);
    for k = 1:numel(files)
        content = fileread(files(k));
        for i = 1:numel(patterns)
            if ~isempty(regexp(content, char(patterns(i)), 'once'))
                findings(end+1) = string(relativePath(root, files(k))) + ...
                    " -> " + patterns(i);
            end
        end
    end
    findings = unique(findings);
end

function files = gitTrackedFiles(root)
    command = sprintf('git -C "%s" ls-files', root);
    [status, output] = system(command);
    assert(status == 0, 'Could not list tracked files with git.');
    files = string(splitlines(strtrim(output))).';
    files = files(strlength(files) > 0);
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [root filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
