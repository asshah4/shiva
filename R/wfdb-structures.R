# Signal Table -----------------------------------------------------------------

#' Signal tables
#'
#' @description
#'
#' `signal_table()` modifies the `data.table` class to work with electrical
#' signal data. The input should be a data set of equal number of rows. It will
#' add a column of index positions called `sample` if it does not already exist.
#'
#' @param x <data.frame> A data frame
#'
#' @param ... <list> A list or equal lengths
#'
#' @import data.table
#' @export
signal_table <- function(...) {

	# Invariant rules:
	# 	Can add and remove rows (each row is a time point)
	# 	Rows can NOT be re-ordered
	# 	Columns CAN be re-ordered
	# 	Signal columns must be numeric (integer or double)
	#
	# Invariant columns:
	# 	sample <integer> represents a time point and order of data (<integer>)

	x <- df_list(..., .name_repair = ~ make.unique(.x, sep = "_"))

	if (length(x) == 0) {
		return(new_signal_table())
	}

	# Check to see if a `sample` column exists
	# If it is, put it in front
	if ('sample' %in% names(x)) {
		y <- x[c('sample', names(x)[which(names(x) != 'sample')])]
	} else {
		x$sample <- 1:max(lengths(x))
		y <- x[c('sample', names(x)[which(names(x) != 'sample')])]
	}

	# Last checks
	checkmate::assert_list(y, types = 'numeric')
	checkmate::assert_names(names(y), must.include = 'sample')
	checkmate::assert_integer(y$sample)

	new_signal_table(data = y)
}

#' @keywords internal
new_signal_table <- function(data = list()) {
	new_data_frame(data, class = c('signal_table', 'data.table'))
}

#' @export
print.signal_table <- function(x, ...) {
	cat(sprintf('<%s: %s x %s>\n', class(x)[[1]], dim(x)[1], dim(x)[2]))
	if (length(x) > 0) {
		NextMethod()
	}
}

#' @export
vec_ptype_abbr.signal_table <- function(x, ...) "sig_tbl"

#' @export
vec_ptype_full.signal_table <- function(x, ...) "signal_table"

#' @rdname signal_table
#' @export
is_signal_table <- function(x) {
	inherits(x, "signal_table")
}

#' @importFrom vctrs vec_ptype2 vec_cast
NULL

#' @keywords internal
signal_table_ptype2 <- function(x, y, ...) {
	as.data.table(df_ptype2(x, y, ...))
}

#' @keywords internal
signal_table_cast <- function(x, to, ...) {
	as.data.table(df_cast(x, to, ...))
}

## signal_table

#' @export
vec_ptype2.signal_table.signal_table <- function(x, y, ...) {
	new_signal_table()
}

#' @export
vec_cast.signal_table.signal_table <- function(x, to, ...) {
	x
}

## data.table

#' @export
vec_ptype2.signal_table.data.table <- function(x, y, ...) {
	signal_table_ptype2(x, y, ...)
}

#' @export
vec_cast.signal_table.data.table <- function(x, to, ...) {
	signal_table_cast(x, to, ...)
}

## data.frame

#' @export
vec_ptype2.signal_table.data.frame <- function(x, y, ...) {
	signal_table_ptype2(x, y, ...)
}

#' @export
vec_cast.signal_table.data.frame <- function(x, to, ...) {
	signal_table_cast(x, to, ...)
}

# Annotation Table -------------------------------------------------------------

#' Annotation Table
#'
#' @description
#' `annotation_table()` modifies the `<data.table>` class to work with
#' annotation data. The columns are of all equal length, and each row describes
#' a single annotation (although there may be duplicate time points).
#'
#' @details
#' The `annotation_table()` function creates a compatible table that can be used
#' with [write_annotation()] and [read_annotation()] functions.
#'
#' @inheritSection wfdb_annotations Annotation files
#'
#' @returns A `<data.table>` that has invariant columns that are compatible with
#'   the WFDB library
#'
#' @inheritParams wfdb
#' @inheritParams wfdb_io
#'
#' @param time <numeric> Time stamp of the annotation
#' @param sample <integer> Sample number of the annotation
#' @param type <character> Type of the annotation
#' @param subtype <character> Subtype of the annotation
#' @param channel <integer> Channel number of the annotation
#' @param number <integer> Number that further classifies the annotation
#'
#' @export
annotation_table <- function(annotator = character(),
														 time = numeric(),
														 sample = integer(),
														 type = character(),
														 subtype = character(),
														 channel = integer(),
														 number = integer()) {


	# Invariant rules:
	# 	Can add and remove rows (each row is an annotation)
	# 	Rows CAN be re-ordered
	# 	Columns CANNOT be re-ordered
	# 	Each column type is specific and invariant
	#
	# Invariant columns:
	#		time: <double>
	# 	sample: <integer>
	#		type: <character>
	# 	subtype: <character>
	#		channel: <integer>
	# 	number: <integer>

	x <- df_list(time = time,
							 sample = sample,
							 type = type,
							 subtype = subtype,
							 channel = channel,
							 number = number)

	new_annotation_table(x, annotator)
}

