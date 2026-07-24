function result = explainChanged(varargin)
%EXPLAINCHANGED Explain changed-path ownership without running tests.
%   RESULT = labkittest.explainChanged prints each changed path's structural
%   classification, owner evidence, selected identities, and explicit manual
%   boundary. It accepts ChangedPaths, RepositoryRoot, and SpecsRoot options
%   supported by labkittest.plan. Unknown paths fail planning with an actionable
%   ownership error; ignored paths state which non-test check owns them.

    result = labkittest.plan("Profile", "changed", varargin{:});
    if isempty(result.Classifications)
        fprintf("LabKit changed validation: no changed paths were found.\n");
        return;
    end
    fprintf("LabKit changed validation plan (%s)\n", result.Scope);
    for classification = result.Classifications
        fprintf("%s\n", classification.Path);
        fprintf("  classification: %s", classification.Kind);
        if strlength(classification.Role) > 0
            fprintf(" (%s)", classification.Role);
        end
        fprintf("\n  reason: %s\n", classification.Reason);
        if classification.Kind == "ignored"
            continue;
        end
        pathPlan = labkittest.plan("File", classification.Path, varargin{:});
        for descriptor = pathPlan.Descriptors
            fprintf("  evidence: %s / %s / %s\n", descriptor.Owner, ...
                descriptor.Contracts, descriptor.Environment);
        end
        for check = pathPlan.ManualChecks
            fprintf("  manual boundary: %s\n", check);
        end
    end
end
