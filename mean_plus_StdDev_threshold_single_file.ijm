/*
 * Retrieve all thresholds and get mean + stdDev threshold
 * Use the calculated value on the mosaic_to_point_list_omx.ijm macro
 * 
 * Dependencies:
 * - Bio-formats
 * 
 * Please cite macro's author (me :D) and Otsu paper if you ended using these macros
 * 
 * Author: José Serrado-Marques
 * Version: v1.0
 * Date: 2021-05
 * 
 */

run("Bio-Formats Macro Extensions");
print("\\Clear");

// paths
#@ File (style="open") inputFile ; // opens a single file
input = File.getParent(inputFile);
input_file = inputFile;
list_files = getFileList(input);

start_time = getTime();
n = getMosaicImagesCount(input_file);
// for testing purposes
n = floor(n / 2);
if (n>300) {
	n = 300;
}
print(n);

// get all thresholds
all_thresh = getArrayThresholds(input_file, n);
Array.getStatistics(all_thresh, min, max, mean, stdDev);
print("\nThreshold statistics:\nMinimum threshold: "+min+"\nMaximum threshold: "+max+"\nAvg threshold: "+mean+"\nStdDev threshold: "+stdDev+"\n");

// threshold strategy
good_thresh = mean + 1*stdDev;
print(good_thresh);
print(round(good_thresh));

end_time = getTime();
runtime(start_time, end_time);

// functions
function getMosaicImagesCount(input_file) {
	// get number of images from the first dv mosaic file found
	if (endsWith(input_file, ".dv")) {
		Ext.setId(input_file);
		Ext.getSeriesCount(seriesCount);
		n = seriesCount;
		break;
	}
	return n;
}

function getArrayThresholds(input_file, number_images) {
	// gets threshold values calculated by Otsu method
	setBatchMode("hide");
	array_thresh = newArray();
	if (endsWith(input_file, ".dv")) {
		print("opening " + input_file);
		for (a = 0; a < number_images; a++) {
			run("Bio-Formats Importer", "open=[" + input_file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack series_list=" + (a+1));
			img = getTitle();
			img_name = substring(img, 0, indexOf(img, ".dv"));
			img_name = img_name + "_" + (a+1);
			
			// pre-process
			run("Duplicate...", " ");
			//run("Subtract Background...", "rolling=50 sliding");
			run("Gaussian Blur...", "sigma=2");
			
			// get lower auto threshold value
			resetThreshold();
			resetMinAndMax();
			setAutoThreshold("Otsu dark");
			getThreshold(lower, upper);
			thresh_current = lower;
			resetThreshold();
			print("" + thresh_current + " for tile number " + (a+1));
			array_thresh = Array.concat(array_thresh, thresh_current);
			close("*");
		}
	}
	return array_thresh;
}

function runtime(start_time, end_time) { 
	// print time in minutes and seconds
	total_time = end_time - start_time;
	minutes_remanider = total_time % (60 * 1000);
	minutes = (total_time - minutes_remanider) / (60 * 1000);
	seconds = minutes_remanider / 1000;
	print("Macro runtime was " + minutes + " minutes and " + seconds + " seconds.");
}


