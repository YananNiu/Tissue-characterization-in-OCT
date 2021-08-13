% © 2021 Massachusetts Institute of Technology
% Yanan Niu
% Impact and Implications of Mixed Plaque class in Automated Characterization of Complex Atherosclerotic Lesions
% version 26/07/2021

% This algorithm is used to create patches for the sebsequent training process
% Patches are only created in diseased area, which is defined by plaque annoations
%   input -----------------------------------------------------------------
%      Name                Value
%      'patch_size'        An odd, size of the patch
%      'coordinate'        'polar' or 'cartesian', the coordinate of the patches
%      'OCT_raw'           OCT awaiting for patch creation
%      'anno_path'         plaque annotations for 'OCT_raw'
%   Output ----------------------------------------------------------------             
%   Created patches, saved as 'png' in folder 'PatchFolder'       
%   Info summary for created patches [class, patch matrix, coordinate of central pixel] saved in folder 'InfoFolder'         

clc;
clear;
close all;
%% Configuration (modify here...)
patch_size = 41;                       % choose the patch size (odd)
coordinate = 'polar';                  % 'Polar' or 'cartesian'
OCT_raw = 'OCT_raw.oct';               % uint16
anno_path = 'plaques_OCT_raw/';        % annotations for 'OCT_raw' (all in the Cartesian coordinates)

patch_out = 'patches_full_all/';         % root folder: created patches
Patch_info_out = 'patches_full_all_info/';   % root folder: info summary for created patches
%% Patch creation
w = (patch_size-1)/2;
file_name = ['patch_',coordinate];
 
count =[0 0 0 0 0]; % indexing for the 5 classes
% load manual annotations
anno = fullfile(anno_path,'*.txt');
Files = dir(anno);
for s2 = 1:size(Files,1)
    % baseFileName is as the type "A_B_unm_C_D.txt"
    % A: class label(1~5) 
    % B: the (B+1)th annotation of plaque A on this
    % C: OCT index 
    % D: frame index
    baseFileName = Files(s2).name; 
    pts_border = load(fullfile(anno_path,baseFileName));
    pts1 = zeros(500,500);
    %load annotated delineation of plaques in a 500*500 matrix
    pts1(sub2ind(size(pts1),pts_border(:,1),pts_border(:,2)))=1; 
    %annotate all the pixels within this plaque 
    pts2 = imfill(pts1);          

    %load this OCT frame 
    name_str = strsplit(baseFileName,'_');
    f_num = str2double(name_str{1,5}(1:end-4));%indicate the frame num of this file
    A = imrotate(double(imresize(imread(OCT_raw,f_num),[500,500])),-90);

    % Annotations are initially in the Cartesian coordinates
    % Transfer annotation into polar or not
    if strcmp(coordinate,'Polar')
        pts3 = flip(imrotate(pts2,90),1);
        pts4 = CarToPolar_500(pts3);
        [pts(:,1),pts(:,2)] = find(pts4);
        OCT = A;%double
    else
        [pts(:,1),pts(:,2)] = find(pts2);
        OCT = imrotate(flip(PolarToCart_500(A),1),-90);%double
    end

    PatchFolder = [patch_out,num2str(patch_size),'/',file_name,'/OCT_raw/',name_str{1,1},'/'];
    InfoFolder = [Patch_info_out,num2str(patch_size),'/',file_name,'/OCT_raw'];
    if ~exist(PatchFolder, 'dir')
        mkdir(PatchFolder)
    end
    if ~exist(InfoFolder, 'dir')
        mkdir(InfoFolder)
    end

    patch = cell(length(pts(:,1)),3);
    for s3 = 1:length(pts(:,1))
        % collect class of this plaque from its title
        patch{s3,1} = str2double(name_str{1,1});
        count(patch{s3,1}) = count(patch{s3,1})+1;

        % For OCT in Polar, should expand the OCT for patch creation
        % of pixels sited near the border of the image
        if strcmp(coordinate,'polar')
            OCT_large = cat(2,OCT(:,end-w+1:end),OCT,OCT(:,1:w));
            patch{s3,2} = uint8(OCT_large(pts(s3,1)-w:pts(s3,1)+w,pts(s3,2):pts(s3,2)+2*w));
        else
            patch{s3,2} = uint8(OCT(pts(s3,1)-w:pts(s3,1)+w,pts(s3,2)-w:pts(s3,2)+w));
        end

        %coordinate of this pixel
        patch{s3,3} = [pts(s3,1),pts(s3,2)]; 
        %patch{s3,4} = max(1,pts(s3,1)-Lumen(Lumen(:,2)==pts(s3,2),1)); %depth of this pixel
        imwrite(uint8(patch{s3,2}),strcat(PatchFolder,sprintf('%d.png',count(patch{s3,1}))));
    end
    save([InfoFolder,'/',baseFileName(1:end-4)],'patch');
    clear pts
end

