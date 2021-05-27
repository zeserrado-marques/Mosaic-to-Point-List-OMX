# Mosaic-to-Point-List-OMX
ImageJ macro code that:
- Processes all images to identify transfected cells and calculates their centroids.
- Using inputted stage coordinates, it calibrates the centroids to their real stage positions.
- Writes a .txt file with the same formatting as the OMX's softworks point list files.

Current workflow only identifies transfected from non-transfected cells.

*._single_file* macros will open only the mosaic file. Meaning that you can have more than one mosaic images in the same folder.

#### Needed inputs:
- X, Y and Z values of mosaic's upper left stage coordinates
- Directory (folder) containing only a single .dv file that must be the mosaic image.
- Calcuted threshold using _mean_plus_StdDev_threshold.ijm_ into _mosaic_to_point_list.ijm_

#### Dependencies:
- Bio-formats


Please cite if you used it. Thanks :D
