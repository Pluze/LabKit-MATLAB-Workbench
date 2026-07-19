classdef UiExplicitContractClosureTest < matlab.unittest.TestCase
    methods (Test)
        function exposesOnlyAcceptedLayoutAndPresentationVocabulary(testCase)
            setupLabKitTestPath();
            layoutMethods = string(methods("labkit.ui.Layout"));
            required = ["action", "field", "rangeField", "panner", ...
                "filePanel", "previewArea", "resultTable", "logPanel", ...
                "statusPanel", "group", "section", "tab", "workspace", ...
                "workbench", "page", "initialPage"];
            testCase.verifyEmpty(setdiff(required, layoutMethods));
            testCase.verifyEmpty(intersect( ...
                ["root", "table", "preview", "workspaceTab"], ...
                layoutMethods));

            presentationMethods = string(methods( ...
                "labkit.ui.Presentation"));
            testCase.verifyEmpty(intersect( ...
                ["set", "patch", "property"], presentationMethods));
            testCase.verifyTrue(ismember( ...
                "workspacePage", presentationMethods));
        end

        function rejectsAliasesStringsAndUntypedPayloads(testCase)
            setupLabKitTestPath();
            testCase.verifyError(@() labkit.ui.Layout.field( ...
                "value", "kind", "text"), ...
                "labkit:ui:contract:UnknownArgument");
            testCase.verifyError(@() labkit.ui.Layout.action( ...
                "run", "Run", "run"), ...
                "labkit:ui:contract:InvalidValue");
            testCase.verifyError(@() labkit.ui.Presentation().selection( ...
                "table", [1 2]), ...
                "labkit:ui:contract:InvalidValue");
            testCase.verifyError(@() labkit.ui.Command( ...
                "run", @variableCommand), ...
                "labkit:ui:contract:CallbackRoleMismatch");
        end

        function commandRolesDeclareNamedPayloadClasses(testCase)
            setupLabKitTestPath();
            tableCommand = labkit.ui.Command( ...
                "edit", @tableEdit, Role="tableEdit");
            selectionCommand = labkit.ui.Command( ...
                "select", @selectionEdit, Role="selection");
            valueCommand = labkit.ui.Command( ...
                "value", @valueEdit, Role="value");

            testCase.verifyEqual(tableCommand.PayloadClass, ...
                "labkit.ui.TableEdit");
            testCase.verifyEqual(selectionCommand.PayloadClass, ...
                "labkit.ui.Selection");
            testCase.verifyEqual(valueCommand.PayloadClass, "");
        end

        function contractDiagnosticsAreDeterministicAndNamed(testCase)
            setupLabKitTestPath();
            first = capture(@() labkit.ui.ResultOutput( ...
                "bad", "primary", "../escape.csv"));
            second = capture(@() labkit.ui.ResultOutput( ...
                "bad", "primary", "../escape.csv"));

            testCase.verifyEqual(string(first.identifier), ...
                "labkit:ui:contract:InvalidValue");
            testCase.verifyEqual(first.identifier, second.identifier);
            testCase.verifyEqual(first.message, second.message);
            testCase.verifySubstring(first.message, ...
                "ResultOutput relativePath");
        end
    end
end

function exception = capture(callback)
    try
        callback();
        error("test:ExpectedFailure", "Callback did not fail.");
    catch exception
    end
end

function state = variableCommand(varargin)
    state = varargin{1};
end

function state = tableEdit(state, ~, ~)
end

function state = selectionEdit(state, ~, ~)
end

function state = valueEdit(state, ~, ~)
end
