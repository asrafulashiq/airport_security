Extracting Frames:
1. Unwrap CLASP_extractingFrames.m
2. Do CLASP_extractingFrames(‘path/of/videos’,’path/of/saving/frames’,30) in Matlab.

Labeling Frames:
1. Unwrap ‘P dollar toolbox.zip’.
2. Function for labeling is detecor/bblabel.m. Please do bblabel({‘person’,’bin’},’path/of/frames’,’path/of/saving/tags’) in Matlab.
3. Some shortcuts which may be useful: double click to skip one frame; Arrow up/down to switch tag of bounding box.
4. This toolbox is pretty old and not stable in new version of Matlab. Some shortcut mentioned in GUI may not work. Please take care.

Labeled Ground Truth: 
Labeling data is stored in folder CLASP_labels. Every subfolder’s name has format ExperimentNo._CameraNo., eg subfolder of camera 9 in experiment 9A should have name 9A_C9.

In each subfolder a txt file stores labels of each extracting frame. You can see several lines which each line indicate one object.  Each object struct has the following fields:

  lbl  - a string label describing object type. 
	 We only have ‘person’ and ‘bin’ at present 
  bb   - [left top width height]: 4 number indicating bounding box of predicted 		  object extent
  occ  - 0/1 value indicating if bb is occluded
  bbv  - [l t w h]: bb indicating visible region (may be [0 0 0 0])
  ign  - 0/1 value indicating bb was marked as ignore
  ang  - [0-360] orientation of bb in degrees