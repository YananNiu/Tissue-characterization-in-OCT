% © 2021 Massachusetts Institute of Technology
% Yanan Niu
% Impact and Implications of Mixed Plaque class in Automated Characterization of Complex Atherosclerotic Lesions
% Version 26/07/2021

% numbering: 
% class 1~5 indicate: calcium(C), lipid(LP), fibrous tissue(FT), mixed plaque(MP) and shadow(S) respectively

% This algorithm can process the training of 3 types of classifers:
%      o 5-class CNN classifier, i.e. '5_class'
%      o 4-class CNN classifier, i.e. '4_class'
%      o 4-class CNN classifier with MP lumped with C/LP/FT/S, i.e. '4_lump_1','4_lump_2','4_lump_3','4_lump_5'
%      o (4_plus_1 CNN classifier use the same network as 4-class CNN
%      classifier, so we don't provide this option here)

%   input -----------------------------------------------------------------
%      Name                         Value
%      'net'                        1~6: choose one from '5_class','4_class','4_lump_1','4_lump_2','4_lump_3','4_lump_5'
%      'patch_size'                 Patch size.
%      'DatasetPath_train_ori'      path of training dataset (saved in cell)
%      'DatasetPath_valid_ori'      path of validation dataset (saved in cell)

%   Output ----------------------------------------------------------------
%   "checkpoints" and trained models saved in folder 'Output_Folder'.
%    Model saved as 'trainedModel.mat'
%    Confusion matrix as a figure 'Confusion_matrix.fig' and a matrix 'Confusion_matrix.mat' in folder 'Output_Folder'.


clc;
clear;
close all;
%% Configuration (need to modify here...)
Network_configuration = {'5_class','4_class','4_lump_1','4_lump_2','4_lump_3','4_lump_5'};
net = 5; % choose the classifier you want to train 
Network = Network_configuration{net};
patch_size = 41;
            
% dataset for training and validation: pay attention to the patch_size conformity
DatasetPath_train_ori={'folders of training dataset'};
DatasetPath_valid_ori={'folders of validation dataset'};

%% Classifier Info 
% get parameters for this classifier
net_f = strsplit(Network,'_');
switch net_f{2}
    case 'lump'
        lump = true; %true or false
        cl_lump = net_f{3}; % 1,2,3 or 5
    case 'class'
        lump = false; %true or false
end
% create output folder
Output_Folder = ['result/',Network,' CNN classifier'];
if ~exist(Output_Folder, 'dir')
    mkdir(Output_Folder)
end

% display classifier info and 
if lump
    disp(['Training: 4-class CNN classifier with mixed plaque lumped with class ',cl_lump]);
    
else
    disp(['Training: ',Network,' CNN classifier']);
    
end
%% ------------------Define Network Architecture-----------------------------
layers = [
    imageInputLayer([patch_size patch_size 1],'Name','input1')
    
    % Conv #1     
    convolution2dLayer(6,32,'Padding','same','Name','conv_1')
    batchNormalizationLayer('Name','BN_1')
    reluLayer('Name','relu_1')
    % Maxpooling 
    maxPooling2dLayer(2,'Stride',2,'Name','maxP_1')
    
    % Conv #2     
    convolution2dLayer(6,64,'Padding','same','Name','conv_2')
    batchNormalizationLayer('Name','BN_2')
    reluLayer('Name','relu_2')
    % Maxpooling
    maxPooling2dLayer(2,'Stride',2,'Name','maxP_2')
    
    % Conv #3     
    convolution2dLayer(6,128,'Padding','same','Name','conv_3')
    batchNormalizationLayer('Name','BN_3')
    reluLayer('Name','relu_3')
    % Maxpooling 
    maxPooling2dLayer(2,'Stride',2,'Name','maxP_3')
    
    % Conv #4     
    convolution2dLayer(6,256,'Padding','same','Name','conv_4')
    batchNormalizationLayer('Name','BN_4')
    reluLayer('Name','relu_4')
    % Avepooling 
    averagePooling2dLayer(2,'Name','avg4')    
       
    fullyConnectedLayer(num_classes,'Name','fc1') 
    dropoutLayer('Name','drop1','Name','dpout')
    fullyConnectedLayer(num_classes,'Name','fc2') 
    softmaxLayer('Name','softmax');
    classificationLayer('Name','classOutput')];

lgraph = layerGraph(layers);

%% ------------------------------Training----------------------------------
% create image datastore and assign foldernames as labels
imdsTrain_ori = imageDatastore(DatasetPath_train_ori,'LabelSource','foldernames');
imdsValid_ori = imageDatastore(DatasetPath_valid_ori,'LabelSource','foldernames');

if lump
    % replace MP with the chosen lumped class
    imdsTrain_ori.Labels(imdsTrain_ori.Labels == '4') = categorical(cl_lump);
    imdsValid_ori.Labels(imdsTrain_ori.Labels == '4') = categorical(cl_lump);
end

% create a balanced dataset across all the classes
labelCount1 = countEachLabel(imdsTrain_ori);NUM1 = floor(min(labelCount1.Count));
labelCount2 = countEachLabel(imdsValid_ori);NUM2 = min(labelCount2.Count);
[ds1_trian_bal,~] = splitEachLabel(imdsTrain_ori,NUM1,'randomized');  
[ds1_valid_bal,~] = splitEachLabel(imdsValid_ori,NUM2,'randomized');

% shuffle the data among all the num_classes
cds1 = shuffle(ds1_trian_bal);    
cds2 = shuffle(ds1_valid_bal);

% compute training/validation ratio
tr=size(ds1_trian_bal.Files);
ts=size(ds1_valid_bal.Files);
fprintf('Train patches: %d\n',(tr(1)));
fprintf('Valid patches: %d\n',(ts(1)));
fprintf('Validation percentange: %d\n',((ts(1))/(tr(1))));

% can choose to augment the dataset 
%aug = imageDataAugmenter('RandXReflection',true);% flipping(left-right direction)
%cds1 = augmentedImageDatastore([patch_size patch_size],cds1,'DataAugmentation',aug);
%cds2 = augmentedImageDatastore([patch_size patch_size],cds2,'DataAugmentation',aug);
%% Training 
options = trainingOptions('sgdm', ...
    'InitialLearnRate',0.02, ...
    'MaxEpochs',50, ...
    'Shuffle','never', ...
    'ValidationData',cds2, ...
    'ValidationFrequency',30, ...
    'OutputFcn',@(info)stopIfAccuracyNotImproving(info,20),...
    'ValidationPatience',10,...   %stop automatically if Val-loss doesn't improve
    'CheckpointPath',Output_Folder,...
    'MiniBatchSize', 3000, ...
    'Verbose',true, ...
    'VerboseFrequency', 50);   %'Plots','training-progress'

disp('Entering training...')
[trainedNet,traininfo] = trainNetwork(cds1,lgraph,options);
disp('Saving data...')

save([Output_Folder,'/trainedModel.mat'],'trainedNet','traininfo');
estimated_label= classify(trainedNet, cds2); % predict labels
real_label= cds2.labels;
% save the confusion matrix as a figure and a matrix
figure(); plotconfusion(real_label, estimated_label);savefig([Output_Folder,'/Confusion_matrix.fig'])
[C,order] = confusionmat(real_label, estimated_label); save([Output_Folder,'/Confusion_matrix.mat'],'C','order');




