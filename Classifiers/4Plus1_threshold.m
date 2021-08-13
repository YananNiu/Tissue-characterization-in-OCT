% © 2021 Massachusetts Institute of Technology
% Yanan Niu
% Impact and Implications of Mixed Plaque class in Automated Characterization of Complex Atherosclerotic Lesions
% version 26/07/2021

% This algorithm is used to calculate the thresholds of 4+1 neural network 

%   input -----------------------------------------------------------------
%      Name                Value
%      '4Plus1_version'    'V1' or 'V2'(Pr(C)+Pr(LP) for pixel predicted as calcium, specifically)
%      'model_folder'      where the trained model saved(ps: for 4_plus_1 classifier, it uses the same model as 4-class classifir) 
%   Output ----------------------------------------------------------------
%      'Th_opt'            Optimal thresholds for C, LP, FT and S.
%      'S'                 Sensitivity before "+1" layer
%      'Sp'                Specificity before "+1" layer
%      'S_total'           Overall performance (mean accuracy) before "+1" layer
%      'S_cor'             Sensitivity after "+1" layer
%      'Sp_cor'            Specificity after "+1" layer
%      'S_cor_total'       Overall performance (mean accuracy) after "+1" layer
%   Statistics of probabilities(output of Softmax layer) saved as 'Confidence_total' in folder 'out_folder'.
clc;
clear;
close all;
%% Configuration (modify here...)
Plus1_version = 'V1'; % or 'V2'
model_folder = 'result/4_class CNN classifier/trainedModel.mat'; % where the trained model saved

out_folder = '4Plus1_analysis/'; % to save statistics of probabilities
if ~exist(out_folder,'dir')
    mkdir(out_folder);
end