#' @keywords internal
new_annotation_table <- function(x = list(),
																 annotator = character()) {

	if (length(x) > 0) {
		checkmate::assert_list(
			x,
			types = c('numeric', 'integer', 'character')
		)

		checkmate::assert_names(
			names(x),
			identical.to = c('time', 'sample', 'type', 'subtype', 'channel', 'number')
		)
	}

	new_data_frame(x, annotator = annotator, class = c('annotation_table', 'data.table'))

}

#' @export
print.annotation_table <- function(x, ...) {

	if (nrow(x) > 0) {
		cat(sprintf(
			'<%s: %s `%s` annotations>\n',
			class(x)[[1]],
			dim(x)[1],
			attributes(x)$annotator
		))
		if (lengths(x)[1] > 0) {
			NextMethod()
		}
	} else {
		cat(sprintf( '<%s: 0 annotations>\n', class(x)[[1]]))
	}

}

#' @export
vec_ptype_abbr.annotation_table <- function(x, ...) "ann_tbl"

#' @export
vec_ptype_full.annotation_table <- function(x, ...) "annotation_table"

#' @export
#' @rdname annotation_table
is_annotation_table <- function(x) {
	inherits(x, "annotation_table")
}

#' @keywords internal
annotation_table_ptype2 <- function(x, y, ...) {
	as.data.table(df_ptype2(x, y, ...))
}

#' @keywords internal
annotation_table_cast <- function(x, to, ...) {
	as.data.table(df_cast(x, to, ...))
}

#' @export
vec_ptype2.annotation_table.annotation_table <- function(x, y, ...) {
	new_annotation_table()
}

#' @export
vec_cast.annotation_table.annotation_table <- function(x, to, ...) {
	x
}

#' @export
vec_ptype2.annotation_table.data.table <- function(x, y, ...) {
	annotation_table_ptype2(x, y, ...)
}

#' @export
vec_cast.annotation_table.data.table <- function(x, to, ...) {
	annotation_table_cast(x, to, ...)
}

#' @export
vec_ptype2.annotation_table.data.frame <- function(x, y, ...) {
	annotation_table_ptype2(x, y, ...)
}

#' @export
vec_cast.annotation_table.data.frame <- function(x, to, ...) {
	annotation_table_cast(x, to, ...)
}

# Header Table -------------------------------------------------------------

