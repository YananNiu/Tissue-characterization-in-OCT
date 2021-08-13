% © 2021 Massachusetts Institute of Technology
% Yanan Niu
% Impact and Implications of Mixed Plaque class in Automated Characterization of Complex Atherosclerotic Lesions
% version 26/07/2021

% This algorithm can process the prediction of the 4 types of classifers:
%      o 5-class CNN classifier
%      o 4-class CNN classifier
%      o 4-class CNN classifier with MP lumped with C/LP/FT/S
%      o 4-Plus-1 CNN classifier

%   input -----------------------------------------------------------------
%      Name                Value
%      'net'               1~7: choose one from '5_class','4_class','4_lump_1','4_lump_2','4_lump_3','4_lump_5','4_plus_1'
%      'OCT_new'           new OCT for prediction      
%      'frame'             specific frame for prediction
%      'border_Lumen'      Lumen annotation
%      'border_IEM'        IEM annotation
%      'Th_opt'            Threshold values got from 4Plus1_analysis(only needed for '4_plus_1')
%      'patch_size'        Patch size. Should make it consistent to the chosen classifer

%   Output ----------------------------------------------------------------
%   Results saved in folder 'Directory_Results'
%   2 images: original color OCT image; characterized color OCT image.
%   Color: C（white),LP（red),FT(green),S(gray),MP(grass green),lumped category(yellow)

clear
close all
clc
%% SETUP(modify here...)
Network_configuration = {'5_class','4_class','4_lump_1','4_lump_2','4_lump_3','4_lump_5','4_plus_1'}; 
net = 7; % choose the classifier you want to train 
Network = Network_configuration{net};

% specify the frame awaiting for characterization in an OCT (*.oct | DICOM) file 
OCT_new = 'OCT_new.oct';    % new OCT for prediction
frame =136; % specify the frame for prediction
% annotation of inner and outer borders of for this OCT frame
border_Lumen = '136_lumen.txt'; 
border_IEM = '136_IEM.txt'; 

% Threshold values got from 4Plus1_analysis: C, LP, FT, S respectively
Th_opt = [0.99,0.41,0.99,0.36];

patch_size = 41;
%% Info
w = (patch_size-1)/2; 

% Folder where the trained classifier saved
if Network == '4_plus_1'
    Network_foler = 'result/4_class CNN classifier';
else
    Network_foler = ['result/',Network,' CNN classifier'];
end

% Prepare results folder
Directory_Results = ['Characterized\OCT_new_frame',num2str(frame)];	
if  ~exist(Directory_Results,'dir')
    mkdir(Directory_Results);
end
%% -----------------------------loading------------------------------------
% Load colormap (gray -> gold)
cmap=load('oct_colormap.mat');
cmap=cmap.cmp2;

% load original OCT
A = imrotate(double(imresize(imread(OCT_new,frame),[500,500])),-90);  %double
B = uint8(A); %uint8

%since operations were performed in Polar coordinate, larger OCT frames
%should be provided for the patch creation
ori_large = cat(2,B(:,end-w+1:end),B,B(:,1:w));
res = ind2rgb(B, double(cmap)/255);
res = im2uint8(res);

% load borders 
Lumen_var = load(border_Lumen);
IEM_var = load(border_IEM);

% create Region-of-interest mask
pts1 = zeros(500,500);pts2 = zeros(500,500);
pts1(sub2ind(size(pts1),Lumen_var(:,1),Lumen_var(:,2)))=1;
pts2(sub2ind(size(pts2),IEM_var(:,1),IEM_var(:,2)))=1;
% convert borders from cartesian to polar coordinate
[r1,c1] = find(CarToPolar_500(flip(imrotate(pts1,90),1)));
[r2,c2] = find(CarToPolar_500(flip(imrotate(pts2,90),1)));
mask = zeros(500,500);
for b_col = 1:500
    if sum(c1==b_col)~=0 && sum(c2==b_col)~=0
        mask(min(r1(c1==b_col)):max(r2(c2==b_col)),b_col)=1;
    else
        mask(:,b_col) = mask(:,b_col-1); %in case that borders are no longer continuous after transformation
    end
end

% Load trained CNN classifier
DLN_struct=load([Network_foler,'trainedModel.mat']);  
DLN_info=DLN_struct.traininfo;
DLN=DLN_struct.trainedNet;

%% ----------------------------prediction----------------------------------
[x, y] = find(mask==1);
cl = zeros(length(x),1);

for i=1:length(x)
    patch = ori_large(x(i)-w:x(i)+w,y(i):y(i)+2*w);	% Extract patch
    if net == 7 % for 4Plus1 specifically
        [pro,lab]= max(predict(DLN,patch));
        if pro>Th_opt(lab)
            cl(i) = lab;
        else
            cl(i) = 5; % attention: 5-->MP here. It should ba aligned with 'Cmap2' 
        end
    else
        cl(i) = classify(DLN,patch);% Classify patch
    end
end

%% Color image based on classification
% colormap for characterization: 
% C（white),LP（red),FT(green),S(gray),MP(grass green),lumped category(yellow)
switch Network
    case '4_class'
        Cmap2 = [255 255 255;255 0 0;0 176 80;150 150 150]; %C,LP,FT,S
    case '4_lump_1'
        Cmap2 = [255 255 0;255 0 0;0 176 80;150 150 150];%lumped,LP,FT,S
    case '4_lump_2'
        Cmap2 = [255 255 255;255 255 0;0 176 80;150 150 150];%C,lumped,FT,S
    case '4_lump_3'
        Cmap2 = [255 255 255;255 0 0;255 255 0;150 150 150];%C,LP,lumped,S
    case '4_lump_5'
        Cmap2 = [255 255 255;255 0 0;0 176 80;255 255 0];%C,LP,FT,lumped
    case '5_class'
        Cmap2 = [255 255 255;255 0 0;0 176 80;124 252 0;150 150 150];%C,LP,FT,MP,S
    case '4_plus_1'
        Cmap2 = [255 255 255;255 0 0;0 176 80;150 150 150;124 252 0];%C,LP,FT,S,MP
end

%labelling
Af2 = res;
for ll=1:length(x)  % Plaque
    ii=x(ll);
    jj=y(ll);
    c=cl(ll);

    Af2(ii,jj,:)=Cmap2(c,:);
end

%% ---------------------------Save results---------------------------------
% Color image (initial)
cur_fr1 = sprintf('ini_F%d.jpg',frame);
% display results in cartesian coordinates
RES = imrotate(uint8(flip(PolarToCart_500(res),1)),-90); 
imwrite(RES,[Directory_Results,'\',cur_fr1],'jpg');

% Mapped image (characterized)
af2 = imrotate(uint8(flip(PolarToCart_500(Af2),1)),-90);
imwrite(af2,[Directory_Results,'\res_Network_',Network,'.bmp'],'bmp');



