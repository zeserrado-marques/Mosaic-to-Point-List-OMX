/*
 * Main macro code that will indeed process a mosaic image file and returns a point list.
 * Applies calculated threshold and gets all centroids in a cute little table. kawaii deshou?
 * Calibrated centroid for stage coordinates are written as .txt file. Use this file to get a point list for your cell of interest.
 * 
 * Dependencies:
 * - Bio-formats
 * 
 * Inputs:
 * - Calcuted threshold using mean_plus_StdDev_threshold.ijm
 * - X, Y and Z values of mosaic's upper left stage coordinates
 * - Single .dv file that must be the mosaic image.
 * These inputs are read from files.
 * 
 * 
 * Please cite the author (me :D) if you ended using these macros. Thank you.
 * 
 * Change log:
 * 2021-09-30 
 * 	- analyze particles now accepts objects of lowest size = 20
 * 	- fixed a bug in removeRepeatedCentroids where X coordiante difference was not absolute value. now uses abs()
 * 	
 * 2021-10-06
 *  - analyze particles lowest size = 30
 *  - remove overlap. There is no overlap.
 * 	
 * Author: José Serrado-Marques
 * Version: v1.1
 * Date: 2021-09-30
 * 
 * 
 */

// script parameters to have all of the main inputs
#@ String (visibility=MESSAGE, value="<html><p>Files to get necessary inputs<ul><li>mosaic file</li><li>threshold info file</li><li>coordinates file</li></ul></p></html>") ;
#@ File (style="open") mosaicFile ;
#@ File (style="open") good_thresh_file ;
#@ File (style="open") coordinate_file ;


// initialize
run("Bio-Formats Macro Extensions");
print("\\Clear");
run("Set Measurements...", "area mean centroid shape limit redirect=None decimal=4");

// paths
input = File.getParent(mosaicFile);
input_file = mosaicFile;
list_files = getFileList(input);
output = input + File.separator + "post_processing_analysis_of_" + File.getNameWithoutExtension(input_file);
File.makeDirectory(output);

// path to tables
path_table_folder = input + File.separator + "centroids_table";
if (File.isDirectory(path_table_folder) == 0) {
	File.makeDirectory(path_table_folder);
}

// image handling variables
n_size_array = getMosaicImagesCountAndImageSize(input_file);
number_images = n_size_array[0];
image_size = n_size_array[1]; // 0 % of overlay between tiles
counter = 0;

// variables imported from files
array_xyz_raw = getStageCoordinates(coordinate_file);
array_xyz = correctCenterCoordinates(array_xyz_raw, n_size_array[1]);
x_input = array_xyz[0];
y_input = array_xyz[1];
z_value = array_xyz[2];
real_start_coordinates = newArray(x_input, y_input);

good_thresh = getCalculatedThresh(good_thresh_file);

// spiral mosaic variables 
sqrt_total_images = sqrt(number_images);
start_index = floor(sqrt_total_images / 2);

// start indexes
index_x = 0;
index_y = start_index;

// run everything. Ai minha nossa senhora!

start_time = getTime();

setBatchMode("hide");
processMosaic(input_file, output, path_table_folder); //main function

end_time = getTime();
runtime(start_time, end_time);

// functions
function getMosaicImagesCountAndImageSize(input_file) {
	// get number of images and image size from the first dv mosaic file found
	run("Bio-Formats Macro Extensions");
	if (endsWith(input_file, ".dv")) {
		Ext.setId(input_file);
		Ext.getSeriesCount(seriesCount);
		Ext.getSizeX(sizeX);
		Ext.getPixelsPhysicalSizeX(pixel_sizeX);
		n = seriesCount;
		n_size_array = newArray(n, sizeX * pixel_sizeX);
	}
	return n_size_array;
}