% variable for loading the patches: they should be consistent with the trained classifier
patch_size = 41;
coordinate = 'polar';                  % 'Polar' or 'cartesian'
% load model and patches
load(model_folder);
patch_folder = ['patches_full_all_info\' ,num2str(patch_size),'\','patch_',coordinate,'\OCT_raw\']; 

%% Feed all the diseased pixels (5 classes) into 4-CNN to calculate confidence
% Save the 4 probabilities of softmax layer as "Confidence_total"
plaque_type = {'C','LP','FT','MP','S'};
for Type = 1:5
    count = 0; % count for all the pixels of this "Type" in the dataset 
    Confidence = {}; % Condifence for each type of plaque 
 
    % take all the patches if this "Type" for this patient
    patch_path = [patch_folder,num2str(Type),'_*.mat'];
    Files = dir(patch_path);
    %sprintf(num2str(length(Files)))
    for s1 = 1:size(Files,1)
        count = count+1;
        baseFileName = Files(s1).name;
        MAT = load(fullfile(patch_folder,baseFileName)).patch;

        % MAT: 3 columns (label, patch matrix, coordinate of central pixel)
        cl_5 = zeros(length(MAT),4);
        for s2=1:length(MAT)
            cl_5(s2,:) = predict(trainedNet,MAT{s2,2}); % return the probabilities of 4 output classes
        end

        Confidence{count}=cl_5;
    end

    Confidence_total.(char(plaque_type(Type)))=Confidence;
end
save([out_folder,'\confidence_total.mat'],'Confidence_total');

%% Collect max probabilities for each class
Confidence=load([out_folder,'\confidence_total.mat']).Confidence_total;

group = cell(5,4); % 5 rows -> 5 classes; 4 columns -> 4 labels (1~4) from 4-CNN,except MP
s = cell(1,5); % all the probabilities across all the pixels predicted as a certain class
len = zeros(5,1);% calculate the amount of pixels for each class
for type2 = 1:5     
    Class = Confidence.(plaque_type{type2});
    s{type2} = [];
    for l = 1:length(Class)
        s{type2} = [s{type2};Class{l}];      
    end 
    len(type2) = length(s{type2}); 
end

bal_num = min(len);
r = cell(1,5);
for type3 = 1:5
    r{type3} = randperm(len(type3),bal_num); % balance and shuffle the dataset at the same time
    s_temp = s{type3};
    s_bal = s_temp(r{type3},:);
    [s_max,ind] = max(s_bal,[],2);
    
    switch Plus1_version
        case 'V1'
            for ix = 1:4 
                % pay attention: now ix = 4 --> S
                temp1 = roundn(s_max(ind == ix),-2);%round it to the nearest hundredth
                group{type3,ix}=sort(temp1);
            end
        case 'V2'
            for ix = 1 
                temp1 = s_bal(ind == ix,:); % pixel classified as calcium, use Pr(C)+Pr(LP)
                temp2 = roundn((temp1(:,1)+temp1(:,2)),-2);
                group{type3,ix}=sort(temp2);
            end
            for ix2 = 2:4
                temp3 = roundn(s_max(ind == ix2),-2);% for the rest classes, use Pr(class) directly
                group{type3,ix2}=sort(temp3);
            end
    end
end

%% find the optimal threshold to distinguish two signals
Class = {'Calcium','Lipid','Fibrous tissue','Shadow',''};
Color_1d = {'y','g','b','c','m'};% for C, LP,FT, S, MP in order
group_re = cell(5,4); %change sequence: make 5 rows as C,LP,FT,S,MP in order
group_re(1:3,:) = group(1:3,:); group_re(4,:) = group(5,:);group_re(5,:)= group(4,:); 
Th_opt = zeros(1,4);

for cc = 1:4 % plot: pixels predicted as C, LP,FT,S individually
    cc_type = [cc 5];
    
    pro = cell(1,2);
    freq = cell(1,2);

    figure();
    for cc1 = 1:2   %go through this class and MP
        cc2 = cc_type(cc1);
        %ori
        temp3 = group_re{cc2,cc};
        [freq{cc1},pro{cc1}] = groupcounts(temp3);
   
        %freq = freq./sum(freq);
        % the absolute number of two classes is meaningful here since the
        % dataset is balanced before this operation
        p = plot(pro{cc1},freq{cc1}); p.Color=Color_1d{cc2}; hold on;
    end
    hold off;title("For pixels predicted as ",Class{cc});legend(Class{cc},'Mixed plaque');
    
    % calculate the point where max(Pr(MP)-Pr(class)), Pr() indicates cumulative probabilities
    pro_l = min([pro{1};pro{2}]);
    pro_r = max([pro{1};pro{2}]);
    
    pro_fix = [pro_l:0.01:pro_r]; %scale: 0.01
    freq_fix = cell(1,2);
    for pp1 = 1:2
        PRO = pro{pp1};
        for pp2 = 1:length(PRO)
            freq_fix{pp1}(pro_fix==PRO(pp2)) = freq{pp1}(pp2);
        end
    end
    
    Th = cumtrapz(pro_fix,freq_fix{2})-cumtrapz(pro_fix,freq_fix{1});
    [~,Th_opt_idx] = max(Th);
    Th_opt(cc) = pro_fix(Th_opt_idx);       
end

%% sensitivity&specificity calculation for ori: set up optimal threshold
S = zeros(1,4);
Sp = zeros(1,4);
for ty = 1:4
    S(ty) = length(group_re{ty,ty})/bal_num;
    Sp(ty) = length(group_re{ty,ty})/(length(group_re{1,ty})+length(group_re{2,ty})...
        +length(group_re{3,ty})+length(group_re{4,ty}));
end
S_total = sum(S(:))/4;

% "Plus 1" Layer:when
T = Th_opt;
Predict = zeros(5,5);
for ty2 = 1:5
    for  ty3 = 1:5
        if ty3 == 5
            Predict(ty2,5) = sum(group_re{ty2,1}<T(1))+sum(group_re{ty2,2}<T(2))+sum(group_re{ty2,3}<T(3))+sum(group_re{ty2,4}<T(4));
        else
            Predict(ty2,ty3) = sum(group_re{ty2,ty3}>=T(ty3)); 
        end
    end
end

%after threshold
S_cor = zeros(1,5);Spe = zeros(1,5);
for ty4 = 1:5
    S_cor(ty4) = Predict(ty4,ty4)/sum(Predict(ty4,:));
    Sp_cor(ty4) = Predict(ty4,ty4)/sum(Predict(:,ty4));
end
S_cor_total = sum(S_cor(:))/5;
Predict = Predict.'; % make 'Predict' as the format of confusion matrix: row(real); column(predicted)