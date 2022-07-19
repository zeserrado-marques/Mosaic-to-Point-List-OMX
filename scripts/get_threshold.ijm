/*
 * Retrieve all thresholds and get mean + stdDev threshold
 * Use the calculated value on the mosaic_to_point_list_omx.ijm macro
 * 
 * Dependencies:
 * - Bio-formats
 * 
 * Please cite macro's author (me :D) and Minimum paper if you ended using these macros
 * 
 * 
 * Author: José Serrado-Marques
 * Version: v1.1
 * Date: 2021-10-06
 * 
 * Change log:
 * 2021-10-06
 *  - Changed Otsu threshold for Minimum
 * 
 */

#@ String (visibility=MESSAGE, value="Choose Mosaic File") ;
#@ File (style="open") inputFile ; // opens a single file

// initialize
run("Bio-Formats Macro Extensions");
print("\\Clear");

// paths
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
print("Calculating threshold for " + n + " images.");

// get all thresholds
all_thresh = getArrayThresholds(input_file, n);
Array.getStatistics(all_thresh, min, max, mean, stdDev);
print("\nThreshold statistics:\nMinimum threshold: "+min+"\nMaximum threshold: "+max+"\nAvg threshold: "+mean+"\nStdDev threshold: "+stdDev);
print("mean /2 = " + (mean/2) + "\n");

//threshold strategy
good_thresh = mean + 1*stdDev;
print("Calculated Threshold: " + good_thresh);
print("Rounded Calculated Threshold: " + round(good_thresh));


if ((mean/2) > stdDev) {
	showMessage("Warning", "Calculated threshold might not be correct, if you have very few positive cells.\nEither use another mosaic to calculated a threshold or insert one manually by changing the value in the csv file with the calculated threshold.\nProposed threshold = " + round(mean*2));
}

// save threshold
saveThreshAsTable(round(good_thresh), input_file);

end_time = getTime();
runtime(start_time, end_time);

// save log
selectWindow("Log");
saveAs("txt", input + File.separator + File.getNameWithoutExtension(input_file) + "_log_mean_threshold");

// functions
function getMosaicImagesCount(input_file) {
	// get number of images from the first dv mosaic file found
	if (endsWith(input_file, ".dv")) {
		Ext.setId(input_file);
		Ext.getSeriesCount(seriesCount);
		n = seriesCount;
	}
	return n;
}

function getArrayThresholds(input_file, number_images) {
	// gets threshold values calculated by Minimum method
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
			run("Gaussian Blur...", "sigma=2");
			
			// get lower auto threshold value
			resetThreshold();
			resetMinAndMax();
			setAutoThreshold("Minimum dark");
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

function saveThreshAsTable(good_thresh, input_file) {
	// saves the calculated threshold in the same directory as the mosaic image
	img_name =  File.getNameWithoutExtension(input_file);
	table_name = "Good_thresh_" + img_name;
	Table.create(table_name);
	Table.set("mean_threshold", 0, good_thresh);
	Table.save(File.getParent(input_file) + File.separator + table_name + ".csv");
}


function runtime(start_time, end_time) { 
	// print time in minutes and seconds
	total_time = end_time - start_time;
	minutes_remanider = total_time % (60 * 1000);
	minutes = (total_time - minutes_remanider) / (60 * 1000);
	seconds = minutes_remanider / 1000;
	print("Macro runtime was " + minutes + " minutes and " + seconds + " seconds.");
}



