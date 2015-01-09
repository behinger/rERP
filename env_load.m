rerp_path=mfilename('fullpath');
rerp_path=regexp(rerp_path, ['^(.*)' filesep '.*$'], 'tokens');
rerp_path=rerp_path{:}{:};