#' Header Table
#'
#' @description
#' `header_table()` modifies the `data.table` class to work with header data.
#' The header data is read in from a similar format as to that of WFDB files and
#' should be compatible/interchangeable when writing out to disk. The details
#' extensively cover the type of data that is input. Generally, this function is
#' called by `read_*_header()` functions and will generally not be called by the
#' end-user.
#'
#' @details
#'
#' # Header file structure
#'
#' There are three components to the header file
#'
#' 1. __Record line__ that contains the following information, in the order
#' documented, however pieces may be missing based on different parameters. From
#' left to right...
#'
#'		- Record name
#'		- Number of signals: represents number of segments/channels
#'		- Sampling frequency (optional)
#'		- Number of samples (optional)
#'		- Time: in HH:MM:SS format (optional)
#'		- Date: in DD/MM/YYYY (optional)
#'
#' 1. __Signal specification lines__ contains specifications for individual
#' signals, and there must be as many signal lines as there are reported by the
#' above record line. From left to right....
#'
#'		- File name: usually *.dat
#'		- Format <integer>: represents storage type, e.g. 8-bit or 16-bit
#'		- ADC gain: ADC units per physical unit (optional)
#'			- Baseline: corresponds to 0 physical units, sep = '*(0)" (optional)
#'			- Units: with '/' as a field separator e.g '*/mV' (optional)
#'		- ADC resolution <integer>: bits, usually 8 or 16 (optional)
#'		- ADC zero: represents middle of ADC input range (optional)
#'		- Initial value (optional)
#'		- Checksum (optional)
#'		- Block size (optional)
#'		- Description: text or label information (optional)
#'
#' 1. __Info strings__ are unstructured lines that contains information about
#' the record. Usually are descriptive. Starts with initial '#' without
#' preceding white space at beginning of line.
#'
#' @param record_name <character> Record line information
#' @param number_of_channels <integer> Number of signals
#' @param frequency <numeric> Sampling frequency, 250 Hz default
#' @param samples <integer> Number of samples
#' @param start_time <POSIXct> Time of recording
#' @param ADC_saturation <integer> ADC saturation
#' @param file_name <character> Signal specific information
#' @param storage_format <integer> Storage format, 16-bit default
#' @param ADC_gain <integer> ADC gain, default of 200
#' @param ADC_baseline <integer> ADC baseline, defaults to `ADC_zero`
#' @param ADC_units <character> ADC units, "mV" is default
#' @param ADC_resolution <integer> ADC resolution, default is 12
#' @param ADC_zero <integer> ADC zero, defaults to 0
#' @param initial_value <integer> Initial value, defaults to `ADC_zero` value
#' @param checksum <integer> Checksum
#' @param blocksize <integer> Block size
#' @param label <character> Description
#' @param info_strings <list> Additional information at end of file
#' @param additional_gain <numeric> Additional gain, defaults to 1.0
#' @param low_pass <integer> Low pass filter
#' @param high_pass <integer> High pass filter
#' @param color <character> Color as hexadecimal format, defaults to black
#' @param scale <integer> Scale
#'
#' @export
header_table <- function(record_name = character(), # Record line information
												 number_of_channels = integer(),
												 frequency = 250.0,
												 samples = integer(),
												 start_time = Sys.time(),
												 ADC_saturation = integer(),
												 file_name = character(), # Signal specific information
												 storage_format = 16L,
												 ADC_gain = 200L,
												 ADC_baseline = ADC_zero,
												 ADC_units = "mV",
												 ADC_resolution = 12L,
												 ADC_zero = 0L,
												 initial_value = ADC_zero,
												 checksum = 0L,
												 blocksize = 0L,
												 label = character(),
												 info_strings = list(), # Secondary information
												 additional_gain = 1.0,
												 low_pass = integer(),
												 high_pass = integer(),
												 color = '#000000',
												 scale = integer()) {


	# Three components to the header structure as described above
	# 	Record line
	# 	Signal line(s)
	# 	Info strings

	# File name from record name
	if (length(record_name) == 0) {
		record_name <- NA
		file_name <- NA
	} else {
		file_name <- paste0(record_name, '.dat')
	}

	# First line of (*.hea) equivalent
	record_line <- list(
		record_name = record_name,
		number_of_channels = number_of_channels,
		samples = samples,
		start_time = start_time,
		frequency = frequency,
		ADC_saturation = ADC_saturation
	)

	# Channels and specific signal should be organized appropriately
	# 	Top to bottom should be from high to low, and then from left to right
	# 	Catheters/leads are specifically included
	# 	Retrieved from "data-raw" folder from leads.R file
	# Table of channel information
	# 	Clean up names if possible
	# 	All are made upper character
	label <-
		toupper(label) |>
		gsub("\ ", "_", x = _)

	if (length(label) > 0 & all(label %in% .labels)) {
		lab_splits <-
			stringr::str_split(label, pattern = "_", n = 2, simplify = TRUE)

		source <- lab_splits[,1]
		source <- ifelse(label %in% .leads$ECG, "ECG", source)

		lead <- lab_splits[,2]
		lead <- ifelse(label %in% .leads$ECG, label, lead)

		# Factor if possible
		source <- factor(source, levels = intersect(.source, source))
		label <- factor(label, levels = intersect(.labels, label))
	} else {
		source <- NA
		lead <- NA
		label <- make.unique(label, sep = "_")
	}

	# Make sure labels are unique
	if (length(low_pass) == 0) {
		low_pass <- NA_integer_
	}
	if (length(high_pass) == 0) {
		high_pass <- NA_integer_
	}

	# ADC gain can be generated by dividing saturation by digital gain
	# Otherwise defaults
	if (length(ADC_saturation) > 0) {
		ADC_gain <- ADC_saturation / additional_gain
	}

	# Option characteristics

	# Signal specifications
	x <- df_list(
		"file_name" = ifelse(length(file_name) == 0, NA_character_, file_name),
		"storage_format" = storage_format,
		"number" = ifelse(length(number_of_channels) == 0, 0, 1:number_of_channels),
		"ADC_gain" = ADC_gain,
		"ADC_baseline" = ADC_baseline,
		"ADC_units" = ADC_units,
		"ADC_zero" = ADC_zero,
		"ADC_resolution" = ADC_resolution,
		"initial_value" = initial_value,
		"checksum" = checksum,
		"blocksize" = blocksize,
		"label" = label,
		"lead" = lead,
		"source" = source,
		"additional_gain" = additional_gain,
		"low_pass" = low_pass,
		"high_pass" = high_pass,
		"color" = color,
		"scale" = ifelse(length(scale) == 0, NA, scale)
	)

	# Info strings


	# Construct new table
	new_header_table(
		x = x,
		record_line = record_line,
		info_strings = info_strings
	)

}

#' @keywords internal
new_header_table <- function(x = list(),
														 record_line = list(),
														 info_strings = list()) {

	new_data_frame(
		x,
		record_line = record_line,
		info_strings = info_strings,
		class = c("header_table", "data.table")
	)

}

#' @export
#' @rdname header_table
is_header_table <- function(x) {
	inherits(x, "header_table")
}

#' @export
print.header_table <- function(x, ...) {

	if (nrow(x) > 0) {
		cat(
			sprintf(
				"<%s: %s channels, %s samples @ %s Hz> %s\n",
				class(x)[[1]],
				attributes(x)$record_line$number_of_channels,
				attributes(x)$record_line$samples,
				attributes(x)$record_line$frequency,
				attributes(x)$record_line$record_name
			)
		)
		if (lengths(x)[1] > 0) {
			NextMethod()
		}
	} else {
		cat(sprintf( "<%s: 0 channels, 0 samples>\n", class(x)[[1]]))
	}

}
