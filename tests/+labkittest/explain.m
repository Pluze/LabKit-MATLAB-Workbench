function result = explain(target, varargin)
%EXPLAIN Print and return the evidence closure for a LabKit source target.
%   RESULT = labkittest.explain(TARGET) treats TARGET as a repository-relative
%   source file and prints the selected test identities, their owner,
%   contract, execution environment, and whether conservative fallback was
%   needed. Additional name-value arguments are passed to labkittest.plan.
%
%   The function is diagnostic only: it does not execute tests or write
%   artifacts. Use labkittest.run to execute a compiled plan.

    result = labkittest.plan("File", target, varargin{:});
    fprintf("LabKit test plan: %d exact test(s), fallback=%d\n", ...
        numel(result.Descriptors), result.Fallback);
    for k = 1:numel(result.Descriptors)
        descriptor = result.Descriptors(k);
        fprintf("  %s owner=%s contract=%s env=%s\n", ...
            descriptor.Id, descriptor.Owner, descriptor.Contracts, ...
            descriptor.Environment);
    end
    for k = 1:numel(result.Reasons)
        fprintf("  reason: %s\n", result.Reasons(k));
    end
end
