function section = layoutSection()
    section = labkit.app.layout.section("regions", "Paired windows", { ...
        labkit.app.layout.field("pair", Label="Pair", Kind="choice", ...
            Choices="1", OnValueChanged=@selectPair), ...
        labkit.app.layout.group("pairActions", { ...
            labkit.app.layout.button("addPair", "Add pair", @addPair), ...
            labkit.app.layout.button("removePair", "Remove selected pair", @removePair)}, Layout="horizontal"), ...
        labkit.app.layout.field("windowSeconds", Label="Window duration (s)", ...
            Kind="numeric", Bind="session.windowSeconds", Limits=[eps realmax], ...
            OnValueChanged=@emg_review.regions.settingsChanged), ...
        labkit.app.layout.field("baselineStart", Label="Baseline start (s)", ...
            Kind="numeric", Limits=[0 realmax], OnValueChanged=@editBaseline), ...
        labkit.app.layout.field("activityStart", Label="Activity start (s)", ...
            Kind="numeric", Limits=[0 realmax], OnValueChanged=@editActivity), ...
        labkit.app.layout.button("autoMark", "Auto-mark selected pair", ...
            @emg_review.regions.autoMark)});
end

function applicationState = selectPair(applicationState, value, ~)
    applicationState.session.pairIndex = str2double(value);
end

function applicationState = addPair(applicationState, ~)
    session = applicationState.session;
    session.pairs(end + 1, :) = [0 0];
    session.pairIndex = size(session.pairs, 1);
    applicationState.session = session;
    applicationState = emg_review.regions.settingsChanged(applicationState, [], []);
end

function applicationState = removePair(applicationState, ~)
    session = applicationState.session;
    if size(session.pairs, 1) == 1
        return;
    end
    session.pairs(session.pairIndex, :) = [];
    session.pairIndex = min(session.pairIndex, size(session.pairs, 1));
    applicationState.session = session;
    applicationState = emg_review.regions.settingsChanged(applicationState, [], []);
end

function applicationState = editBaseline(applicationState, seconds, context)
    applicationState.session.pairs(applicationState.session.pairIndex, 1) = seconds;
    applicationState = emg_review.regions.settingsChanged(applicationState, seconds, context);
end

function applicationState = editActivity(applicationState, seconds, context)
    applicationState.session.pairs(applicationState.session.pairIndex, 2) = seconds;
    applicationState = emg_review.regions.settingsChanged(applicationState, seconds, context);
end
