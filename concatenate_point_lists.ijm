/*
 * Creates a concatenated point list from .csv centroid files that are the output of mosaic_to_point_list.ijm
 * 
 * Input:
 * - folder with the centroid tables .csv files
 * 
 * Author: José Serrado-Marques
 * Version: v1.0
 * Date: 2021-05
 * 
 */

print("\\Clear");
input = getDir("folder with centroid tables");
list_files = getFileList(input);
z_value = 5803.2;
counter = 0;
for (i = 0; i < list_files.length; i++) {
	current_file = list_files[i];
	path_current = input + File.separator + list_files[i];
	if (endsWith(current_file, ".csv")) {
		if (counter == 0) {
			last_table_index = 0;
		}
		open(path_current);
		for (b = 0; b < Table.size; b++) {
			x_value = round(Table.get("centroid_x", b) * 10) / 10;
			y_value = round(Table.get("centroid_y", b) * 10) / 10;
			print((last_table_index + (b+1)) + ": " + x_value + ", " + y_value + ", " + z_value);
		}
		last_table_index = Table.size;
		selectWindow(current_file);
		run("Close");
		counter++;
	}
}

selectWindow("Log");
saveAs("txt", input + File.separator + "Concatenated_point_list_desktop");

