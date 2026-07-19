classdef UiExplicitContractClosureTest < matlab.unittest.TestCase
    methods (Test)
        function exposesOnlyAcceptedLayoutAndPresentationVocabulary(testCase)
            setupLabKitTestPath();
            required = ["button", "field", "rangeField", "slider", ...
                "fileList", "plotArea", "dataTable", "logPanel", ...
                "statusPanel", "group", "section", "tab", "workspace", ...
                "workbench"];
            for name = required
                testCase.verifyNotEmpty(which( ...
                    "labkit.app.layout." + name));
            end

            presentationMethods = string(methods( ...
                "labkit.app.view.Snapshot"));
            testCase.verifyEmpty(intersect( ...
                ["set", "patch", "property"], presentationMethods));
            testCase.verifyTrue(ismember( ...
                "workspacePage", presentationMethods));
        end

        function rejectsAliasesStringsAndUntypedPayloads(testCase)
            setupLabKitTestPath();
            testCase.verifyError(@() labkit.app.layout.field( ...
                "value", "kind", "text"), ...
                "labkit:app:contract:UnknownArgument");
            testCase.verifyError(@() labkit.app.layout.button( ...
                "run", "Run", "run"), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() labkit.app.view.Snapshot().listSelection( ...
                "table", [1 2]), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() labkit.app.StateHandler( ...
                "run", @variableCommand), ...
                "labkit:app:contract:CallbackRoleMismatch");
        end

        function commandRolesDeclareNamedPayloadClasses(testCase)
            setupLabKitTestPath();
            tableCommand = labkit.app.StateHandler( ...
                "edit", @tableEdit, Event="tableCellEdit");
            selectionCommand = labkit.app.StateHandler( ...
                "select", @selectionEdit, Event="listSelection");
            valueCommand = labkit.app.StateHandler( ...
                "value", @valueEdit, Event="valueChange");

            testCase.verifyEqual(tableCommand.PayloadClass, ...
                "labkit.app.event.TableCellEdit");
            testCase.verifyEqual(selectionCommand.PayloadClass, ...
                "labkit.app.event.ListSelection");
            testCase.verifyEqual(valueCommand.PayloadClass, "");
        end

        function contractDiagnosticsAreDeterministicAndNamed(testCase)
            setupLabKitTestPath();
            first = capture(@() labkit.app.result.File( ...
                "bad", "primary", "../escape.csv"));
            second = capture(@() labkit.app.result.File( ...
                "bad", "primary", "../escape.csv"));

            testCase.verifyEqual(string(first.identifier), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyEqual(first.identifier, second.identifier);
            testCase.verifyEqual(first.message, second.message);
            testCase.verifySubstring(first.message, ...
                "File relativePath");
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
