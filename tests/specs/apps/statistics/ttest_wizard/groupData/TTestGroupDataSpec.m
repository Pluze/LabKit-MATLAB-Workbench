classdef TTestGroupDataSpec < matlab.unittest.TestCase
    %TTESTGROUPDATASPEC Guard editable group-table transitions.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function batchRenamePreservesPairOrderAndReferenceIdentity(testCase)
            % Oracle: category labels change while exact samples/provenance stay put.
            groups = repmat(ttest_wizard.groupData.emptyGroup("A"), 3, 1);
            for k = 1:3
                groups(k).label = string(char('A' + k - 1));
                groups(k).values = [k; k + 3];
                groups(k).cellAddresses = ["R1"; "R2"];
            end
            parameters = ttest_wizard.initialData().parameters;
            parameters.referenceGroup = "B";
            parameters.excludedComparisonGroups = "C";
            [renamed, selected] = ttest_wizard.groupData.renameGroups( ...
                groups, parameters, ["B", "A", "Other"]);
            testCase.verifyEqual(string({renamed.label}), ["B", "A", "Other"]);
            testCase.verifyEqual(renamed(2).values, [2; 5]);
            testCase.verifyEqual(renamed(2).cellAddresses, ["R1"; "R2"]);
            testCase.verifyEqual(selected.referenceGroup, "A");
            testCase.verifyEqual(selected.excludedComparisonGroups, "Other");
            testCase.verifyError(@() ttest_wizard.groupData.renameGroups( ...
                groups, parameters, ["A", "a", "C"]), ...
                "ttest_wizard:groupData:InvalidNames");
        end

        function tableRowsBuildOrderedGroupsAndSelection(testCase)
            project = ttest_wizard.initialData();
            state = struct("project", project, ...
                "session", struct("selection", struct( ...
                    "analysisCells", zeros(0, 2))));
            edit = labkit.app.event.TableCellEdit( ...
                RowIndex=1, ColumnIndex=2, ...
                PreviousValue=[], NewValue=1, ...
                Data={"A", 1; "", 2; "B", 3});
            context = labkittest.createCallbackContext( ...
                struct("log", @(varargin) []));

            state = ttest_wizard.groupData.replaceFromTableEdit( ...
                state, edit, context);
            state = ttest_wizard.groupData.selectRows( ...
                state, labkit.app.event.TableCellSelection([2 2]), []);

            testCase.verifyEqual( ...
                string({state.project.inputs.groups.label}), ["A" "B"]);
            testCase.verifyEqual( ...
                state.project.inputs.groups(1).values, [1; 2]);
            testCase.verifyEqual( ...
                state.session.selection.analysisCells, [2 2]);
        end
    end
end
