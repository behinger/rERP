%Add rERP toolbox functionality to EEGLAB GUI 
function eegplugin_rerp( fig, trystr, catchstr )
toolsmenu = findobj(fig, 'tag', 'tools');
submenu = uimenu( toolsmenu, 'label', 'rERP','separator','on','userdata','startup:on;epoch:off;study:on');

uimenu( submenu, 'label', 'Run analysis', 'callback', 'pop_rerp_study(''eeg'', ALLEEG);', 'userdata','study:on;startup:on');
uimenu( submenu, 'label', 'Plot results', 'callback', 'rerp_result_gui;','userdata','study:on;startup:on');
end

