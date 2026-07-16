classdef LibraryDocumentationGuardrailTest < matlab.unittest.TestCase
    %LIBRARYDOCUMENTATIONGUARDRAILTEST Detailed generated library reference checks.

    methods (Test, TestTags = {'Integration', 'Style'})
        function generatedThermalReferenceExplainsPublicCallContracts(testCase)
            root = setupLabKitTestPath();
            apiRoot = fullfile(root, "site", "reference", "api", ...
                "labkit", "thermal");
            functions = ["fileDialogFilter", "inspectFile", ...
                "isSupportedPath", "rawToTemperatureC", "readFile", ...
                "readFiles", "renderImage", "supportedExtensions", "version"];
            for k = 1:numel(functions)
                page = string(fileread(fullfile(apiRoot, functions(k) + ".html")));
                testCase.verifyTrue(contains(page, ...
                    "labkit.thermal." + functions(k) + "("), ...
                    functions(k) + " should show its public MATLAB call syntax.");
                testCase.verifyFalse(contains(page, ...
                    "function " + functions(k)), ...
                    functions(k) + " should not present its source declaration as call syntax.");
                testCase.verifyTrue(contains(page, ...
                    '<h2 id="description">Description</h2>'), ...
                    functions(k) + " should explain its behavior.");
                testCase.verifyTrue(contains(page, '<h2 id="outputs">Outputs</h2>'), ...
                    functions(k) + " should describe returned values.");
                testCase.verifyFalse(contains(page, "App-facing contract"));
            end

            rawPage = string(fileread(fullfile(apiRoot, ...
                "rawToTemperatureC.html")));
            testCase.verifyTrue(contains(rawPage, ...
                '<h2 id="calibration-fields">Calibration Fields</h2>'));
            testCase.verifyTrue(contains(rawPage, "RelativeHumidity"));
            testCase.verifyTrue(contains(rawPage, "planck-basic"));

            renderPage = string(fileread(fullfile(apiRoot, "renderImage.html")));
            testCase.verifyTrue(contains(renderPage, '<h2 id="options">Options</h2>'));
            testCase.verifyTrue(contains(renderPage, ...
                '&quot;turbo&quot;, &quot;parula&quot;, &quot;hot&quot;, &quot;gray&quot;, and &quot;iron&quot;'));
        end

        function generatedDtaReferenceExplainsFilesAndDataSchemas(testCase)
            root = setupLabKitTestPath();
            apiRoot = fullfile(root, "site", "reference", "api", ...
                "labkit", "dta");
            functions = ["detectPulses", "detectType", "findFiles", ...
                "getColumn", "getCurveXY", "getMainCurve", "getZCurve", ...
                "loadFile", "loadFiles", "loadFolder", "version"];
            for k = 1:numel(functions)
                page = string(fileread(fullfile(apiRoot, functions(k) + ".html")));
                testCase.verifyTrue(contains(page, ...
                    "labkit.dta." + functions(k) + "("), ...
                    functions(k) + " should show its public MATLAB call syntax.");
                testCase.verifyTrue(contains(page, ...
                    '<h2 id="description">Description</h2>'), ...
                    functions(k) + " should explain its behavior.");
                testCase.verifyTrue(contains(page, '<h2 id="outputs">Outputs</h2>'), ...
                    functions(k) + " should describe returned values.");
            end

            pulsePage = string(fileread(fullfile(apiRoot, "detectPulses.html")));
            testCase.verifyTrue(contains(pulsePage, ...
                '<h2 id="mode-values">Mode Values</h2>'));
            testCase.verifyTrue(contains(pulsePage, "current_only"));
            testCase.verifyTrue(contains(pulsePage, "25 percent"));

            loadPage = string(fileread(fullfile(apiRoot, "loadFile.html")));
            testCase.verifyTrue(contains(loadPage, ...
                '<h2 id="output-fields">Output Fields</h2>'));
            testCase.verifyTrue(contains(loadPage, "scanRate_V_per_s"));
            testCase.verifyTrue(contains(loadPage, "status.ok=false"));
        end

        function generatedRhsReferenceExplainsLazyReadsAndUnits(testCase)
            root = setupLabKitTestPath();
            apiRoot = fullfile(root, "site", "reference", "api", ...
                "labkit", "rhs");
            functions = ["findFiles", "indexFile", "inspectFile", ...
                "readWindow", "version"];
            for k = 1:numel(functions)
                page = string(fileread(fullfile(apiRoot, functions(k) + ".html")));
                testCase.verifyTrue(contains(page, ...
                    "labkit.rhs." + functions(k) + "("), ...
                    functions(k) + " should show its public MATLAB call syntax.");
                testCase.verifyTrue(contains(page, ...
                    '<h2 id="description">Description</h2>'));
                testCase.verifyTrue(contains(page, '<h2 id="outputs">Outputs</h2>'));
            end

            windowPage = string(fileread(fullfile(apiRoot, "readWindow.html")));
            testCase.verifyTrue(contains(windowPage, '<h2 id="options">Options</h2>'));
            testCase.verifyTrue(contains(lower(windowPage), "samples-by-channels"));
            testCase.verifyTrue(contains(windowPage, "microvolts"));
            testCase.verifyTrue(contains(windowPage, "microamps"));
            testCase.verifyTrue(contains(windowPage, ...
                "Both calculated endpoint samples are included"));

            inspectPage = string(fileread(fullfile(apiRoot, "inspectFile.html")));
            testCase.verifyTrue(contains(inspectPage, ...
                '<h2 id="output-fields">Output Fields</h2>'));
            testCase.verifyTrue(contains(inspectPage, "exactBlocks"));
        end
    end
end
