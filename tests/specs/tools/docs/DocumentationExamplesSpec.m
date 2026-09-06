classdef DocumentationExamplesSpec < matlab.unittest.TestCase
    % Regression: rendered pages cannot hide broken executable examples.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function markedRuntimeFailureRejectsDocumentation(testCase)
            source = testCase.documentationCopy();
            testCase.appendExample(source, [ ...
                "<!-- labkit-runnable-example -->", "```matlab", ...
                "exampleLocalValue = 7;", "```", "", ...
                "<!-- labkit-runnable-example -->", "```matlab", ...
                "assert(~exist('exampleLocalValue', 'var'));", ...
                "error('example:ExpectedFailure', 'Synthetic example failed.');", "```"]);
            try
                checkLabKitDocs(source);
                testCase.assertFail("Broken example was accepted.");
            catch exception
                testCase.verifyEqual(string(exception.identifier), "LabKit:Docs:ExampleFailed");
                testCase.assertNumElements(exception.cause, 1);
                testCase.verifyEqual(string(exception.cause{1}.identifier), "example:ExpectedFailure");
            end
        end

        function markerWithoutMatlabFenceIsRejected(testCase)
            source = testCase.documentationCopy();
            testCase.appendExample(source, [ ...
                "<!-- labkit-runnable-example -->", "```text", "not MATLAB", "```"]);
            testCase.verifyError(@() checkLabKitDocs(source), ...
                "LabKit:Docs:InvalidRunnableExample");
        end
    end

    methods (Access = private)
        function source = documentationCopy(testCase)
            repository = fileparts(fileparts(fileparts(fileparts(fileparts( ...
                mfilename("fullpath"))))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repository, "tools", "docs")));
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            source = fullfile(folder.Folder, "docs");
            copyfile(fullfile(repository, "docs"), source);
        end

        function appendExample(~, source, lines)
            fid = fopen(fullfile(source, "README.md"), "a");
            cleanup = onCleanup(@() fclose(fid));
            fprintf(fid, "\n%s\n", strjoin(lines, newline));
            clear cleanup
        end
    end
end