function processMosaic(input_file, output, path_table_folder) {
	// ui, que isto faz muita coisa. e recolhe centroids. The main function
	if (endsWith(input_file, ".dv")) {
		print("opening " + input_file);
		// table is created for every mosaic images
		cell_centroids_table = "cell_centroids_real_coordinates";
		Table.create(cell_centroids_table);

		// run function
		goThroughMosaic(index_x, index_y, sqrt_total_images, image_size, real_start_coordinates, counter);
		Table.save(output + File.separator + File.getNameWithoutExtension(input_file) + "_point_list.csv");
		Table.update(cell_centroids_table);
		
		// remove repeated centroids
		new_table_name = "No repeated centroids";
		size_limit = 15;
		removeRepeatedCentroids(new_table_name, cell_centroids_table, size_limit, z_value);
		Table.save(path_table_folder + File.separator + File.getNameWithoutExtension(input_file) + "_no_repeated_centroids_point_list.csv", new_table_name);
		
		// save processing log
		selectWindow("Log");
		saveAs("txt", output + File.separator + File.getNameWithoutExtension(input_file) + "_processing_log");

		// write point list desktop txt file
		print("\\Clear");
		for (b = 0; b < Table.size; b++) {
			x_value = round(Table.get("centroid_x", b) * 10) / 10;
			y_value = round(Table.get("centroid_y", b) * 10) / 10;
			print((b+1) + ": " + x_value + ", " + y_value + ", " + z_value);
		
		selectWindow("Log");
		saveAs("txt", output + File.separator + File.getNameWithoutExtension(input_file) + "_point_list_desktop");
		}
	}
}

// the big boi while looping index function
function goThroughMosaic(index_x, index_y, sqrt_total_images, image_size, real_start_coordinates, counter) {
	// the previous recurvise but as a while loop
	while (counter < sqrt_total_images*sqrt_total_images) {
		
		first_image_index_y = floor(sqrt_total_images / 2);
		if (index_y >= first_image_index_y) {
			order_parameters = defineSpiralOrder(first_image_index_y);
		} else if (first_image_index_y % 2 == 0) {
			order_parameters = defineSpiralOrder(first_image_index_y);
		} else {
			order_parameters = defineSpiralOrder(first_image_index_y - 1);
		}
	
		print("image number " + (counter + 1));
		if (index_y % 2 == order_parameters[0]) {
			print("y é " + order_parameters[1]);
			print(index_x, index_y);
	
			// run code to put correct coordinates into calculated centroid
			processImageAddCentroids(input_file, good_thresh, counter, index_x, index_y);
			
			if (index_x < sqrt_total_images - 1) {
				index_x++;
				counter++;
				continue;
			} else if (index_y == sqrt_total_images - 1){
				// go back up in y
				print("---------------------------------------------------------------------------");
				print("salto com o x no " + sqrt_total_images - 1);
				print("---------------------------------------------------------------------------");
				index_y = first_image_index_y - 1;
				counter++;
				continue;
			} else {
				if (index_y >= first_image_index_y) {
					index_y++;
					counter++;
					continue;
				} else {
					index_y--;
					counter++;
					continue;
				}
			}
		} else {
			print("y é " + order_parameters[2]);
			print(index_x, index_y);
	
			// run code to put correct coordinates into calculated centroid
			processImageAddCentroids(input_file, good_thresh, counter, index_x, index_y);
			
			if (index_x > 0) {
				index_x--;
				counter++;
				continue;
			} else if (index_y == sqrt_total_images - 1){
				// go back up in y
				print("---------------------------------------------------------------------------");
				print("salto com o x no 0 ");
				print("---------------------------------------------------------------------------");
				index_y = first_image_index_y - 1;
				counter++;
				continue;
			} else {
				if (index_y >= first_image_index_y) {
					index_y++;
					counter++;
					continue;
				} else {
					index_y--;
					counter++;
					continue;
				}
			}		 	
	 	}
	}
	// Check these values together with upper right coordinates
	final_x = real_start_coordinates[0] + (sqrt_total_images * image_size);
	final_y = real_start_coordinates[1] + (0 * image_size);
	print("\nmax values are:\nX = " + final_x + "\nY = " + final_y);
	print("acabou o processamento");

}

