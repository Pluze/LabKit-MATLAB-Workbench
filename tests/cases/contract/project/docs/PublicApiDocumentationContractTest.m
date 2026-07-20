classdef PublicApiDocumentationContractTest < matlab.unittest.TestCase
    %PUBLICAPIDOCUMENTATIONCONTRACTTEST Verify source help and examples.

    methods (Test, TestTags = {'Integration', 'Style'})
        function discoveredPublicApisKeepCompleteHelpContracts(testCase)
            root = setupLabKitTestPath();
            files = publicApiContractFiles(root);
            defects = strings(0, 1);
            for k = 1:numel(files)
                defects = [defects; ...
                    labkitPublicHelpContractDefects(root, files(k))];
            end

            testCase.verifyEmpty(defects, ...
                "Discovered public APIs need complete, signature-aligned help contracts: " + ...
                strjoin(defects, "; "));
        end

        function discoveredPublicApiExamplesExecuteInMatlab(testCase)
            root = setupLabKitTestPath();
            files = publicApiContractFiles(root);
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
                "Public modules should retain a useful executable example set.");
            testCase.verifyEmpty(failures, ...
                "Every help section titled Example must execute: " + ...
                strjoin(failures, "; "));
        end

        function exampleExtractionStopsAtSeeAlso(testCase)
            folder = matlab.unittest.fixtures.TemporaryFolderFixture;
            testCase.applyFixture(folder);
            filepath = fullfile(folder.Folder, "documentedFunction.m");
            source = strjoin([ ...
                "function value = documentedFunction()"
                "%DOCUMENTEDFUNCTION Demonstrate a help example."
                "%"
                "% Example:"
                "%   value = 42;"
                "%"
                "% See also anotherFunction"
                "value = 42;"
                "end"], newline);
            fid = fopen(filepath, "w");
            cleaner = onCleanup(@() fclose(fid));
            fwrite(fid, source);
            clear cleaner

            code = labkitPublicHelpExampleCode(filepath);
            testCase.verifyEqual(strip(code), "value = 42;");
        end

        function generatedApiCodeBlocksExcludeSeeAlsoText(testCase)
            root = setupLabKitTestPath();
            files = dir(fullfile(root, "site", "reference", "api", ...
                "**", "*.html"));
            findings = strings(0, 1);
            pattern = '<pre><code[^>]*>[^<]*See also[^<]*</code></pre>';
            for k = 1:numel(files)
                filepath = fullfile(files(k).folder, files(k).name);
                if ~isempty(regexp(fileread(filepath), pattern, "once"))
                    findings(end + 1, 1) = string(filepath);
                end
            end
            testCase.verifyEmpty(findings, ...
                "Generated MATLAB code blocks must not contain See also text.");
        end

        function generatedNameValueSectionsUseDefinitionLists(testCase)
            root = setupLabKitTestPath();
            filepath = fullfile(root, "site", "reference", "api", ...
                "labkit", "app", "Definition.html");
            html = string(fileread(filepath));
            for id = ["required-name-value-arguments", ...
                    "optional-name-value-arguments"]
                sectionStart = '<section class="api-section"><h2 id="' + ...
                    id + '">';
                section = extractAfter(html, sectionStart);
                section = extractBefore(section, "</section>");
                testCase.verifyTrue(contains(section, ...
                    '<dl class="argument-list">'), ...
                    "Generated Name-Value sections must be scannable definition lists.");
            end
        end

        function generatedMethodSectionsUseDefinitionLists(testCase)
            root = setupLabKitTestPath();
            filepath = fullfile(root, "site", "reference", "api", ...
                "labkit", "app", "Definition.html");
            html = string(fileread(filepath));
            section = extractAfter(html, ...
                '<section class="api-section"><h2 id="definition-methods">');
            section = extractBefore(section, "</section>");
            testCase.verifyTrue(contains(section, ...
                '<dl class="argument-list">'), ...
                "Generated method sections must be scannable definition lists.");
        end

        function explicitSeeAlsoCreatesCrossComponentLinks(testCase)
            root = setupLabKitTestPath();
            filepath = fullfile(root, "site", "reference", "api", ...
                "cic", "analysisRun", "computeCIC.html");
            html = string(fileread(filepath));
            testCase.verifyTrue(contains(html, ...
                '../../labkit/dta/detectPulses.html'), ...
                "Explicit See also entries must link across components.");
            testCase.verifyTrue(contains(html, ...
                '../../vt_resistance/analysisRun/computeResistance.html'), ...
                "Explicit See also entries must link across app packages.");
        end

        function helpContractDetectsEveryOptionDefaultErrorAndRelatedApi(testCase)
            folder = matlab.unittest.fixtures.TemporaryFolderFixture;
            testCase.applyFixture(folder);
            packageFolder = fullfile(folder.Folder, "+labkit", "+probe");
            mkdir(packageFolder);
            filepath = fullfile(packageFolder, "incomplete.m");
            source = strjoin([ ...
                "function value = incomplete(opts)"
                "%INCOMPLETE Deliberately incomplete public help."
                "%"
                "% Usage:"
                "%   value = labkit.probe.incomplete(opts)"
                "%"
                "% Description:"
                "%   Probe the contract checker."
                "%"
                "% Inputs:"
                "%   opts - Scalar option struct."
                "%"
                "% Options:"
                "%   first - Positive numeric scalar."
                "%   third - Controls behavior. Default: 3."
                "%"
                "% Outputs:"
                "%   value - Selected value."
                "value = optionValue(opts, 'first', 1) + " + ...
                    "optionValue(opts, 'second', 2) + " + ...
                    "optionValue(opts, 'third', 3);"
                "end"], newline);
            fid = fopen(filepath, "w");
            cleaner = onCleanup(@() fclose(fid));
            fwrite(fid, source);
            clear cleaner

            defects = labkitPublicHelpContractDefects( ...
                folder.Folder, filepath);
            combined = strjoin(defects, newline);
            testCase.verifyTrue(contains(combined, ...
                "undocumented option second"));
            testCase.verifyTrue(contains(combined, ...
                "option first has no documented default"));
            testCase.verifyTrue(contains(combined, ...
                "option third does not describe legal values"));
            testCase.verifyTrue(contains(combined, ...
                "missing explicit Errors or Failure Behavior"));
            testCase.verifyTrue(contains(combined, ...
                "missing See also related APIs"));
        end
    end
end

function executeExample(code)
    evalc(char(code));
end

function files = publicApiContractFiles(root)
    entries = dir(fullfile(root, "+labkit", "**", "*.m"));
    files = strings(0, 1);
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if ~contains(filepath, filesep + "private" + filesep) && ...
                ~contains(filepath, filesep + "@") && ...
                ~isHiddenClassFile(filepath)
            files(end + 1, 1) = filepath;
        end
    end
    files = sort(files);
    files = [files; discoverLabKitAppApiFiles(root)];
end

function tf = isHiddenClassFile(filepath)
    lines = strip(readlines(filepath, "EmptyLineRule", "skip"));
    lines = lines(~startsWith(lines, "%"));
    tf = ~isempty(lines) && startsWith(lines(1), "classdef") && ...
        contains(lines(1), "Hidden");
end
