/*
 * Creates a concatenated point list from .csv centroid files that are the output of mosaic_to_point_list.ijm
 * 
 * Input:
 * - folder with the centroid tables .csv files
 * 
 * z_value is now read from the table
 * 
 * Author: José Serrado-Marques
 * Version: v1.1
 * Date: 2021-09-30
 * 
 */

print("\\Clear");
input = getDir("folder with centroid tables");
list_files = getFileList(input);

centroid_count = 0;
last_count = 0;
for (i = 0; i < list_files.length; i++) {
	current_file = list_files[i];
	path_current = input + File.separator + list_files[i];
	if (endsWith(current_file, ".csv")) {
		open(path_current);
		for (b = 0; b < Table.size; b++) {
			x_value = round(Table.get("centroid_x", b) * 10) / 10;
			y_value = round(Table.get("centroid_y", b) * 10) / 10;
			z_value = round(Table.get("z_value", b) * 10) / 10;
			// writes centroid positions in omx point list pattern
			print((last_count + (b+1)) + ": " + x_value + ", " + y_value + ", " + z_value);
			centroid_count++;
		}
		last_count = centroid_count;
		selectWindow(current_file);
		run("Close");
	}
}

selectWindow("Log");
saveAs("txt", input + File.separator + "Concatenated_point_list");

