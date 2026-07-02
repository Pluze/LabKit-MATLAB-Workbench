function suite = labkitSelectTestShard(suite, opts)
%LABKITSELECTTESTSHARD Deterministically select one test shard.
% Expected caller: runLabKitTests after suite discovery and filtering.
% Inputs:
%   suite MATLAB unittest suite array
%   opts  runner options with ShardCount and zero-based ShardIndex
% Output:
%   suite selected suite shard
% Side effects: none.

    if opts.ShardCount <= 1 || isempty(suite)
        return;
    end

    names = string({suite.Name});
    [~, order] = sort(lower(names));
    suite = suite(order);
    indexes = 0:(numel(suite) - 1);
    suite = suite(mod(indexes, opts.ShardCount) == opts.ShardIndex);
end
