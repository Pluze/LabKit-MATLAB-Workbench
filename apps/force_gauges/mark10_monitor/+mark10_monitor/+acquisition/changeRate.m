function state = changeRate(state, value, context)
%CHANGERATE Update requested rate and replace an active acquisition source.
state.session.acquisition.rate = string(value);
if state.session.acquisition.monitoring
    sampler = context.getResource("application", "mark10Sampler");
    labkit.mark10.setSamplingPeriod(sampler, ...
        mark10_monitor.acquisition.ratePeriod(value));
end
end
