function state = scrollWindow(state, delta, ~)
state.session.view.windowStartSec = max(0, state.session.view.windowStartSec + double(delta));
end