// opens the current image (counter), process it and calculated centroid
function processImageAddCentroids(input_file, good_thresh, counter, index_x, index_y) { 
	// this does a fuck ton
	run("Bio-Formats Importer", "open=[" + input_file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack series_list=" + (counter+1));
	img = getTitle();
	img_name = substring(img, 0, indexOf(img, ".dv"));
	img_name = img_name + "_" + (counter+1);
	print(img);

	if (bitDepth() == 16) {
		upper = 65535;
	} else {
		print("Image must be 16-bit.");
		exit;
	}
	// pre-process
	run("Duplicate...", " ");
	run("Gaussian Blur...", "sigma=2");
	
	// threshold
	setThreshold(good_thresh, upper);
    setOption("BlackBackground", true);
    run("Convert to Mask");
    
    // binary
    run("Open");
    run("Watershed");
	run("Analyze Particles...", "size=30-Infinity circularity=0.50-1.00 show=Masks display clear add");
	mask_img = getTitle();

	// centroid retrival and roimanager operations
    getPixelSize(unit, pixelWidth, pixelHeight);
	last_index_table = Table.size(cell_centroids_table);
	initial_roi_count = roiManager("count");
	for (i = 0; i < initial_roi_count; i++) {
		// roimanager
		roiManager("select", i);
		roiManager("rename", "cell_" + (i+1));
		
		// get centroid and calibrate it
		centroid_x = getResult("X", i);
		centroid_y = getResult("Y", i);
		centroids_coordinates = newArray(centroid_x, centroid_y);
		// the function to calibrate
		lst_calibrated = calibrateCentroids(index_x, index_y, image_size, real_start_coordinates, centroids_coordinates);
		new_centroid_x = lst_calibrated[0];
		new_centroid_y = lst_calibrated[1];

		// centroid for ROI manager
		roi_centroid_x = getResult("X", i) / pixelWidth;
		roi_centroid_y = getResult("Y", i) / pixelHeight;
	
		// add to centroids table
		Table.set("Image", (last_index_table + i), img_name + "_centroid_" + (i+1), cell_centroids_table);
		Table.set("centroid_x", (last_index_table + i), new_centroid_x, cell_centroids_table);
		Table.set("centroid_y", (last_index_table + i), new_centroid_y, cell_centroids_table);

		// add centroid to roi manager
		makeOval(roi_centroid_x - 10, roi_centroid_y - 10, 20, 20);
		roiManager("Add");
		roiManager("select", roiManager("count") - 1);
		roiManager("rename", "centroid_" + (i+1));
	}

	
	// saving files
    if (roiManager("count") > 0) {
    	masks_folder = output + File.separator + File.getNameWithoutExtension(input_file) + "_masks_folder";
    	if (File.isDirectory(masks_folder) == 0) {
    		File.makeDirectory(masks_folder);
    	}
    	print("centroid was successfully added");
    	Overlay.remove;
    	Roi.remove;
    	roiManager("save", masks_folder + File.separator + img_name + "_cell_and_centroid_ROIs.zip");
    	roiManager("deselect");
    	roiManager("delete");
    	selectWindow(mask_img);
    	saveAs("TIFF", masks_folder + File.separator + img_name + "_cell_mask.tif");
    }			    
    run("Clear Results");
	close("*");
}

function calibrateCentroids(index_x, index_y, image_size, real_start_coordinates, centroids_coordinates) {
	// returns centroids calibrated for real values needed to create the point list for the OMX
	start_x = real_start_coordinates[0];
	start_y = real_start_coordinates[1];
	current_zero_x = start_x + (index_x * image_size);
	current_zero_y = start_y - (index_y * image_size);
	calibrated_centroid_x = current_zero_x + centroids_coordinates[0];
	calibrated_centroid_y = current_zero_y - centroids_coordinates[1];
	result = newArray(calibrated_centroid_x, calibrated_centroid_y);
	return result;
}

function defineSpiralOrder(first_image_index_y) { 
	// returns wanted remainder to start with x index going to the left (the same has increasing its value)
	if (first_image_index_y % 2 == 0) {
		wanted_remainder = 0;
		beginning_y_string = "par";
		other_y_string = "impar";
	} else {
		wanted_remainder = 1;
		beginning_y_string = "impar";
		other_y_string = "par";
	}
	a = newArray(wanted_remainder, beginning_y_string, other_y_string);
	return a;
}


function getStageCoordinates(coordinate_file) {
	// returns the start coordinates from the point list as an array
	// array(x_coordinate, y_coordinate, z_coordinate)
	coord_str = File.openAsString(coordinate_file);
	lines = split(coord_str, "\n");
	coord_values = split(lines[0], ",");
	array_xyz = newArray(0);
	for (i = 0; i < coord_values.length; i++) {
		split_current_value = split(coord_values[i], " ");
		if (split_current_value.length > 1) {
			x_value = parseFloat(split_current_value[1]);
			array_xyz = Array.concat(array_xyz, x_value);
		} else {
			current_value = parseFloat(split_current_value[0]);
			array_xyz = Array.concat(array_xyz, current_value);
		}
	}
	return array_xyz;
}

function getCalculatedThresh(good_thresh_file) {
	// get threshold from the saved table
	if (endsWith(good_thresh_file, ".csv")) {
		thresh_str = File.openAsString(good_thresh_file);
		thresh_array = split(thresh_str, "\n");
		good_thresh = parseInt(thresh_array[1]);
		return good_thresh;
	} else {
		showMessage("File is not csv. Sad");
		exit;
	}
}


function correctCenterCoordinates(array_xyz, raw_image_size) {
	// returns array with x and y coordinates corrected
	x = array_xyz[0] - (raw_image_size / 2);
	y = array_xyz[1] + (raw_image_size / 2);
	z = array_xyz[2];
	corrected_coord = newArray(x, y, z);
	return corrected_coord;
}


function removeRepeatedCentroids(new_table_name, table1, size_limit, z_value) {
	// removes repeated centroids, aka, centroids that are on edge of an image
	Table.create(new_table_name);
	headings_array = split(Table.headings(table1), "	");
	
	// duplicating the table
	for (i = 0; i < Table.size(table1); i++) {
		for (j = 0; j < headings_array.length; j++) {
			heading_value = Table.get(headings_array[j], i, table1);
			if (heading_value == "NaN") {
				heading_value = Table.getString(headings_array[j], i, table1);
			}
			Table.set(headings_array[j], i, heading_value, new_table_name);
		}
	}
	
	// sort by x coordinate
	Table.sort(headings_array[1], new_table_name);
	names_array = Table.getColumn(headings_array[0], new_table_name);
	x_array = Table.getColumn(headings_array[1], new_table_name);
	y_array = Table.getColumn(headings_array[2], new_table_name);
	
	delete_counter = 0;
	for (i = 0; i < x_array.length; i++) {
		// jump the first row
		if (i == 0) {
			continue;
		}
		x_value = parseFloat(x_array[i]);
		x_value_before = parseFloat(x_array[i-1]);
		y_value = parseFloat(y_array[i]);
		y_value_before = parseFloat(y_array[(i-1)]);

		// distance between centroids
		if (abs(x_value - x_value_before) + abs(y_value - y_value_before) < size_limit) {
			
			centroid_str = substring(names_array[i], lastIndexOf(names_array[i], "centroid_"));
			centroid_str_before = substring(names_array[i-1], lastIndexOf(names_array[i-1], "centroid_"));
			mosaic_str = substring(names_array[i], 0, lastIndexOf(names_array[i], "centroid_"));
			mosaic_str_before = substring(names_array[i-1], 0, lastIndexOf(names_array[i-1], "centroid_"));

			print(names_array[i], names_array[i-1]);
			// keep centroids close to each other that are different cells, so not duplicates
			if ((centroid_str != centroid_str_before) && (mosaic_str == mosaic_str_before)) {
				print("These two centroids are not duplicated. They are indeed 2 different cells, that are just really close together");
			} else {
				Table.deleteRows(i - delete_counter, i - delete_counter, new_table_name);
				print("Deleted " + names_array[i]);
				delete_counter++;
			}
		}
	}
	Table.update(new_table_name);

	// add z-value to table
	for (a = 0; a < Table.size(new_table_name); a++) {
		Table.set("z_value", a, z_value);
	}
}


function runtime(start_time, end_time) { 
	// print time in minutes and seconds
	total_time = end_time - start_time;
	minutes_remanider = total_time % (60 * 1000);
	minutes = (total_time - minutes_remanider) / (60 * 1000);
	seconds = minutes_remanider / 1000;
	print("Macro runtime was " + minutes + " minutes and " + seconds + " seconds.");
}


