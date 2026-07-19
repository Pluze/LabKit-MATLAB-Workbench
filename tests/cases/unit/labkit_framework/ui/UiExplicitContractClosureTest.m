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
            testCase.verifyError(@() labkit.app.layout.button( ...
                "run", "Run", @variableCommand), ...
                "labkit:app:contract:CallbackRoleMismatch");
        end

        function layoutSignalsCompileNamedPayloadClasses(testCase)
            setupLabKitTestPath();
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.dataTable("table", ...
                    OnCellEdited=@tableEdit, ...
                    OnCellSelectionChanged=@selectionEdit), ...
                labkit.app.layout.field("value", ...
                    OnValueChanged=@valueEdit)});
            app = labkit.app.Definition( ...
                Entrypoint="labkit_SignalProbe_app", ...
                AppId="probe.signals", Title="Signals", Family="Tests", ...
                AppVersion="1.0.0", Updated="2026-07-19", ...
                Requirements=[], Workbench=layout);
            plan = app.platformPlanForRuntime();
            tableSignal = plan.Nodes(2).Signals{1};
            selectionSignal = plan.Nodes(2).Signals{2};
            valueSignal = plan.Nodes(3).Signals{1};

            testCase.verifyEqual(tableSignal.PayloadClass, ...
                "labkit.app.event.TableCellEdit");
            testCase.verifyEqual(selectionSignal.PayloadClass, ...
                "labkit.app.event.TableCellSelection");
            testCase.verifyEqual(valueSignal.PayloadClass, "");
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

        function composesFeatureSnapshotsWithoutOpenPatchSchema(testCase)
            setupLabKitTestPath();
            controls = labkit.app.view.Snapshot().enabled("run", true);
            status = labkit.app.view.Snapshot().text("status", "Ready");

            combined = labkit.app.view.Snapshot() ...
                .include(controls) ...
                .include(status);

            testCase.verifyError(@() combined.include(controls), ...
                "labkit:app:contract:DuplicateId");
            testCase.verifyError(@() combined.include(struct()), ...
                "labkit:app:contract:InvalidValue");
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
