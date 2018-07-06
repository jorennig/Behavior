clear all
close all
clc

% Get all csv files
result_files = dir('*.csv');
result_files = {result_files(:).name}';

data_behav_tot = [];
for i = 1:numel(result_files)
    
    % read in file
    fid = fopen(result_files{i}, 'rt');
    data = textscan(fid,'%d %s %s %f', 'delimiter', ',');
    fclose(fid);    
    result_file_name = result_files{i};
    
    sub_num = str2double(result_file_name(1:2));
    idxr = strfind(result_file_name,'RUN');    
    run_num = str2double(result_file_name(idxr+3));

    fprintf('-- Subject %d, RUN %d --\n',sub_num,run_num)
    
    % Results: C1 = 1 (ba), C2 = 2 (da), C3 = 3 (ga)
    results = data(3);
    results = results{1};
    times = data(4);
    times = times{1};
    get_resp = data(2);
    get_resp = get_resp{1};
    idx_mov = strfind(get_resp,'movie');    
    
    idx_tr = strfind(get_resp,'trigger');
    idx_tr = find(not(cellfun('isempty', idx_tr)));
    idx_null = strfind(get_resp,'null');
    idx_null = find(not(cellfun('isempty', idx_null)));
    idx_esc = strfind(results,'ESCAPE');
    idx_esc = find(not(cellfun('isempty', idx_esc)));
    idx_fix = strfind(get_resp,'fix');
    idx_fix = find(not(cellfun('isempty', idx_fix)));
    
    idx_ex = sort([idx_tr;idx_null;idx_esc;idx_fix]);

    results(idx_ex) = [];
    get_resp(idx_ex) = [];
    times(idx_ex) = [];
        
    % Check if first Element is a movie file, cut off all button presses
    % before first stimulus/movie
    mov_idx = strfind(results,'MS1_');
    mov_idxn = find(not(cellfun('isempty', mov_idx)));
    
    if mov_idxn(1) > 1
        results = results(mov_idxn(1):end);
        times = times(mov_idxn(1):end);
    end
    
    % Extract movie code and responses
    field_num_tot = zeros(length(results),1);
    for j = 1:length(results)
        field = results{j};
        
        if strfind(field,'.mp4');
            idxc = strfind(field,'.mp4');
            field_num_tot(j) = str2double(field(idxc-1))+10;
        else
            field_num_tot(j) = str2double(regexprep(field,'[^1-9]',''));
        end
    end
    
    % Check for missing responses
    miss_resp = 0;
    idx = 1;
    for j = 1:length(field_num_tot)-1        
        if field_num_tot(j) > 10 && field_num_tot(j+1) > 10
            miss_resp(idx) = j;
            idx = idx + 1;
        end
    end
    
    % Replace missing response with adding '0'
    if miss_resp ~= 0
        for j = 1:numel(miss_resp)            
            field_num_tot = [field_num_tot(1:miss_resp(j)); 0; field_num_tot(miss_resp(j)+1:end)];
            times = [times(1:miss_resp(j)); 9999; times(miss_resp(j)+1:end)];
            miss_resp = miss_resp + 1;
        end
    end
    
    % Check for missing responses at the end of the vector
    if field_num_tot(end) > 10
        field_num_tot = [field_num_tot; 0];
        times = [times; 9999];
    end
    
    % Remove repeating numbers
    idx = 1;
    res_clean = zeros(round(length(field_num_tot)/6),1);

    for j = 1:length(field_num_tot)-1
       if field_num_tot(j) ~= field_num_tot(j+1)
            res_clean(idx) = field_num_tot(j);
            idx = idx + 1;
       end
    end
    res_clean = [res_clean; field_num_tot(end)];
    
    % Get onsets and first button press
    idx = 1;
    times_clean = [];
    
    for j = 1:length(field_num_tot)-1
       if field_num_tot(j) > 10
            times_clean(idx,:) = [times(j) times(j+1)];
            idx = idx + 1;
       end
    end
        
    % Check for different responses after stimuli (corrections by subject),
    % keep last number
    for j = 1:length(res_clean)-1
        if res_clean(j) < 10 && res_clean(j+1) < 10
            res_clean(j) = NaN;
        end
    end
    res_clean(isnan(res_clean)) = [];
    
    % Reshape vector to matrix
    res_behav = reshape(res_clean,[2,length(res_clean)/2])';
    res_behav(:,1) = res_behav(:,1) - 10;
    
    % Check correct responses
    pc_corr = double(res_behav(:,1)==res_behav(:,2));

    % Calculate RT
    times_clean(:,1) = times_clean(:,1) + 2.0;
    rt = times_clean(:,2) - times_clean(:,1);
    
    rt(rt < 0.15) = NaN;
    rt(rt > 2.8) = NaN;
    
    res_behav = [pc_corr,rt];
        
    run_code = ones(size(res_behav,1),1)*run_num;
    subj_code = ones(size(res_behav,1),1)*sub_num;
    
    data_behav = [subj_code run_code res_behav];
    
    % Save means to fixation report
    data_behav_tot = [data_behav_tot;data_behav];
    
end

% Sum up by subject
sub = unique(data_behav_tot(:,1));

data_behav_sum = [];
for i = 1:numel(sub)

    data_s = data_behav_tot(data_behav_tot(:,1)==sub(i),:);
    data_behav_sum(i,:) = nanmean(data_s(:,3:4));
    
end

var_tot = {'Sub','Run','ACC','RT'};
var_sum = {'ACC','RT'};

data_behav_tot = array2table(data_behav_tot,'VariableNames',var_tot);
data_behav_sum = array2table(data_behav_sum,'VariableNames',var_sum);

save('Clear_Syllables_ET_Behav.mat','data_behav_tot','data_behav_sum');
