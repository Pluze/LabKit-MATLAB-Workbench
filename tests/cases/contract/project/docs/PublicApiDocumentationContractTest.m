classdef PublicApiDocumentationContractTest < matlab.unittest.TestCase
    %PUBLICAPIDOCUMENTATIONCONTRACTTEST Verify source help and examples.

    methods (Test, TestTags = {'Integration', 'Style'})
        function rewrittenPublicApisKeepCompleteHelpContracts(testCase)
            root = setupLabKitTestPath();
            files = rewrittenModuleFiles(root);
            defects = strings(0, 1);
            for k = 1:numel(files)
                defects = [defects; ...
                    labkitPublicHelpContractDefects(root, files(k))];
            end

            testCase.verifyEmpty(defects, ...
                "Rewritten public APIs need complete, signature-aligned help contracts: " + ...
                strjoin(defects, "; "));
        end

        function rewrittenPublicApiExamplesExecuteInMatlab(testCase)
            root = setupLabKitTestPath();
            files = rewrittenModuleFiles(root);
            examples = strings(0, 1);
            failures = strings(0, 1);
            oldVisibility = get(groot, "DefaultFigureVisible");
            set(groot, "DefaultFigureVisible", "off");
            testCase.addTeardown(@() set(groot, ...
                "DefaultFigureVisible", oldVisibility));
            testCase.addTeardown(@() close(findall(groot, "Type", "figure")));
            for k = 1:numel(files)
                code = labkitPublicHelpExampleCode(files(k));
                if strlength(strip(code)) == 0
                    continue;
                end
                rel = replace(extractAfter(files(k), string(root) + filesep), ...
                    filesep, "/");
                examples(end + 1, 1) = rel;
                try
                    executeExample(code);
                catch ME
                    failures(end + 1, 1) = rel + " -> " + ...
                        string(ME.identifier) + ": " + string(ME.message);
                end
            end

            testCase.verifyGreaterThanOrEqual(numel(examples), 12, ...
                "Rewritten modules should retain a useful executable example set.");
            testCase.verifyEmpty(failures, ...
                "Every help section titled Example must execute: " + ...
                strjoin(failures, "; "));
        end
    end
end

function executeExample(code)
    evalc(char(code));
end

function files = rewrittenModuleFiles(root)
    moduleFolders = ["+biosignal", "+contract", "+dta", "+rhs", "+thermal"];
    files = strings(0, 1);
    for iModule = 1:numel(moduleFolders)
        entries = dir(fullfile(root, "+labkit", moduleFolders(iModule), "*.m"));
        for k = 1:numel(entries)
            files(end + 1, 1) = string(fullfile( ...
                entries(k).folder, entries(k).name));
        end
    end
end
