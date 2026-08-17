function state = requireMark10Sampler(sampler)
%REQUIREMARK10SAMPLER Validate the opaque background sampler token.
% Called by public sampler lifecycle operations. SAMPLER must be the scalar
% structure returned by startSampling and must retain its handle-semantic
% state map with connection and stop state. Returns that state map without
% changing serial callbacks, timers, or samples.
if ~isstruct(sampler) || ~isscalar(sampler) || ...
        ~isfield(sampler, "Type") || ...
        string(sampler.Type) ~= "labkit.mark10.sampler" || ...
        ~isfield(sampler, "State") || ...
        ~isa(sampler.State, "containers.Map")
    error("labkit:mark10:InvalidSampler", ...
        "Expected a sampler returned by labkit.mark10.startSampling.");
end
state = sampler.State;
required = ["stopped", "connection", "period", "timer", "service"];
if ~all(isKey(state, cellstr(required)))
    error("labkit:mark10:InvalidSampler", ...
        "Mark-10 sampler state is invalid.");
end
end
