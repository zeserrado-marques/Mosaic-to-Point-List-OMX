/*
 * Main macro code that indeed processes mosaic and returns a point list.
 * Applies calculated threshold (good_thresh) and gets all centroids in a cute little table. kawaii deshou?
 * Calibrated centroid for stage coordinates are written as .txt file. Use this file to get a point list for your cell of interest.
 * 
 * Dependencies:
 * - Bio-formats
 * 
 * Inputs:
 * - Calcuted threshold using mean_plus_StdDev_threshold.ijm
 * - X, Y and Z values of mosaic's upper left stage coordinates 
 * - folder containing only a single .dv file that must be the mosaic images (to be updated).
 * 
 * Please cite the author (me :D) and Otsu paper if you ended using these macros. Thank you.
 * 
 * Author: José Serrado-Marques
 * Version: v1.0
 * Date: 2021-05
 * 
 * To do:
 * - Save table in separete folder
 * 
 */

run("Bio-Formats Macro Extensions");
print("\\Clear");
run("Set Measurements...", "area mean centroid shape limit redirect=None decimal=4");

// paths
input = getDir("Choose the folder with the mosaic image");
list_files = getFileList(input);
output = input + File.separator + "post_processing_analysis";
File.makeDirectory(output);

// path to tables
path_table_folder = input + File.separator + "centroids_table";
if (File.isDirectory(path_table_folder) == 0) {
	File.makeDirectory(path_table_folder);
}

// user input variables
Dialog.create("Variables");
Dialog.addNumber("Calculated threshold", 374);
Dialog.addNumber("Upper left X coordinate", 10648.0);
Dialog.addNumber("Upper left Y coordinate", 26032.0);
Dialog.addNumber("Z value", 5803.2);
Dialog.show();
good_thresh = Dialog.getNumber();
x_input = Dialog.getNumber();
y_input = Dialog.getNumber();
z_value = Dialog.getNumber();
real_start_coordinates = newArray(x_input, y_input);

// static variables
n_size_array = getMosaicImagesCountAndImageSize(list_files);
number_images = n_size_array[0];
image_size = n_size_array[1] - (0.015 * n_size_array[1]); // 1.5 % of overlay between tiles
counter = 0;

// spiral mosaic variables 
sqrt_total_images = sqrt(number_images);
start_index = floor(sqrt_total_images / 2);

// start indexes
index_x = 0;
index_y = start_index;

// run everything. Ai minha nossa senhora!

start_time = getTime();

setBatchMode("hide");
processMosaic(list_files, output, path_table_folder);

end_time = getTime();
runtime(start_time, end_time);

// functions
function getMosaicImagesCountAndImageSize(list_files) {
	// get number of images and image size from the first dv mosaic file found
	run("Bio-Formats Macro Extensions");
	for (i = 0; i < list_files.length; i++) {
		current_file = list_files[i];
		path_current = input + File.separator + list_files[i];
		if (endsWith(current_file, ".dv")) {
			Ext.setId(path_current);
			Ext.getSeriesCount(seriesCount);
			Ext.getSizeX(sizeX);
			Ext.getPixelsPhysicalSizeX(pixel_sizeX);
			n = seriesCount;
			n_size_array = newArray(n, sizeX * pixel_sizeX);
			break;
		}
	}
	
	return n_size_array;
}


function processMosaic(list_files, output, path_table_folder) {
	// ui, que isto faz muita coisa. e recolhe centroids.
	for (j = 0; j < list_files.length; j++) {
		current_file = list_files[j];
		path_current = input + File.separator + current_file;
		if (endsWith(current_file, ".dv")) {
			print("opening " + current_file);
			// table is created for every mosaic images
			cell_centroids_table = "cell_centroids_real_coordinates";
			Table.create(cell_centroids_table);
			
			goThroughMosaic(index_x, index_y, sqrt_total_images, image_size, real_start_coordinates, counter);
			
			Table.save(path_table_folder + File.separator + File.getNameWithoutExtension(path_current) + "_point_list.csv");
			selectWindow("Log");
			saveAs("txt", output + File.separator + File.getNameWithoutExtension(path_current) + "_log_centroid.desktop");

			// write point list desktop txt file
			print("\\Clear");
			for (b = 0; b < Table.size; b++) {
				x_value = round(Table.get("centroid_x", b) * 10) / 10;
				y_value = round(Table.get("centroid_y", b) * 10) / 10;
				print((b+1) + ": " + x_value + ", " + y_value + ", " + z_value);
			
			selectWindow("Log");
			saveAs("txt", output + File.separator + File.getNameWithoutExtension(path_current) + "_point_list_desktop");
			}
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
			processImageAddCentroids(path_current, good_thresh, counter, index_x, index_y);
			
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
			processImageAddCentroids(path_current, good_thresh, counter, index_x, index_y);
			
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
	print("acabou o teste");

}

// opens the current image (counter), process it and calculated centroid
function processImageAddCentroids(path_current, good_thresh, counter, index_x, index_y) { 
	// this does a fuck ton
	run("Bio-Formats Importer", "open=[" + path_current + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack series_list=" + (counter+1));
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
	run("Analyze Particles...", "size=30-Infinity circularity=0.50-1.00 show=Masks display clear add");
	mask_img = getTitle();

	// centroid retrival and roimanager operations
    getPixelSize(unit, pixelWidth, pixelHeight);
    selectWindow(cell_centroids_table);
	last_index_table = Table.size;
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
		Table.set("Image", (last_index_table + i), img_name + "_centroid_" + (i+1));
		Table.set("centroid_x", (last_index_table + i), new_centroid_x);
		Table.set("centroid_y", (last_index_table + i), new_centroid_y);

		// add centroid to roi manager
		makeOval(roi_centroid_x - 10, roi_centroid_y - 10, 20, 20);
		roiManager("Add");
		roiManager("select", roiManager("count") - 1);
		roiManager("rename", "centroid_" + (i+1));
	}
	
	// saving files
    if (roiManager("count") > 0) {
    	masks_folder = output + File.separator + File.getNameWithoutExtension(path_current) + "_masks_folder";
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

function runtime(start_time, end_time) { 
	// print time in minutes and seconds
	total_time = end_time - start_time;
	minutes_remanider = total_time % (60 * 1000);
	minutes = (total_time - minutes_remanider) / (60 * 1000);
	seconds = minutes_remanider / 1000;
	print("Macro runtime was " + minutes + " minutes and " + seconds + " seconds.");
}


