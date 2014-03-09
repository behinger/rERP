% Copyright (C) 2013 Matthew Burns, Swartz Center for Computational
% Neuroscience.
%
% User feedback welcome: email rerptoolbox@gmail.com
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% The views and conclusions contained in the software and documentation are those
% of the authors and should not be interpreted as representing official policies,
% either expressed or implied, of the FreeBSD Project.

function eegplugin_rerp( fig, trystr, catchstr )

% cllbk_profile_from_disk='RerpPluginCallbacks.profileFromDisk(EEG);';
% cllbk_default_profile='RerpPluginCallbacks.defaultProfile(EEG);';
% cllbk_last_profile='RerpPluginCallbacks.lastProfile(EEG);';
cllbk_setup_gui='pop_rerp_study(''eeg'', EEG);';
cllbk_plot_result_eeg='rerp_result_gui;';
% cllbk_plot_result_from_folder_eeg='RerpPluginCallbacks.plotResultsFromDirectory(EEG);';

% create menu
toolsmenu = findobj(fig, 'tag', 'tools');
submenu = uimenu( toolsmenu, 'label', 'rERP','separator','on','userdata','startup:on;epoch:off;study:on');

uimenu( submenu, 'label', 'Run analysis', 'callback', cllbk_setup_gui, 'userdata','study:on;startup:on');
uimenu( submenu, 'label', 'Plot results', 'callback', cllbk_plot_result_eeg,'userdata','study:on;startup:on');

% uimenu( runmenu, 'label', 'Profile from disk', 'callback', cllbk_profile_from_disk);
% uimenu( runmenu, 'label', 'Default profile', 'callback', cllbk_default_profile);
% uimenu( runmenu, 'label', 'Last profile', 'callback', cllbk_last_profile);

end

