# MATLAB Implementation of Tissue Characterization Classifiers in OCT 

This is the code of 4 types of CNN tissue classifiers for tissue characterization in intravascular OCT images.
These tissue classifiers are proposed in the paper:
[Impact and Implications of Mixed Plaque class in Automated Characterization of Complex Atherosclerotic Lesions]
If you use the code for your application, please cite this paper. 

## Applications
For applications of tissue classifiers to different kinds of problems, please refer to the following codes.
Order of execution:
1. Use 'Patch_creation.m' to create patches.
2. Use the created patches to train the chosen type of classifier with "CNN_training.m".
3. Use "4Plus1_threshold.m" to calculate the thresholds for the "Plus1" layer if the 4_plus_1 CNN classifier is chosen.
4. Use "OCT_prediction" to realize tissue characterization in new OCT images.

### Patch_creation.m
Since the patch is the input unit in the tissue characterization task, this code is used to create patches with a pre-defined size, whose central pixels are in diseased areas, for the subsequent classifier training process.
This example code uses manual annotations to define the diseased area. The coordinates of patches can also be chosen according to the specific needs.

It requires inputs:
1. 'patch_size': should be odd, which indicates the size of the patches.
2. 'coordinate': can be whether 'polar' or 'cartesian', indicating the coordinate of the patches.
3. 'OCT_raw': the path of OCT awaiting patch creation. 
4. 'anno_path': the path of plaque annotations for 'OCT_raw' that helps to define the diseased area.

You can get:
Created patches are saved as 'png' and matrix respectively in the folders 'PatchFolder'  and 'InfoFolder'. 

### CNN_training.m
This algorithm can process the training of 3 types of classifers:
o 5-class CNN classifier, i.e. '5_class'
o 4-class CNN classifier, i.e. '4_class'
o 4-class CNN classifier with MP lumped with calcium/lipid/fibrous tissue/shadow, i.e. '4_lump_1','4_lump_2','4_lump_3','4_lump_5'
o (4_plus_1 CNN classifier use the same network as 4-class CNN classifier, so we don't provide this option here)

The part provides the benchmark results about '5_class' reported in the paper.
[Lambros S. Athanasiou, Max L. Olender, José M. de la Torre Hernandez, Eyal Ben-Assa, Elazer R. Edelman, "A deep learning approach to classify atherosclerosis using intracoronary optical coherence tomography," Proc. SPIE 10950, Medical Imaging 2019: Computer-Aided Diagnosis, 109500N (13 March 2019); https://doi.org/10.1117/12.2513078]
If you use this part of the code, please cite this paper. 

It requires inputs:
1. 'net': 1~6: choose one from '5_class','4_class','4_lump_1','4_lump_2','4_lump_3','4_lump_5'
2. 'patch_size': patch size.
3. 'DatasetPath_train_ori': path of training dataset (saved in cell)
4. 'DatasetPath_valid_ori': path of validation dataset (saved in cell)

You can get:
"checkpoints" and trained models saved in folder 'Output_Folder'.
Confusion matrix as a figure 'Confusion_matrix.fig' and a matrix 'Confusion_matrix.mat' in folder 'Output_Folder'.

### 4Plus1_threshold.m
This algorithm is used to calculate the thresholds of the "plus 1" layer in 4+1 neural network classifier. 

It requires inputs:
1. '4Plus1_version': 'V1'(Pr(A) for pixel predicted as class A) or 'V2'(Pr(C)+Pr(LP) for pixel predicted as calcium, specifically). They correspond to the same definition in the paper.
2. 'model_folder' : where the trained model saved (ps: for 4_plus_1 classifier, it uses the same model as 4-class classifir) 

You can get:
Statistics of probabilities(output of Softmax layer) saved as 'Confidence_total' in folder 'out_folder'.
Optimal thresholds 'Th_opt' for calcium, lipid, fibrous tissue and shadow.
Sensitivities, specificities and overall accuracy before and after the "Plus1" layer.

### OCT_prediction
This algorithm can process the prediction of the 4 types of classifers:
o 5-class CNN classifier, i.e. '5_class'
o 4-class CNN classifier, i.e. '4_class'
o 4-class CNN classifier with MP lumped with calcium/lipid/fibrous tissue/shadow, i.e. '4_lump_1','4_lump_2','4_lump_3','4_lump_5'
o 4_plus_1 CNN classifier 

It requires borders to define the diseased area before the characterization process.
It requires inputs:
1. 'net': 1~7: choose one from '5_class','4_class','4_lump_1','4_lump_2','4_lump_3','4_lump_5','4_plus_1'
2. 'OCT_new': path of new OCT for prediction      
3. 'frame': an interger, indicating the specific frame for prediction
4. 'border_Lumen' and 'border_IEM': lumen and IEM annotations to define the diseased area in the vessel.
5. 'Th_opt': the threshold values got from '4Plus1_threshold.m' (only needed for '4_plus_1' classifier).
6. 'patch_size': Patch size. Should make it consistent to the chosen classifer

You can get:
Predicted results saved in folder 'Directory_Results', including 2 images: original color OCT image and characterized color OCT image.


## Changelog
__26 Jul 2021__  
The first version of the code.

