# Mosaic-to-Point-List-OMX
ImageJ macro code that:
- Processes all images to identify transfected cells and calculates their centroids.
- Using stage coordinates saved in a txt file, it calibrates the centroids to their real stage positions.
- Writes a .txt file with the same formatting as the OMX's softworks point list files.

Current workflow only identifies transfected from non-transfected cells.

**Main script - _mosaic_to_point_list_more_smart.ijm_**

#### Needed inputs:
- X, Y and Z values of mosaic's upper left image center (macro then calculates where top left x, y coordinates)
- Directory (folder) containing _.dv_ files (mosaic image)

#### How to run
1- Make sure you have two types of files:
  - mosaic image file(s)
  - stage coordinates file(s)

You should always have a pair of "mosaic-stage coordinates" files.

2- Run _get_threshold.ijm_.  
_get_threshold.ijm_ will output a .csv file called *"Good_thresh_" + image name* with the calculated threshold value that the main script will read.

3 - Run _mosaic_to_point_list_more_smart.ijm_ for as many mosaic images you have

4 - Run _concatenate_point_lists.ijm_ on the created folder containing all individual point lists to create a big one.


#### Dependencies:
- [Bio-formats](https://www.openmicroscopy.org/bio-formats/) (comes installed with Fiji)

Please cite:
- [Minimum threshold paper](https://doi.org/10.1111/j.1749-6632.1965.tb11715.x)
- [Fiji](https://doi.org/10.1038/nmeth.2019)
- and this repo if you used it.

Thanks :D
Hope it was useful
