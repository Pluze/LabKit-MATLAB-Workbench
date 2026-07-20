classdef AppDocumentationGuardrailTest < matlab.unittest.TestCase
    %APPDOCUMENTATIONGUARDRAILTEST Keep App manuals product-specific.

    methods (Test, TestTags = {'Integration', 'Style'})
        function appManualsDoNotRepeatFrameworkBoilerplate(testCase)
            root = setupLabKitTestPath();
            entries = dir(fullfile(root, "docs", "apps", "*", "*", ...
                "README.md"));
            forbidden = [ ...
                "## Framework Compatibility", ...
                "Every action and input-selection button provides hover help", ...
                "The semantic layout follows the", ...
                "remain framework-owned", ...
                "remain framework-private"];
            offenders = strings(1, 0);

            for k = 1:numel(entries)
                filepath = fullfile(entries(k).folder, entries(k).name);
                content = string(fileread(filepath));
                for iPhrase = 1:numel(forbidden)
                    if contains(content, forbidden(iPhrase))
                        offenders(end + 1) = relativePath(root, filepath) + ...
                            " -> " + forbidden(iPhrase);
                    end
                end
            end

            testCase.verifyEmpty(offenders, ...
                ["App manuals should explain App-specific user behavior and " ...
                "leave shared framework contracts in framework docs: " + ...
                strjoin(offenders, ", ")]);
        end
    end
end

function path = relativePath(root, filepath)
    path = replace(string(filepath), "\", "/");
    prefix = replace(string(root), "\", "/") + "/";
    path = extractAfter(path, prefix);
end
